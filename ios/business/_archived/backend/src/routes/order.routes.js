const express = require('express');
const router = express.Router();
const { body, param, validationResult } = require('express-validator');
const { Order, Customer, MenuItem } = require('../models');
const { authenticate, authorize } = require('../middleware/auth');
const { emitNewOrder, emitOrderStatusUpdate } = require('../sockets/orderSocket');
const logger = require('../config/logger');

/**
 * @route   POST /api/v1/orders
 * @desc    Create a new order
 * @access  Public
 */
router.post('/', [
  body('customerId').isUUID(),
  body('items').isArray({ min: 1 }),
  body('type').isIn(['dine-in', 'takeout', 'delivery']),
  body('customerName').trim().notEmpty(),
  body('customerPhone').trim().notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const {
      customerId,
      items,
      type,
      customerName,
      customerPhone,
      customerEmail,
      deliveryAddress,
      specialInstructions,
      scheduledFor
    } = req.body;

    // Validate customer exists
    const customer = await Customer.findByPk(customerId);
    if (!customer) {
      return res.status(404).json({
        success: false,
        error: 'Customer not found'
      });
    }

    // Calculate totals
    let subtotal = 0;
    const enrichedItems = [];

    for (const item of items) {
      const menuItem = await MenuItem.findByPk(item.menuItemId);
      if (!menuItem || !menuItem.isAvailable) {
        return res.status(400).json({
          success: false,
          error: `Menu item ${item.menuItemId} not available`
        });
      }

      const itemTotal = parseFloat(menuItem.price) * item.quantity;
      subtotal += itemTotal;

      enrichedItems.push({
        menuItemId: menuItem.id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: item.quantity,
        customizations: item.customizations || [],
        prepTime: menuItem.prepTime
      });
    }

    // Calculate tax (8% example)
    const tax = (subtotal * 0.08).toFixed(2);
    const total = (parseFloat(subtotal) + parseFloat(tax)).toFixed(2);

    // Create order
    const order = await Order.create({
      customerId,
      items: enrichedItems,
      subtotal: subtotal.toFixed(2),
      tax,
      total,
      type,
      customerName,
      customerPhone,
      customerEmail,
      deliveryAddress,
      specialInstructions,
      scheduledFor,
      status: 'pending',
      paymentStatus: 'pending'
    });

    // Emit real-time notification
    emitNewOrder(order.toJSON());

    logger.logOrderEvent('order_created', order.id, { type, total });

    res.status(201).json({
      success: true,
      data: { order }
    });
  } catch (error) {
    logger.error('Create order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create order'
    });
  }
});

/**
 * @route   GET /api/v1/orders/:id
 * @desc    Get order by ID
 * @access  Private/Public (customer can see their own)
 */
router.get('/:id', [
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const order = await Order.findByPk(req.params.id, {
      include: [
        { model: Customer, as: 'customer' }
      ]
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    res.json({
      success: true,
      data: { order }
    });
  } catch (error) {
    logger.error('Get order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get order'
    });
  }
});

/**
 * @route   GET /api/v1/orders
 * @desc    Get all orders (with filters)
 * @access  Private (Staff only)
 */
router.get('/', authenticate, authorize('admin', 'manager', 'staff', 'kitchen'), async (req, res) => {
  try {
    const { status, type, startDate, endDate, limit = 50, offset = 0 } = req.query;

    const where = {};
    if (status) where.status = status;
    if (type) where.type = type;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.$gte = new Date(startDate);
      if (endDate) where.createdAt.$lte = new Date(endDate);
    }

    const orders = await Order.findAll({
      where,
      include: [
        { model: Customer, as: 'customer' }
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']]
    });

    const total = await Order.count({ where });

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          total,
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    logger.error('Get orders error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get orders'
    });
  }
});

/**
 * @route   PATCH /api/v1/orders/:id/status
 * @desc    Update order status
 * @access  Private (Staff only)
 */
router.patch('/:id/status', [
  authenticate,
  authorize('admin', 'manager', 'staff', 'kitchen'),
  param('id').isUUID(),
  body('status').isIn(['pending', 'confirmed', 'preparing', 'ready', 'out-for-delivery', 'completed', 'cancelled'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const order = await Order.findByPk(req.params.id);
    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    const { status } = req.body;
    await order.updateStatus(status);

    // Emit real-time update
    emitOrderStatusUpdate(order.id, status);

    logger.logOrderEvent('status_updated', order.id, {
      oldStatus: order.status,
      newStatus: status,
      updatedBy: req.userId
    });

    res.json({
      success: true,
      data: { order }
    });
  } catch (error) {
    logger.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update order status'
    });
  }
});

/**
 * @route   DELETE /api/v1/orders/:id
 * @desc    Cancel an order
 * @access  Private (Staff or customer)
 */
router.delete('/:id', [
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const order = await Order.findByPk(req.params.id);
    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    if (!order.canCancel()) {
      return res.status(400).json({
        success: false,
        error: `Cannot cancel order in ${order.status} status`
      });
    }

    await order.updateStatus('cancelled');

    // Emit real-time update
    emitOrderStatusUpdate(order.id, 'cancelled');

    logger.logOrderEvent('order_cancelled', order.id);

    res.json({
      success: true,
      message: 'Order cancelled successfully'
    });
  } catch (error) {
    logger.error('Cancel order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cancel order'
    });
  }
});

module.exports = router;
