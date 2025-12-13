const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Order = sequelize.define('Order', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  orderNumber: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false,
    field: 'order_number'
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
  // Order Details
  items: {
    type: DataTypes.JSONB,
    allowNull: false,
    comment: 'Array of order items with customizations'
  },
  subtotal: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  tax: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  tip: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00
  },
  deliveryFee: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    field: 'delivery_fee'
  },
  discount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00
  },
  total: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  // Order Type
  type: {
    type: DataTypes.ENUM('dine-in', 'takeout', 'delivery'),
    allowNull: false
  },
  // Status
  status: {
    type: DataTypes.ENUM('pending', 'confirmed', 'preparing', 'ready', 'out-for-delivery', 'completed', 'cancelled'),
    defaultValue: 'pending',
    allowNull: false
  },
  // Payment
  paymentId: {
    type: DataTypes.UUID,
    allowNull: true,
    field: 'payment_id',
    references: {
      model: 'payments',
      key: 'id'
    }
  },
  paymentStatus: {
    type: DataTypes.ENUM('pending', 'processing', 'completed', 'failed', 'refunded'),
    defaultValue: 'pending',
    field: 'payment_status'
  },
  // Timing
  scheduledFor: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'scheduled_for'
  },
  estimatedReadyTime: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'estimated_ready_time'
  },
  actualReadyTime: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'actual_ready_time'
  },
  completedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'completed_at'
  },
  // Delivery Info
  deliveryAddress: {
    type: DataTypes.JSONB,
    allowNull: true,
    field: 'delivery_address'
  },
  driverId: {
    type: DataTypes.UUID,
    allowNull: true,
    field: 'driver_id'
  },
  deliveryInstructions: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'delivery_instructions'
  },
  // Customer Info
  customerName: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'customer_name'
  },
  customerPhone: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'customer_phone'
  },
  customerEmail: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'customer_email'
  },
  // Loyalty & Promotions
  loyaltyPointsEarned: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'loyalty_points_earned'
  },
  loyaltyPointsUsed: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'loyalty_points_used'
  },
  couponCode: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'coupon_code'
  },
  // Special Instructions
  specialInstructions: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'special_instructions'
  },
  // Staff Assignment
  assignedToUserId: {
    type: DataTypes.UUID,
    allowNull: true,
    field: 'assigned_to_user_id'
  },
  // Ratings & Reviews
  rating: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1,
      max: 5
    }
  },
  reviewText: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'review_text'
  },
  // Metadata
  source: {
    type: DataTypes.ENUM('ios-app', 'web-app', 'phone', 'walk-in', 'third-party'),
    defaultValue: 'ios-app'
  },
  metadata: {
    type: DataTypes.JSONB,
    defaultValue: {}
  }
}, {
  tableName: 'orders',
  timestamps: true,
  indexes: [
    { fields: ['customer_id'] },
    { fields: ['order_number'] },
    { fields: ['status'] },
    { fields: ['type'] },
    { fields: ['payment_status'] },
    { fields: ['created_at'] },
    { fields: ['scheduled_for'] }
  ]
});

// Hooks
Order.beforeCreate(async (order) => {
  // Generate order number if not provided
  if (!order.orderNumber) {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const randomStr = Math.random().toString(36).substring(2, 6).toUpperCase();
    order.orderNumber = `ORD-${dateStr}-${randomStr}`;
  }

  // Calculate estimated ready time based on items
  if (!order.estimatedReadyTime) {
    const prepTime = order.items.reduce((total, item) => total + (item.prepTime || 15), 0);
    const avgPrepTime = prepTime / order.items.length;
    order.estimatedReadyTime = new Date(Date.now() + avgPrepTime * 60000);
  }
});

// Instance methods
Order.prototype.updateStatus = async function(newStatus) {
  this.status = newStatus;

  if (newStatus === 'ready' && !this.actualReadyTime) {
    this.actualReadyTime = new Date();
  }

  if (newStatus === 'completed' && !this.completedAt) {
    this.completedAt = new Date();
  }

  return this.save();
};

Order.prototype.calculateTotal = function() {
  const subtotal = parseFloat(this.subtotal);
  const tax = parseFloat(this.tax);
  const tip = parseFloat(this.tip || 0);
  const deliveryFee = parseFloat(this.deliveryFee || 0);
  const discount = parseFloat(this.discount || 0);

  this.total = (subtotal + tax + tip + deliveryFee - discount).toFixed(2);
};

Order.prototype.canCancel = function() {
  return ['pending', 'confirmed'].includes(this.status);
};

Order.prototype.canModify = function() {
  return ['pending', 'confirmed'].includes(this.status);
};

Order.prototype.getPreparationTime = function() {
  if (this.actualReadyTime && this.createdAt) {
    return Math.round((this.actualReadyTime - this.createdAt) / 60000); // minutes
  }
  return null;
};

module.exports = Order;
