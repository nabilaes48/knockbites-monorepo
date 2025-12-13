const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Payment = sequelize.define('Payment', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  orderId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'order_id',
    references: {
      model: 'orders',
      key: 'id'
    }
  },
  customerId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'customer_id',
    references: {
      model: 'customers',
      key: 'id'
    }
  },
  // Amount Details
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  },
  currency: {
    type: DataTypes.STRING(3),
    defaultValue: 'USD',
    allowNull: false
  },
  // Payment Method
  paymentMethod: {
    type: DataTypes.ENUM('card', 'apple-pay', 'google-pay', 'cash', 'loyalty-points'),
    allowNull: false,
    field: 'payment_method'
  },
  // Card Details (last 4 digits only)
  cardLast4: {
    type: DataTypes.STRING(4),
    allowNull: true,
    field: 'card_last4'
  },
  cardBrand: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'card_brand',
    comment: 'e.g., visa, mastercard, amex'
  },
  // Status
  status: {
    type: DataTypes.ENUM('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded', 'partially_refunded'),
    defaultValue: 'pending',
    allowNull: false
  },
  // Stripe Integration
  stripePaymentIntentId: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: true,
    field: 'stripe_payment_intent_id'
  },
  stripeChargeId: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'stripe_charge_id'
  },
  stripeCustomerId: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'stripe_customer_id'
  },
  // Refund Information
  refundedAmount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    field: 'refunded_amount'
  },
  refundReason: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'refund_reason'
  },
  refundedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'refunded_at'
  },
  // Processing Details
  processingFee: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    field: 'processing_fee',
    comment: 'Payment processor fee'
  },
  netAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    field: 'net_amount',
    comment: 'Amount after processing fees'
  },
  // Timestamps
  authorizedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'authorized_at'
  },
  capturedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'captured_at'
  },
  failedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'failed_at'
  },
  // Error Information
  errorCode: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'error_code'
  },
  errorMessage: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'error_message'
  },
  // Metadata
  metadata: {
    type: DataTypes.JSONB,
    defaultValue: {}
  },
  // Receipt
  receiptUrl: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'receipt_url'
  },
  receiptNumber: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: true,
    field: 'receipt_number'
  }
}, {
  tableName: 'payments',
  timestamps: true,
  indexes: [
    { fields: ['order_id'] },
    { fields: ['customer_id'] },
    { fields: ['status'] },
    { fields: ['stripe_payment_intent_id'] },
    { fields: ['created_at'] }
  ]
});

// Hooks
Payment.beforeCreate(async (payment) => {
  // Generate receipt number
  if (!payment.receiptNumber) {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const randomStr = Math.random().toString(36).substring(2, 8).toUpperCase();
    payment.receiptNumber = `RCP-${dateStr}-${randomStr}`;
  }

  // Calculate net amount
  if (payment.amount && payment.processingFee) {
    payment.netAmount = (parseFloat(payment.amount) - parseFloat(payment.processingFee)).toFixed(2);
  }
});

// Instance methods
Payment.prototype.markAsSucceeded = async function(stripeChargeId = null) {
  this.status = 'succeeded';
  this.capturedAt = new Date();
  if (stripeChargeId) {
    this.stripeChargeId = stripeChargeId;
  }
  return this.save();
};

Payment.prototype.markAsFailed = async function(errorCode, errorMessage) {
  this.status = 'failed';
  this.failedAt = new Date();
  this.errorCode = errorCode;
  this.errorMessage = errorMessage;
  return this.save();
};

Payment.prototype.processRefund = async function(amount, reason) {
  const refundAmount = amount || parseFloat(this.amount);
  const currentRefunded = parseFloat(this.refundedAmount);
  const totalAmount = parseFloat(this.amount);

  if (currentRefunded + refundAmount > totalAmount) {
    throw new Error('Refund amount exceeds payment amount');
  }

  this.refundedAmount = (currentRefunded + refundAmount).toFixed(2);
  this.refundReason = reason;
  this.refundedAt = new Date();

  if (this.refundedAmount === this.amount) {
    this.status = 'refunded';
  } else {
    this.status = 'partially_refunded';
  }

  return this.save();
};

Payment.prototype.calculateProcessingFee = function() {
  // Stripe standard fee: 2.9% + $0.30
  const amount = parseFloat(this.amount);
  this.processingFee = ((amount * 0.029) + 0.30).toFixed(2);
  this.netAmount = (amount - parseFloat(this.processingFee)).toFixed(2);
};

module.exports = Payment;
