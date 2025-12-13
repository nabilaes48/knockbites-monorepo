const redis = require('redis');
const logger = require('./logger');

const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379
  },
  password: process.env.REDIS_PASSWORD || undefined,
  database: parseInt(process.env.REDIS_DB) || 0,
  lazyConnect: true
});

// Error handling
redisClient.on('error', (err) => {
  logger.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  logger.info('Redis client connected');
});

redisClient.on('ready', () => {
  logger.info('Redis client ready');
});

redisClient.on('end', () => {
  logger.info('Redis client connection closed');
});

// Connect to Redis
(async () => {
  try {
    await redisClient.connect();
  } catch (error) {
    logger.error('Failed to connect to Redis:', error);
  }
})();

// Helper functions for common operations
const redisHelper = {
  /**
   * Set key-value with optional expiration
   */
  async set(key, value, expirationSeconds = null) {
    try {
      const stringValue = typeof value === 'object' ? JSON.stringify(value) : value;
      if (expirationSeconds) {
        await redisClient.setEx(key, expirationSeconds, stringValue);
      } else {
        await redisClient.set(key, stringValue);
      }
      return true;
    } catch (error) {
      logger.error(`Redis SET error for key ${key}:`, error);
      return false;
    }
  },

  /**
   * Get value by key
   */
  async get(key) {
    try {
      const value = await redisClient.get(key);
      if (!value) return null;

      // Try to parse as JSON, if fails return raw value
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
    } catch (error) {
      logger.error(`Redis GET error for key ${key}:`, error);
      return null;
    }
  },

  /**
   * Delete key(s)
   */
  async del(...keys) {
    try {
      await redisClient.del(keys);
      return true;
    } catch (error) {
      logger.error(`Redis DEL error for keys ${keys}:`, error);
      return false;
    }
  },

  /**
   * Check if key exists
   */
  async exists(key) {
    try {
      return await redisClient.exists(key);
    } catch (error) {
      logger.error(`Redis EXISTS error for key ${key}:`, error);
      return false;
    }
  },

  /**
   * Set expiration on key
   */
  async expire(key, seconds) {
    try {
      await redisClient.expire(key, seconds);
      return true;
    } catch (error) {
      logger.error(`Redis EXPIRE error for key ${key}:`, error);
      return false;
    }
  },

  /**
   * Increment value
   */
  async incr(key) {
    try {
      return await redisClient.incr(key);
    } catch (error) {
      logger.error(`Redis INCR error for key ${key}:`, error);
      return null;
    }
  },

  /**
   * Publish message to channel
   */
  async publish(channel, message) {
    try {
      const stringMessage = typeof message === 'object' ? JSON.stringify(message) : message;
      await redisClient.publish(channel, stringMessage);
      return true;
    } catch (error) {
      logger.error(`Redis PUBLISH error for channel ${channel}:`, error);
      return false;
    }
  },

  /**
   * Get all keys matching pattern
   */
  async keys(pattern) {
    try {
      return await redisClient.keys(pattern);
    } catch (error) {
      logger.error(`Redis KEYS error for pattern ${pattern}:`, error);
      return [];
    }
  },

  /**
   * Cache a function result
   */
  async cacheFunction(key, fn, expirationSeconds = 3600) {
    const cached = await this.get(key);
    if (cached !== null) {
      return cached;
    }

    const result = await fn();
    await this.set(key, result, expirationSeconds);
    return result;
  }
};

module.exports = redisClient;
module.exports.helper = redisHelper;
