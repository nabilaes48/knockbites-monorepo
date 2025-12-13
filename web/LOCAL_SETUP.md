# Cameron's Connect - Local Development Setup

Complete local development environment with real-time synchronization across Web, iOS, and Android.

## 🏗️ Architecture

- **Backend**: PocketBase (open source, Supabase alternative)
- **Database**: SQLite (default) or PostgreSQL (optional)
- **Storage**: MinIO (S3-compatible)
- **Cache**: Redis (optional)
- **Frontend**: React + Vite
- **Real-time**: WebSockets (built into PocketBase)

## 🚀 Quick Start (5 minutes)

### Prerequisites

1. Docker Desktop installed and running
2. Node.js 20+ installed
3. Your iOS/Android development environment set up

### Step 1: Start All Services

```bash
# Copy environment file
cp .env.local.example .env.local

# Start everything with Docker
docker-compose up -d

# Check all services are running
docker-compose ps
```

You should see:
- ✅ PocketBase: http://localhost:8090
- ✅ Frontend: http://localhost:8080
- ✅ PostgreSQL: localhost:5432 (optional)
- ✅ MinIO: http://localhost:9001 (storage UI)
- ✅ Redis: localhost:6379 (optional)

### Step 2: Access Admin UI

Open PocketBase admin: http://localhost:8090/_/

**First-time setup:**
1. Create admin account: `admin@camerons.com` / `changeme123`
2. PocketBase will auto-create collections from your schema

### Step 3: Test Web App

Open: http://localhost:8080

The web app should:
- Connect to PocketBase backend
- Load menu items
- Real-time order updates working

### Step 4: Connect iOS App

**For iOS Simulator:**
```swift
// In your iOS app config
let apiURL = "http://localhost:8090"
```

**For Physical iPhone:**
1. Find your Mac's IP address:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example: inet 192.168.1.145
```

2. Update iOS app:
```swift
let apiURL = "http://192.168.1.145:8090"
```

3. Make sure iPhone is on SAME WiFi network as your Mac

### Step 5: Connect Android App (Future)

**For Android Emulator:**
```kotlin
// Android Emulator uses special IP to reach host
val apiURL = "http://10.0.2.2:8090"
```

**For Physical Android Device:**
```kotlin
// Use your Mac's IP (same as iOS)
val apiURL = "http://192.168.1.145:8090"
```

## 🔄 Real-Time Synchronization

PocketBase provides automatic real-time sync:

### Web App (JavaScript/React)
```javascript
import PocketBase from 'pocketbase'

const pb = new PocketBase('http://localhost:8090')

// Subscribe to orders collection
pb.collection('orders').subscribe('*', (e) => {
  console.log('Real-time update:', e.action, e.record)
  // e.action: 'create', 'update', 'delete'
  // Update UI automatically
})
```

### iOS App (Swift)
```swift
// Using PocketBase Swift SDK
import PocketBase

let pb = PocketBase(baseURL: "http://localhost:8090")

// Subscribe to real-time updates
pb.collection("orders").subscribe { event in
    switch event.action {
    case .create:
        print("New order:", event.record)
    case .update:
        print("Order updated:", event.record)
    case .delete:
        print("Order deleted:", event.record.id)
    }
}
```

### Android App (Kotlin/Flutter)
```kotlin
// Using PocketBase Kotlin SDK
val pb = PocketBase("http://10.0.2.2:8090")

pb.collection("orders").subscribe { event ->
    when (event.action) {
        "create" -> println("New order: ${event.record}")
        "update" -> println("Updated: ${event.record}")
        "delete" -> println("Deleted: ${event.record.id}")
    }
}
```

## 📱 Testing Cross-Platform Sync

1. **Open all three apps:**
   - Web: http://localhost:8080
   - iOS: Simulator or physical device
   - Android: Emulator or physical device (future)

2. **Create an order on web** → Should instantly appear on iOS/Android

3. **Update order status on iOS** → Should instantly update on web/Android

4. **Delete order on Android** → Should instantly remove from web/iOS

**All updates happen in REAL-TIME with WebSockets!**

## 🛠️ Development Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f pocketbase
docker-compose logs -f frontend

# Restart a service
docker-compose restart pocketbase

# Rebuild frontend after code changes
docker-compose up -d --build frontend

# Reset database (WARNING: deletes all data)
docker-compose down -v
rm -rf pb_data
docker-compose up -d
```

## 📂 Project Structure

```
camerons-connect/
├── docker-compose.yml          # All services definition
├── .env.local                  # Local environment variables
├── Dockerfile.dev              # Frontend container
│
├── pb_data/                    # PocketBase data (SQLite)
├── pb_migrations/              # Database migrations
├── pb_hooks/                   # Custom backend logic (JavaScript)
│
├── src/                        # Frontend code
│   ├── lib/
│   │   └── pocketbase.ts       # PocketBase client
│   ├── hooks/
│   │   └── useRealtimeOrders.ts
│   └── ...
│
└── ios/                        # iOS app (separate repo?)
    └── android/                # Android app (future)
```

## 🔐 Authentication

PocketBase handles auth automatically:

```javascript
// Sign up
await pb.collection('users').create({
  email: 'user@example.com',
  password: 'password123',
  passwordConfirm: 'password123',
  name: 'John Doe'
})

// Sign in
await pb.collection('users').authWithPassword(
  'user@example.com',
  'password123'
)

// Get current user
const user = pb.authStore.model

// Sign out
pb.authStore.clear()
```

## 🗄️ Database Schema

PocketBase auto-creates collections from your schema. Example:

### Orders Collection
```javascript
{
  id: "string",
  orderNumber: "string",
  customerName: "string",
  customerEmail: "string",
  customerPhone: "string",
  storeId: "number",
  status: "pending|preparing|ready|completed",
  total: "number",
  items: "json",
  createdAt: "datetime",
  updatedAt: "datetime"
}
```

### Menu Items Collection
```javascript
{
  id: "string",
  name: "string",
  description: "string",
  price: "number",
  category: "string",
  image: "file",
  customizations: "json",
  available: "boolean"
}
```

## 🚀 Deploying to Production

When ready to deploy:

### Option 1: Fly.io ($2-5/month)
```bash
# Install Fly CLI
brew install flyctl

# Login
flyctl auth login

# Deploy PocketBase
flyctl launch

# Deploy frontend (static)
npm run build
flyctl deploy
```

### Option 2: Railway ($5-10/month)
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Deploy
railway up
```

### Option 3: VPS (DigitalOcean, Hetzner - $5/month)
```bash
# SSH to VPS
ssh root@your-vps-ip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Clone repo
git clone <your-repo>
cd camerons-connect

# Copy production env
cp .env.production .env.local

# Start services
docker-compose -f docker-compose.prod.yml up -d
```

## 🔍 Troubleshooting

### iOS can't connect to backend

**Problem:** Connection refused from simulator/device

**Solution:**
1. Check Docker is running: `docker-compose ps`
2. Check Mac firewall allows port 8090
3. For physical device, verify same WiFi network
4. Ping test: `curl http://localhost:8090/api/health`

### Android emulator can't connect

**Problem:** Network timeout on Android emulator

**Solution:**
1. Use `10.0.2.2` instead of `localhost`
2. Check emulator networking: `adb shell ping 10.0.2.2`
3. Restart emulator if needed

### Real-time updates not working

**Problem:** Changes don't sync between apps

**Solution:**
1. Check WebSocket connection in browser DevTools
2. Verify subscription is active: `pb.realtime.subscriptions`
3. Check PocketBase logs: `docker-compose logs pocketbase`

### Database reset needed

**Problem:** Schema changes or corrupted data

**Solution:**
```bash
# Stop services
docker-compose down

# Remove PocketBase data
rm -rf pb_data

# Restart (will recreate)
docker-compose up -d
```

## 📚 Resources

- **PocketBase Docs**: https://pocketbase.io/docs/
- **PocketBase JS SDK**: https://github.com/pocketbase/js-sdk
- **PocketBase Swift SDK**: https://github.com/iamcaleberic/pocketbase-ios-sdk
- **PocketBase Dart SDK**: https://github.com/pocketbase/dart-sdk (for Flutter/Android)

## 🆘 Need Help?

1. Check PocketBase admin UI: http://localhost:8090/_/
2. View service logs: `docker-compose logs -f`
3. Verify all services healthy: `docker-compose ps`
4. Check this file for common solutions

## ✅ Next Steps

1. ✅ Start local environment: `docker-compose up -d`
2. ✅ Connect iOS app to local backend
3. ✅ Test real-time sync between web + iOS
4. ✅ Add Android app when ready
5. ✅ Deploy to production when tested
