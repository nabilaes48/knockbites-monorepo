const express = require('express');
const router = express.Router();
const { body, param, validationResult } = require('express-validator');
const { Customer, Order } = require('../models');
const { authenticate, authorize } = require('../middleware/auth');
const logger = require('../config/logger');

/**
 * @route   POST /api/v1/customers
 * @desc    Create a new customer
 * @access  Public
 */
router.post('/', [
  body('firstName').trim().notEmpty(),
  body('lastName').trim().notEmpty(),
  body('phone').matches(/^\+?[\d\s\-()]+$/)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { firstName, lastName, phone, email } = req.body;

    // Check if customer already exists
    const existingCustomer = await Customer.findOne({ where: { phone } });
    if (existingCustomer) {
      return res.json({
        success: true,
        data: { customer: existingCustomer },
        message: 'Customer already exists'
      });
    }

    const customer = await Customer.create({
      firstName,
      lastName,
      phone,
      email
    });

    logger.info(`Customer created: ${customer.id} (${customer.firstName} ${customer.lastName})`);

    res.status(201).json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    logger.error('Create customer error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create customer'
    });
  }
});

/**
 * @route   GET /api/v1/customers/:id
 * @desc    Get customer by ID
 * @access  Private
 */
router.get('/:id', [
  authenticate,
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const customer = await Customer.findByPk(req.params.id, {
      include: [
        {
          model: Order,
          as: 'orders',
          limit: 10,
          order: [['createdAt', 'DESC']]
        }
      ]
    });

    if (!customer) {
      return res.status(404).json({
        success: false,
        error: 'Customer not found'
      });
    }

    res.json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    logger.error('Get customer error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get customer'
    });
  }
});

/**
 * @route   GET /api/v1/customers
 * @desc    Search/list customers
 * @access  Private (Staff only)
 */
router.get('/', [
  authenticate,
  authorize('admin', 'manager', 'staff')
], async (req, res) => {
  try {
    const { phone, email, loyaltyTier, limit = 50, offset = 0 } = req.query;

    const where = {};
    if (phone) where.phone = { $like: `%${phone}%` };
    if (email) where.email = { $like: `%${email}%` };
    if (loyaltyTier) where.loyaltyTier = loyaltyTier;

    const customers = await Customer.findAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']]
    });

    const total = await Customer.count({ where });

    res.json({
      success: true,
      data: {
        customers,
        pagination: {
          total,
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    logger.error('List customers error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to list customers'
    });
  }
});

/**
 * @route   PATCH /api/v1/customers/:id
 * @desc    Update customer
 * @access  Private
 */
router.patch('/:id', [
  authenticate,
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const customer = await Customer.findByPk(req.params.id);

    if (!customer) {
      return res.status(404).json({
        success: false,
        error: 'Customer not found'
      });
    }

    await customer.update(req.body);

    logger.info(`Customer updated: ${customer.id}`);

    res.json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    logger.error('Update customer error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update customer'
    });
  }
});

/**
 * @route   POST /api/v1/customers/:id/loyalty/add
 * @desc    Add loyalty points
 * @access  Private (Staff only)
 */
router.post('/:id/loyalty/add', [
  authenticate,
  authorize('admin', 'manager', 'staff'),
  param('id').isUUID(),
  body('points').isInt({ min: 1 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const customer = await Customer.findByPk(req.params.id);

    if (!customer) {
      return res.status(404).json({
        success: false,
        error: 'Customer not found'
      });
    }

    await customer.addLoyaltyPoints(req.body.points);

    logger.info(`Loyalty points added: ${req.body.points} to customer ${customer.id}`);

    res.json({
      success: true,
      data: { customer }
    });
  } catch (error) {
    logger.error('Add loyalty points error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add loyalty points'
    });
  }
});

module.exports = router;
