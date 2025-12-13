const socketIo = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const redis = require('redis');
const logger = require('../config/logger');
const { verifyToken } = require('../middleware/auth');

let io;

/**
 * Initialize Socket.IO server with Redis adapter for horizontal scaling
 */
const initializeSocketServer = (server) => {
  io = socketIo(server, {
    cors: {
      origin: process.env.FRONTEND_URL || 'http://localhost:3000',
      credentials: true
    },
    transports: ['websocket', 'polling']
  });

  // Set up Redis adapter for pub/sub across server instances
  const pubClient = redis.createClient({
    socket: {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT) || 6379
    },
    password: process.env.REDIS_PASSWORD || undefined
  });

  const subClient = pubClient.duplicate();

  Promise.all([pubClient.connect(), subClient.connect()]).then(() => {
    io.adapter(createAdapter(pubClient, subClient));
    logger.info('Socket.IO Redis adapter initialized');
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;

      if (!token) {
        return next(new Error('Authentication required'));
      }

      const decoded = verifyToken(token);

      if (!decoded) {
        return next(new Error('Invalid token'));
      }

      socket.userId = decoded.userId;
      socket.userRole = decoded.role;
      next();
    } catch (error) {
      logger.error('Socket authentication error:', error);
      next(new Error('Authentication failed'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    logger.info(`Client connected: ${socket.id} (User: ${socket.userId})`);

    // Join appropriate rooms based on user role
    if (socket.userRole === 'admin' || socket.userRole === 'manager' || socket.userRole === 'kitchen') {
      socket.join('staff');
      socket.join('kitchen');
      logger.info(`User ${socket.userId} joined staff/kitchen rooms`);
    }

    // Join store-specific room (for multi-location support)
    const storeId = socket.handshake.query.storeId || 'default';
    socket.join(`store:${storeId}`);

    // Handle order subscription
    socket.on('subscribe:order', (orderId) => {
      socket.join(`order:${orderId}`);
      logger.info(`User ${socket.userId} subscribed to order ${orderId}`);
    });

    // Handle order unsubscription
    socket.on('unsubscribe:order', (orderId) => {
      socket.leave(`order:${orderId}`);
      logger.info(`User ${socket.userId} unsubscribed from order ${orderId}`);
    });

    // Handle kitchen status updates (from kitchen staff)
    socket.on('order:statusUpdate', async (data) => {
      if (socket.userRole === 'kitchen' || socket.userRole === 'admin' || socket.userRole === 'manager') {
        const { orderId, status, estimatedTime } = data;

        // Broadcast to all clients subscribed to this order
        io.to(`order:${orderId}`).emit('order:statusChanged', {
          orderId,
          status,
          estimatedTime,
          timestamp: new Date().toISOString()
        });

        logger.logOrderEvent('status_update', orderId, { status, estimatedTime });
      }
    });

    // Handle typing indicators for special instructions
    socket.on('order:typing', (data) => {
      socket.to(`order:${data.orderId}`).emit('order:typingIndicator', {
        userId: socket.userId,
        isTyping: data.isTyping
      });
    });

    // Handle driver location updates
    socket.on('driver:locationUpdate', (data) => {
      if (socket.userRole === 'driver') {
        const { orderId, latitude, longitude } = data;
        io.to(`order:${orderId}`).emit('driver:locationChanged', {
          orderId,
          location: { latitude, longitude },
          timestamp: new Date().toISOString()
        });
      }
    });

    // Disconnect handler
    socket.on('disconnect', () => {
      logger.info(`Client disconnected: ${socket.id} (User: ${socket.userId})`);
    });

    // Error handler
    socket.on('error', (error) => {
      logger.error(`Socket error for ${socket.id}:`, error);
    });
  });

  return io;
};

/**
 * Get Socket.IO instance
 */
const getIO = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};

/**
 * Emit new order notification to staff
 */
const emitNewOrder = (order) => {
  if (io) {
    io.to('staff').emit('order:new', {
      order,
      timestamp: new Date().toISOString(),
      requiresAction: true
    });

    io.to('kitchen').emit('kitchen:newOrder', {
      orderId: order.id,
      orderNumber: order.orderNumber,
      items: order.items,
      estimatedReadyTime: order.estimatedReadyTime,
      type: order.type
    });

    logger.logOrderEvent('new_order_broadcast', order.id);
  }
};

/**
 * Emit order status update
 */
const emitOrderStatusUpdate = (orderId, status, additionalData = {}) => {
  if (io) {
    io.to(`order:${orderId}`).emit('order:statusChanged', {
      orderId,
      status,
      timestamp: new Date().toISOString(),
      ...additionalData
    });

    // Also notify staff room
    io.to('staff').emit('order:updated', {
      orderId,
      status,
      ...additionalData
    });

    logger.logOrderEvent('status_update_broadcast', orderId, { status });
  }
};

/**
 * Emit payment status update
 */
const emitPaymentUpdate = (orderId, paymentStatus, additionalData = {}) => {
  if (io) {
    io.to(`order:${orderId}`).emit('payment:statusChanged', {
      orderId,
      paymentStatus,
      timestamp: new Date().toISOString(),
      ...additionalData
    });

    logger.logPaymentEvent('payment_update_broadcast', orderId, { paymentStatus });
  }
};

/**
 * Emit notification to specific user
 */
const emitUserNotification = (userId, notification) => {
  if (io) {
    io.to(`user:${userId}`).emit('notification', {
      ...notification,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Emit kitchen alert (low stock, delays, etc.)
 */
const emitKitchenAlert = (alert) => {
  if (io) {
    io.to('kitchen').emit('kitchen:alert', {
      ...alert,
      timestamp: new Date().toISOString()
    });
  }
};

module.exports = {
  initializeSocketServer,
  getIO,
  emitNewOrder,
  emitOrderStatusUpdate,
  emitPaymentUpdate,
  emitUserNotification,
  emitKitchenAlert
};
