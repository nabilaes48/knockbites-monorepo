# Cameron's Business - Backend API

Node.js/Express backend API for the restaurant management system with real-time order processing, payment integration, and customer management.

## Features

- **Authentication & Authorization**: JWT-based auth with role-based access control
- **Real-time Updates**: WebSocket integration for live order tracking
- **Payment Processing**: Stripe integration for secure payments and refunds
- **Order Management**: Complete order lifecycle management
- **Customer Profiles**: Loyalty program and customer analytics
- **Menu Management**: CRUD operations for menu items
- **Analytics**: Revenue, orders, and customer insights

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 15+ with Sequelize ORM
- **Cache/Pub-Sub**: Redis 7+
- **WebSockets**: Socket.IO with Redis adapter
- **Payments**: Stripe
- **Authentication**: JWT (jsonwebtoken)
- **Validation**: express-validator
- **Logging**: Winston

## Prerequisites

Before running the backend, ensure you have:

- Node.js 18+ installed
- PostgreSQL 15+ running
- Redis 7+ running
- Stripe account (test mode credentials)

## Installation

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Setup

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and set the following required variables:

```env
# Server
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=camerons_business_dev
DB_USER=postgres
DB_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRES_IN=7d

# Stripe
STRIPE_SECRET_KEY=sk_test_your_test_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_test_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

### 3. Database Setup

Create the PostgreSQL database:

```bash
createdb camerons_business_dev
```

The application will automatically create tables on first run in development mode.

### 4. Start the Server

Development mode with auto-reload:

```bash
npm run dev
```

Production mode:

```bash
npm start
```

The server will start on `http://localhost:3000` (or your configured PORT).

## API Documentation

### Base URL

```
http://localhost:3000/api/v1
```

### Authentication

Most endpoints require authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Endpoints

#### Auth

- `POST /auth/register` - Register new user (staff)
- `POST /auth/login` - Login
- `POST /auth/refresh` - Refresh access token
- `GET /auth/me` - Get current user
- `POST /auth/logout` - Logout

#### Orders

- `POST /orders` - Create new order
- `GET /orders` - List orders (staff only)
- `GET /orders/:id` - Get order details
- `PATCH /orders/:id/status` - Update order status (staff only)
- `DELETE /orders/:id` - Cancel order

#### Payments

- `POST /payments/create-intent` - Create payment intent
- `POST /payments/confirm` - Confirm payment
- `POST /payments/:id/refund` - Process refund (admin/manager only)
- `GET /payments/:id` - Get payment details
- `POST /payments/webhook` - Stripe webhook handler

#### Menu

- `GET /menu` - List menu items
- `GET /menu/:id` - Get menu item
- `POST /menu` - Create menu item (admin/manager only)
- `PATCH /menu/:id` - Update menu item (admin/manager only)
- `DELETE /menu/:id` - Delete menu item (admin only)

#### Customers

- `POST /customers` - Create customer
- `GET /customers` - List customers (staff only)
- `GET /customers/:id` - Get customer details
- `PATCH /customers/:id` - Update customer
- `POST /customers/:id/loyalty/add` - Add loyalty points (staff only)

#### Analytics

- `GET /analytics/dashboard` - Dashboard overview (admin/manager only)
- `GET /analytics/revenue` - Revenue analytics (admin/manager only)
- `GET /analytics/popular-items` - Popular menu items (admin/manager only)
- `GET /analytics/customers` - Customer analytics (admin/manager only)

## WebSocket Events

Connect to the WebSocket server with authentication:

```javascript
const socket = io('http://localhost:3000', {
  auth: {
    token: 'your_jwt_token'
  }
});
```

### Events to Listen

- `order:new` - New order created (staff room)
- `order:statusChanged` - Order status updated
- `payment:statusChanged` - Payment status updated
- `kitchen:newOrder` - New order for kitchen (kitchen room)
- `kitchen:alert` - Kitchen alerts
- `notification` - User notifications

### Events to Emit

- `subscribe:order` - Subscribe to order updates
- `unsubscribe:order` - Unsubscribe from order
- `order:statusUpdate` - Update order status (staff only)
- `driver:locationUpdate` - Update driver location (driver only)

## Development

### Running Tests

```bash
npm test
```

### Code Linting

```bash
npm run lint
```

### Database Migrations

Create a new migration:

```bash
npm run migrate
```

Rollback last migration:

```bash
npm run migrate:undo
```

## Project Structure

```
backend/
├── src/
│   ├── config/           # Configuration files
│   │   ├── database.js   # Sequelize config
│   │   ├── redis.js      # Redis config
│   │   └── logger.js     # Winston logger
│   ├── middleware/       # Express middleware
│   │   └── auth.js       # JWT authentication
│   ├── models/           # Sequelize models
│   │   ├── User.js
│   │   ├── Customer.js
│   │   ├── MenuItem.js
│   │   ├── Order.js
│   │   ├── Payment.js
│   │   └── index.js
│   ├── routes/           # API routes
│   │   ├── auth.routes.js
│   │   ├── order.routes.js
│   │   ├── payment.routes.js
│   │   ├── menu.routes.js
│   │   ├── customer.routes.js
│   │   └── analytics.routes.js
│   ├── services/         # Business logic
│   │   └── stripe.service.js
│   ├── sockets/          # WebSocket handlers
│   │   └── orderSocket.js
│   ├── utils/            # Utility functions
│   └── server.js         # App entry point
├── logs/                 # Application logs
├── .env.example          # Environment template
├── .gitignore
├── package.json
└── README.md
```

## Deployment

### Environment Variables (Production)

Ensure all environment variables are properly set:

- Set `NODE_ENV=production`
- Use strong JWT secrets
- Use production Stripe keys
- Configure proper CORS origins
- Set up SSL/TLS certificates

### Database Migrations

In production, use migrations instead of auto-sync:

```bash
NODE_ENV=production npm run migrate
```

### Process Management

Use PM2 or similar for process management:

```bash
npm install -g pm2
pm2 start src/server.js --name camerons-backend
pm2 save
```

## Stripe Webhook Setup

1. Install Stripe CLI: https://stripe.com/docs/stripe-cli
2. Forward webhooks to local server:

```bash
stripe listen --forward-to localhost:3000/api/v1/payments/webhook
```

3. Copy the webhook signing secret to `.env`:

```env
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
```

## Troubleshooting

### Database Connection Issues

- Verify PostgreSQL is running: `pg_isready`
- Check credentials in `.env`
- Ensure database exists: `psql -l`

### Redis Connection Issues

- Verify Redis is running: `redis-cli ping`
- Check Redis host and port in `.env`

### WebSocket Connection Issues

- Ensure CORS is properly configured
- Verify JWT token is valid
- Check firewall/proxy settings

## Support

For issues or questions, check the main project README or create an issue on GitHub.

## License

MIT
