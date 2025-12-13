const Stripe = require('stripe');
const logger = require('../config/logger');
const { Payment, Order, Customer } = require('../models');

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

class StripeService {
  /**
   * Create a payment intent for an order
   */
  static async createPaymentIntent(orderId, customerId, amount, metadata = {}) {
    try {
      const order = await Order.findByPk(orderId);
      const customer = await Customer.findByPk(customerId);

      if (!order) {
        throw new Error('Order not found');
      }

      // Get or create Stripe customer
      let stripeCustomerId = null;
      if (customer && customer.email) {
        const stripeCustomers = await stripe.customers.list({
          email: customer.email,
          limit: 1
        });

        if (stripeCustomers.data.length > 0) {
          stripeCustomerId = stripeCustomers.data[0].id;
        } else {
          const stripeCustomer = await stripe.customers.create({
            email: customer.email,
            phone: customer.phone,
            name: `${customer.firstName} ${customer.lastName}`,
            metadata: {
              customerId: customer.id
            }
          });
          stripeCustomerId = stripeCustomer.id;
        }
      }

      // Create payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: 'usd',
        customer: stripeCustomerId,
        metadata: {
          orderId: order.id,
          orderNumber: order.orderNumber,
          customerId: customerId,
          ...metadata
        },
        automatic_payment_methods: {
          enabled: true
        },
        description: `Order ${order.orderNumber} - ${order.customerName}`
      });

      // Create payment record
      const payment = await Payment.create({
        orderId: order.id,
        customerId: customerId,
        amount: amount,
        currency: 'usd',
        paymentMethod: 'card',
        status: 'pending',
        stripePaymentIntentId: paymentIntent.id,
        stripeCustomerId: stripeCustomerId
      });

      // Calculate and save processing fee
      payment.calculateProcessingFee();
      await payment.save();

      // Update order with payment ID
      order.paymentId = payment.id;
      await order.save();

      logger.logPaymentEvent('payment_intent_created', payment.id, {
        orderId: order.id,
        amount: amount
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        paymentId: payment.id
      };
    } catch (error) {
      logger.error('Error creating payment intent:', error);
      throw error;
    }
  }

  /**
   * Confirm a payment
   */
  static async confirmPayment(paymentIntentId) {
    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      const payment = await Payment.findOne({
        where: { stripePaymentIntentId: paymentIntentId }
      });

      if (!payment) {
        throw new Error('Payment not found');
      }

      if (paymentIntent.status === 'succeeded') {
        await payment.markAsSucceeded(paymentIntent.latest_charge);

        // Update order payment status
        const order = await Order.findByPk(payment.orderId);
        if (order) {
          order.paymentStatus = 'completed';
          await order.save();
        }

        logger.logPaymentEvent('payment_succeeded', payment.id, {
          orderId: payment.orderId
        });

        return { success: true, payment };
      } else {
        throw new Error(`Payment status: ${paymentIntent.status}`);
      }
    } catch (error) {
      logger.error('Error confirming payment:', error);
      throw error;
    }
  }

  /**
   * Process a refund
   */
  static async processRefund(paymentId, amount = null, reason = '') {
    try {
      const payment = await Payment.findByPk(paymentId);

      if (!payment) {
        throw new Error('Payment not found');
      }

      if (!payment.stripeChargeId) {
        throw new Error('No charge ID found for refund');
      }

      // Create refund in Stripe
      const refund = await stripe.refunds.create({
        charge: payment.stripeChargeId,
        amount: amount ? Math.round(amount * 100) : undefined,
        reason: reason || 'requested_by_customer',
        metadata: {
          paymentId: payment.id,
          orderId: payment.orderId
        }
      });

      // Update payment record
      const refundAmount = amount || parseFloat(payment.amount);
      await payment.processRefund(refundAmount, reason);

      // Update order status
      const order = await Order.findByPk(payment.orderId);
      if (order) {
        order.paymentStatus = payment.status === 'refunded' ? 'refunded' : 'processing';
        if (order.status !== 'cancelled') {
          order.status = 'cancelled';
        }
        await order.save();
      }

      logger.logPaymentEvent('refund_processed', payment.id, {
        orderId: payment.orderId,
        refundAmount: refundAmount,
        refundId: refund.id
      });

      return { success: true, refund, payment };
    } catch (error) {
      logger.error('Error processing refund:', error);
      throw error;
    }
  }

  /**
   * Handle Stripe webhook events
   */
  static async handleWebhook(event) {
    try {
      switch (event.type) {
        case 'payment_intent.succeeded':
          await this.handlePaymentIntentSucceeded(event.data.object);
          break;

        case 'payment_intent.payment_failed':
          await this.handlePaymentIntentFailed(event.data.object);
          break;

        case 'charge.refunded':
          await this.handleChargeRefunded(event.data.object);
          break;

        case 'customer.created':
          logger.info('Stripe customer created:', event.data.object.id);
          break;

        default:
          logger.info(`Unhandled webhook event type: ${event.type}`);
      }

      return { success: true };
    } catch (error) {
      logger.error('Error handling webhook:', error);
      throw error;
    }
  }

  /**
   * Handle successful payment intent
   */
  static async handlePaymentIntentSucceeded(paymentIntent) {
    const payment = await Payment.findOne({
      where: { stripePaymentIntentId: paymentIntent.id }
    });

    if (payment) {
      await payment.markAsSucceeded(paymentIntent.latest_charge);

      const order = await Order.findByPk(payment.orderId);
      if (order) {
        order.paymentStatus = 'completed';
        order.status = 'confirmed';
        await order.save();
      }

      // Update customer stats
      const customer = await Customer.findByPk(payment.customerId);
      if (customer) {
        customer.totalSpent = parseFloat(customer.totalSpent) + parseFloat(payment.amount);
        customer.orderCount += 1;
        customer.lastOrderDate = new Date();

        // Add loyalty points (1 point per dollar)
        const pointsEarned = Math.floor(parseFloat(payment.amount));
        await customer.addLoyaltyPoints(pointsEarned);

        await customer.save();
      }

      logger.logPaymentEvent('payment_intent_succeeded', payment.id, {
        orderId: payment.orderId
      });
    }
  }

  /**
   * Handle failed payment intent
   */
  static async handlePaymentIntentFailed(paymentIntent) {
    const payment = await Payment.findOne({
      where: { stripePaymentIntentId: paymentIntent.id }
    });

    if (payment) {
      await payment.markAsFailed(
        paymentIntent.last_payment_error?.code,
        paymentIntent.last_payment_error?.message
      );

      const order = await Order.findByPk(payment.orderId);
      if (order) {
        order.paymentStatus = 'failed';
        await order.save();
      }

      logger.logPaymentEvent('payment_intent_failed', payment.id, {
        orderId: payment.orderId,
        error: paymentIntent.last_payment_error?.message
      });
    }
  }

  /**
   * Handle charge refunded
   */
  static async handleChargeRefunded(charge) {
    const payment = await Payment.findOne({
      where: { stripeChargeId: charge.id }
    });

    if (payment) {
      const refundAmount = charge.amount_refunded / 100;
      await payment.processRefund(refundAmount, 'Refunded via Stripe dashboard');

      logger.logPaymentEvent('charge_refunded', payment.id, {
        orderId: payment.orderId,
        refundAmount: refundAmount
      });
    }
  }

  /**
   * Get payment details
   */
  static async getPaymentDetails(paymentId) {
    try {
      const payment = await Payment.findByPk(paymentId, {
        include: [
          { model: Order, as: 'order' },
          { model: Customer, as: 'customer' }
        ]
      });

      if (!payment) {
        throw new Error('Payment not found');
      }

      // Get Stripe payment intent details
      let stripeDetails = null;
      if (payment.stripePaymentIntentId) {
        stripeDetails = await stripe.paymentIntents.retrieve(payment.stripePaymentIntentId);
      }

      return {
        payment,
        stripeDetails
      };
    } catch (error) {
      logger.error('Error getting payment details:', error);
      throw error;
    }
  }
}

module.exports = StripeService;
