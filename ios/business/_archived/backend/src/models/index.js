const { sequelize } = require('../config/database');
const User = require('./User');
const Customer = require('./Customer');
const MenuItem = require('./MenuItem');
const Order = require('./Order');
const Payment = require('./Payment');

// Define relationships

// Customer - Order relationship (One-to-Many)
Customer.hasMany(Order, {
  foreignKey: 'customerId',
  as: 'orders'
});
Order.belongsTo(Customer, {
  foreignKey: 'customerId',
  as: 'customer'
});

// Order - Payment relationship (One-to-One)
Order.hasOne(Payment, {
  foreignKey: 'orderId',
  as: 'payment'
});
Payment.belongsTo(Order, {
  foreignKey: 'orderId',
  as: 'order'
});

// Customer - Payment relationship (One-to-Many)
Customer.hasMany(Payment, {
  foreignKey: 'customerId',
  as: 'payments'
});
Payment.belongsTo(Customer, {
  foreignKey: 'customerId',
  as: 'customer'
});

// User - Order relationship (assigned staff)
User.hasMany(Order, {
  foreignKey: 'assignedToUserId',
  as: 'assignedOrders'
});
Order.belongsTo(User, {
  foreignKey: 'assignedToUserId',
  as: 'assignedStaff'
});

const models = {
  sequelize,
  User,
  Customer,
  MenuItem,
  Order,
  Payment
};

module.exports = models;
