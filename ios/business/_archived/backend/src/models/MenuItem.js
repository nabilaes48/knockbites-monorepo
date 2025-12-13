const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const MenuItem = sequelize.define('MenuItem', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  },
  categoryId: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'category_id'
  },
  imageURL: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'image_url'
  },
  isAvailable: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    field: 'is_available'
  },
  prepTime: {
    type: DataTypes.INTEGER,
    defaultValue: 15,
    field: 'prep_time',
    comment: 'Preparation time in minutes'
  },
  calories: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  // Dietary Information
  dietaryInfo: {
    type: DataTypes.ARRAY(DataTypes.STRING),
    defaultValue: [],
    field: 'dietary_info',
    comment: 'e.g., ["vegetarian", "gluten-free"]'
  },
  // Customization Groups
  customizationGroups: {
    type: DataTypes.JSONB,
    defaultValue: [],
    field: 'customization_groups',
    comment: 'Array of customization options'
  },
  // Analytics
  orderCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'order_count'
  },
  totalRevenue: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    field: 'total_revenue'
  },
  averageRating: {
    type: DataTypes.DECIMAL(3, 2),
    allowNull: true,
    field: 'average_rating'
  },
  // Inventory
  trackInventory: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'track_inventory'
  },
  currentStock: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'current_stock'
  },
  lowStockThreshold: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'low_stock_threshold'
  },
  // Featured/Popular
  isFeatured: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'is_featured'
  },
  isPopular: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    field: 'is_popular'
  },
  // Pricing
  costPrice: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    field: 'cost_price',
    comment: 'Cost to make the item'
  },
  // Display Order
  sortOrder: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'sort_order'
  }
}, {
  tableName: 'menu_items',
  timestamps: true,
  indexes: [
    { fields: ['category_id'] },
    { fields: ['is_available'] },
    { fields: ['is_featured'] },
    { fields: ['is_popular'] },
    { fields: ['sort_order'] }
  ]
});

// Instance methods
MenuItem.prototype.incrementOrderCount = async function() {
  this.orderCount += 1;
  return this.save();
};

MenuItem.prototype.addRevenue = async function(amount) {
  this.totalRevenue = parseFloat(this.totalRevenue) + amount;
  return this.save();
};

MenuItem.prototype.updateStock = async function(quantity) {
  if (this.trackInventory) {
    this.currentStock -= quantity;
    if (this.currentStock <= 0) {
      this.isAvailable = false;
    }
    return this.save();
  }
};

MenuItem.prototype.checkLowStock = function() {
  if (this.trackInventory && this.lowStockThreshold) {
    return this.currentStock <= this.lowStockThreshold;
  }
  return false;
};

MenuItem.prototype.getProfitMargin = function() {
  if (this.costPrice) {
    const profit = parseFloat(this.price) - parseFloat(this.costPrice);
    return ((profit / parseFloat(this.price)) * 100).toFixed(2);
  }
  return null;
};

module.exports = MenuItem;
