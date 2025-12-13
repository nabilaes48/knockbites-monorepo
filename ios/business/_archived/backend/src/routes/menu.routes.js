const express = require('express');
const router = express.Router();
const { body, param, validationResult } = require('express-validator');
const { MenuItem } = require('../models');
const { authenticate, authorize } = require('../middleware/auth');
const logger = require('../config/logger');

/**
 * @route   GET /api/v1/menu
 * @desc    Get all menu items
 * @access  Public
 */
router.get('/', async (req, res) => {
  try {
    const { categoryId, isAvailable, isFeatured } = req.query;

    const where = {};
    if (categoryId) where.categoryId = categoryId;
    if (isAvailable !== undefined) where.isAvailable = isAvailable === 'true';
    if (isFeatured !== undefined) where.isFeatured = isFeatured === 'true';

    const menuItems = await MenuItem.findAll({
      where,
      order: [['sortOrder', 'ASC'], ['name', 'ASC']]
    });

    res.json({
      success: true,
      data: { menuItems }
    });
  } catch (error) {
    logger.error('Get menu items error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get menu items'
    });
  }
});

/**
 * @route   GET /api/v1/menu/:id
 * @desc    Get menu item by ID
 * @access  Public
 */
router.get('/:id', [
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const menuItem = await MenuItem.findByPk(req.params.id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        error: 'Menu item not found'
      });
    }

    res.json({
      success: true,
      data: { menuItem }
    });
  } catch (error) {
    logger.error('Get menu item error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get menu item'
    });
  }
});

/**
 * @route   POST /api/v1/menu
 * @desc    Create a new menu item
 * @access  Private (Admin/Manager only)
 */
router.post('/', [
  authenticate,
  authorize('admin', 'manager'),
  body('name').trim().notEmpty(),
  body('description').trim().notEmpty(),
  body('price').isFloat({ min: 0 }),
  body('categoryId').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const menuItem = await MenuItem.create(req.body);

    logger.info(`Menu item created: ${menuItem.id} (${menuItem.name})`);

    res.status(201).json({
      success: true,
      data: { menuItem }
    });
  } catch (error) {
    logger.error('Create menu item error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create menu item'
    });
  }
});

/**
 * @route   PATCH /api/v1/menu/:id
 * @desc    Update a menu item
 * @access  Private (Admin/Manager only)
 */
router.patch('/:id', [
  authenticate,
  authorize('admin', 'manager'),
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const menuItem = await MenuItem.findByPk(req.params.id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        error: 'Menu item not found'
      });
    }

    await menuItem.update(req.body);

    logger.info(`Menu item updated: ${menuItem.id} (${menuItem.name})`);

    res.json({
      success: true,
      data: { menuItem }
    });
  } catch (error) {
    logger.error('Update menu item error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update menu item'
    });
  }
});

/**
 * @route   DELETE /api/v1/menu/:id
 * @desc    Delete a menu item
 * @access  Private (Admin only)
 */
router.delete('/:id', [
  authenticate,
  authorize('admin'),
  param('id').isUUID()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const menuItem = await MenuItem.findByPk(req.params.id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        error: 'Menu item not found'
      });
    }

    await menuItem.destroy();

    logger.info(`Menu item deleted: ${req.params.id}`);

    res.json({
      success: true,
      message: 'Menu item deleted successfully'
    });
  } catch (error) {
    logger.error('Delete menu item error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete menu item'
    });
  }
});

module.exports = router;
