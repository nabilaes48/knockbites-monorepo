const express = require('express');
const router = express.Router();
const { body, param, validationResult } = require('express-validator');
const StripeService = require('../services/stripe.service');
const { authenticate, authorize } = require('../middleware/auth');
const { emitPaymentUpdate } = require('../sockets/orderSocket');
const logger = require('../config/logger');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * @route   POST /api/v1/payments/create-intent
 * @desc    Create a payment intent
 * @access  Public
 */
router.post('/create-intent', [
  body('orderId').isUUID(),
  body('customerId').isUUID(),
  body('amount').isFloat({ min: 0.5 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { orderId, customerId, amount } = req.body;

    const result = await StripeService.createPaymentIntent(
      orderId,
      customerId,
      amount
    );

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    logger.error('Create payment intent error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create payment intent'
    });
  }
});

/**
 * @route   POST /api/v1/payments/confirm
 * @desc    Confirm a payment
 * @access  Public
 */
router.post('/confirm', [
  body('paymentIntentId').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { paymentIntentId } = req.body;

    const result = await StripeService.confirmPayment(paymentIntentId);

    // Emit real-time update
    if (result.payment) {
      emitPaymentUpdate(result.payment.orderId, 'completed');
    }

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    logger.error('Confirm payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to confirm payment'
    });
  }
});

/**
 * @route   POST /api/v1/payments/:id/refund
 * @desc    Process a refund
 * @access  Private (Admin/Manager only)
 */
router.post('/:id/refund', [
  authenticate,
  authorize('admin', 'manager'),
  param('id').isUUID(),
  body('amount').optional().isFloat({ min: 0.01 }),
  body('reason').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { amount, reason } = req.body;

    const result = await StripeService.processRefund(
      req.params.id,
      amount,
      reason || 'Refund requested'
    );

    // Emit real-time update
    if (result.payment) {
      emitPaymentUpdate(result.payment.orderId, result.payment.status);
    }

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    logger.error('Process refund error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to process refund'
    });
  }
});

/**
 * @route   GET /api/v1/payments/:id
 * @desc    Get payment details
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

    const result = await StripeService.getPaymentDetails(req.params.id);

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    logger.error('Get payment details error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to get payment details'
    });
  }
});

/**
 * @route   POST /api/v1/payments/webhook
 * @desc    Handle Stripe webhooks
 * @access  Public (Stripe)
 */
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
      logger.error('Webhook signature verification failed:', err);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle the event
    await StripeService.handleWebhook(event);

    res.json({ received: true });
  } catch (error) {
    logger.error('Webhook error:', error);
    res.status(500).json({
      success: false,
      error: 'Webhook handling failed'
    });
  }
});

module.exports = router;
