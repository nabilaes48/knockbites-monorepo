const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const { Order, Payment, Customer, MenuItem } = require('../models');
const { sequelize } = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const logger = require('../config/logger');

/**
 * @route   GET /api/v1/analytics/dashboard
 * @desc    Get dashboard analytics
 * @access  Private (Admin/Manager only)
 */
router.get('/dashboard', [
  authenticate,
  authorize('admin', 'manager')
], async (req, res) => {
  try {
    const { period = 'today' } = req.query;

    let startDate, endDate = new Date();

    switch (period) {
      case 'today':
        startDate = new Date();
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'week':
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      default:
        startDate = new Date();
        startDate.setHours(0, 0, 0, 0);
    }

    // Total revenue
    const revenue = await Payment.sum('amount', {
      where: {
        status: 'succeeded',
        createdAt: {
          [Op.between]: [startDate, endDate]
        }
      }
    }) || 0;

    // Total orders
    const totalOrders = await Order.count({
      where: {
        createdAt: {
          [Op.between]: [startDate, endDate]
        }
      }
    });

    // Average order value
    const avgOrderValue = totalOrders > 0 ? (revenue / totalOrders) : 0;

    // Orders by status
    const ordersByStatus = await Order.findAll({
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        createdAt: {
          [Op.between]: [startDate, endDate]
        }
      },
      group: ['status']
    });

    // Orders by type
    const ordersByType = await Order.findAll({
      attributes: [
        'type',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        createdAt: {
          [Op.between]: [startDate, endDate]
        }
      },
      group: ['type']
    });

    // New customers
    const newCustomers = await Customer.count({
      where: {
        createdAt: {
          [Op.between]: [startDate, endDate]
        }
      }
    });

    res.json({
      success: true,
      data: {
        period,
        summary: {
          revenue: parseFloat(revenue).toFixed(2),
          totalOrders,
          avgOrderValue: parseFloat(avgOrderValue).toFixed(2),
          newCustomers
        },
        ordersByStatus,
        ordersByType
      }
    });
  } catch (error) {
    logger.error('Dashboard analytics error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get dashboard analytics'
    });
  }
});

/**
 * @route   GET /api/v1/analytics/revenue
 * @desc    Get revenue analytics with time series
 * @access  Private (Admin/Manager only)
 */
router.get('/revenue', [
  authenticate,
  authorize('admin', 'manager')
], async (req, res) => {
  try {
    const { period = 'week', groupBy = 'day' } = req.query;

    let startDate, endDate = new Date();

    switch (period) {
      case 'week':
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      case 'year':
        startDate = new Date();
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      default:
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);
    }

    const dateFormat = groupBy === 'month' ? '%Y-%m' : '%Y-%m-%d';

    const revenueData = await Payment.findAll({
      attributes: [
        [sequelize.fn('DATE_FORMAT', sequelize.col('created_at'), dateFormat), 'date'],
        [sequelize.fn('SUM', sequelize.col('amount')), 'revenue'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'transactions']
      ],
      where: {
        status: 'succeeded',
        createdAt: {
          [Op.between]: [startDate, endDate]
        }
      },
      group: [sequelize.fn('DATE_FORMAT', sequelize.col('created_at'), dateFormat)],
      order: [[sequelize.fn('DATE_FORMAT', sequelize.col('created_at'), dateFormat), 'ASC']]
    });

    res.json({
      success: true,
      data: {
        period,
        groupBy,
        revenueData
      }
    });
  } catch (error) {
    logger.error('Revenue analytics error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get revenue analytics'
    });
  }
});

/**
 * @route   GET /api/v1/analytics/popular-items
 * @desc    Get popular menu items
 * @access  Private (Admin/Manager only)
 */
router.get('/popular-items', [
  authenticate,
  authorize('admin', 'manager')
], async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const popularItems = await MenuItem.findAll({
      attributes: [
        'id',
        'name',
        'price',
        'orderCount',
        'totalRevenue',
        'averageRating'
      ],
      where: {
        isAvailable: true
      },
      order: [['orderCount', 'DESC']],
      limit: parseInt(limit)
    });

    res.json({
      success: true,
      data: { popularItems }
    });
  } catch (error) {
    logger.error('Popular items analytics error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get popular items'
    });
  }
});

/**
 * @route   GET /api/v1/analytics/customers
 * @desc    Get customer analytics
 * @access  Private (Admin/Manager only)
 */
router.get('/customers', [
  authenticate,
  authorize('admin', 'manager')
], async (req, res) => {
  try {
    // Customer distribution by loyalty tier
    const loyaltyDistribution = await Customer.findAll({
      attributes: [
        'loyaltyTier',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: ['loyaltyTier']
    });

    // Top customers by spending
    const topCustomers = await Customer.findAll({
      attributes: ['id', 'firstName', 'lastName', 'totalSpent', 'orderCount', 'loyaltyPoints'],
      order: [['totalSpent', 'DESC']],
      limit: 10
    });

    // Total customers
    const totalCustomers = await Customer.count();

    // Active customers (ordered in last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const activeCustomers = await Customer.count({
      where: {
        lastOrderDate: {
          [Op.gte]: thirtyDaysAgo
        }
      }
    });

    res.json({
      success: true,
      data: {
        totalCustomers,
        activeCustomers,
        loyaltyDistribution,
        topCustomers
      }
    });
  } catch (error) {
    logger.error('Customer analytics error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get customer analytics'
    });
  }
});

module.exports = router;
