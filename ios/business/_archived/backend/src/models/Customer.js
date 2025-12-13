const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Customer = sequelize.define('Customer', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      is: /^\+?[\d\s\-()]+$/
    }
  },
  firstName: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'first_name'
  },
  lastName: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'last_name'
  },
  // Loyalty Program Fields
  loyaltyPoints: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'loyalty_points'
  },
  loyaltyTier: {
    type: DataTypes.ENUM('bronze', 'silver', 'gold', 'platinum'),
    defaultValue: 'bronze',
    field: 'loyalty_tier'
  },
  totalSpent: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    field: 'total_spent'
  },
  orderCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'order_count'
  },
  // Contact Preferences
  smsOptIn: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    field: 'sms_opt_in'
  },
  emailOptIn: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    field: 'email_opt_in'
  },
  pushOptIn: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    field: 'push_opt_in'
  },
  // Saved Addresses
  addresses: {
    type: DataTypes.JSONB,
    defaultValue: []
  },
  // Favorite Items
  favoriteItems: {
    type: DataTypes.ARRAY(DataTypes.UUID),
    defaultValue: [],
    field: 'favorite_items'
  },
  // Last Order Info
  lastOrderDate: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'last_order_date'
  },
  // Account Status
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    field: 'is_active'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'customers',
  timestamps: true,
  indexes: [
    { fields: ['email'] },
    { fields: ['phone'] },
    { fields: ['loyalty_tier'] },
    { fields: ['created_at'] }
  ]
});

// Instance methods
Customer.prototype.addLoyaltyPoints = async function(points) {
  this.loyaltyPoints += points;
  await this.updateLoyaltyTier();
  return this.save();
};

Customer.prototype.deductLoyaltyPoints = async function(points) {
  if (this.loyaltyPoints < points) {
    throw new Error('Insufficient loyalty points');
  }
  this.loyaltyPoints -= points;
  await this.updateLoyaltyTier();
  return this.save();
};

Customer.prototype.updateLoyaltyTier = async function() {
  const spent = parseFloat(this.totalSpent);
  if (spent >= 2000) {
    this.loyaltyTier = 'platinum';
  } else if (spent >= 1000) {
    this.loyaltyTier = 'gold';
  } else if (spent >= 500) {
    this.loyaltyTier = 'silver';
  } else {
    this.loyaltyTier = 'bronze';
  }
};

Customer.prototype.addFavoriteItem = async function(itemId) {
  if (!this.favoriteItems.includes(itemId)) {
    this.favoriteItems.push(itemId);
    return this.save();
  }
};

Customer.prototype.removeFavoriteItem = async function(itemId) {
  this.favoriteItems = this.favoriteItems.filter(id => id !== itemId);
  return this.save();
};

module.exports = Customer;
