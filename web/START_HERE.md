# 🚀 START HERE - Cameron's Connect Local Development

## Step 1: Install PocketBase SDK (2 minutes)

```bash
# Install PocketBase JavaScript SDK
npm install pocketbase

# Install types for TypeScript
npm install --save-dev @types/pocketbase
```

## Step 2: Start Local Environment (3 minutes)

```bash
# Copy environment variables
cp .env.local.example .env.local

# Start all services with Docker
docker-compose up -d

# Wait for services to start (about 30 seconds)
# Then check status:
docker-compose ps
```

**You should see:**
✅ camerons-pocketbase (healthy)
✅ camerons-frontend (healthy)
✅ camerons-postgres (healthy) - optional
✅ camerons-storage (healthy) - MinIO
✅ camerons-redis (healthy) - optional

## Step 3: Access Services (1 minute)

Open in your browser:

1. **PocketBase Admin**: http://localhost:8090/_/
   - Create admin account: `admin@camerons.com` / `changeme123`
   - This is where you manage data, collections, users

2. **Frontend**: http://localhost:8080
   - Your React app should load
   - Connected to PocketBase backend

3. **MinIO Storage UI**: http://localhost:9001
   - Login: `minioadmin` / `minioadmin`
   - This is where menu images are stored (S3-compatible)

## Step 4: Test Real-Time Sync (5 minutes)

### Test on Web:

1. Open: http://localhost:8080
2. Open browser console (F12)
3. Place a test order
4. Watch console for real-time updates

### Test on iOS Simulator:

1. **Find your Mac's IP address:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# Example output: inet 192.168.1.145
```

2. **Update your iOS app configuration:**
```swift
// In your iOS app's config file
#if DEBUG
let apiURL = "http://localhost:8090"  // For simulator
// let apiURL = "http://192.168.1.145:8090"  // For physical device
#else
let apiURL = "https://api.cameronsconnect.com"  // Production
#endif
```

3. **Run iOS app** and test creating orders

4. **Watch BOTH apps** - Changes should sync instantly!

### Test Real-Time Sync:

1. Open web app in browser
2. Open iOS app in simulator
3. Create order on web → Should appear on iOS immediately
4. Update order on iOS → Should update on web immediately

**This is real-time WebSocket synchronization in action!**

## Step 5: Connect iOS App to PocketBase (10 minutes)

### Install PocketBase Swift SDK:

Add to your iOS app's `Package.swift` or use Swift Package Manager in Xcode:

```
https://github.com/iamcaleberic/pocketbase-ios-sdk
```

### Update iOS Code:

```swift
import PocketBase

// Initialize client
let pb = PocketBase(baseURL: "http://localhost:8090")

// Subscribe to orders (real-time)
pb.collection("orders").subscribe { event in
    DispatchQueue.main.async {
        switch event.action {
        case "create":
            print("New order received:", event.record)
            // Update UI with new order
        case "update":
            print("Order updated:", event.record)
            // Update existing order in UI
        case "delete":
            print("Order deleted:", event.record.id)
            // Remove order from UI
        default:
            break
        }
    }
}

// Create new order
let orderData: [String: Any] = [
    "customerName": "John Doe",
    "customerEmail": "john@example.com",
    "customerPhone": "555-0100",
    "storeId": 1,
    "status": "pending",
    "total": 29.99,
    "items": itemsJSON
]

pb.collection("orders").create(body: orderData) { result in
    switch result {
    case .success(let record):
        print("Order created:", record)
    case .failure(let error):
        print("Error:", error)
    }
}
```

## Step 6: Verify Everything Works

### Checklist:

- [ ] Docker services running (`docker-compose ps` shows all healthy)
- [ ] PocketBase admin accessible (http://localhost:8090/_/)
- [ ] Web app loads (http://localhost:8080)
- [ ] iOS simulator connects to backend
- [ ] Create order on web → appears on iOS
- [ ] Create order on iOS → appears on web
- [ ] Real-time sync works both directions

## 🎯 What You've Accomplished

✅ **Local Development Environment**
- Complete backend running locally
- No cloud dependencies
- No monthly costs during development

✅ **Cross-Platform Sync**
- Web ↔ iOS real-time synchronization
- Ready for Android when you need it
- All using open source (PocketBase)

✅ **Production-Ready Architecture**
- Same code works locally and in production
- Deploy to Fly.io ($2/mo), Railway ($5/mo), or VPS ($5/mo)
- No vendor lock-in (MIT license, can't be revoked)

## 🚀 Next Steps

### Option 1: Keep Developing Locally
```bash
# Just keep using Docker
docker-compose up -d

# Develop web app
npm run dev

# Develop iOS app
open ios/CameronsConnect.xcodeproj

# Everything syncs automatically!
```

### Option 2: Deploy to Production
```bash
# When ready to deploy:

# Option A: Fly.io ($2/month)
flyctl launch
flyctl deploy

# Option B: Railway ($5/month)
railway up

# Option C: Your own VPS ($5/month)
scp docker-compose.yml root@your-vps:/app
ssh root@your-vps "cd /app && docker-compose up -d"
```

## 🆘 Troubleshooting

### Services won't start
```bash
# Check Docker is running
docker info

# Reset everything
docker-compose down -v
docker-compose up -d
```

### iOS can't connect
```bash
# Make sure firewall allows port 8090
sudo lsof -i :8090

# Test from iOS simulator
curl http://localhost:8090/api/health

# For physical device, use Mac's IP
curl http://192.168.1.XXX:8090/api/health
```

### Real-time not working
```bash
# Check WebSocket connection
# In browser console:
# - Open DevTools → Network tab
# - Filter by "WS" (WebSocket)
# - Should see connection to localhost:8090

# Check PocketBase logs
docker-compose logs -f pocketbase
```

## 📚 Documentation

- **Full Setup Guide**: See `LOCAL_SETUP.md`
- **PocketBase Docs**: https://pocketbase.io/docs/
- **Deployment Guide**: See `DEPLOYMENT.md` (I can create this)
- **Migration from Supabase**: See `MIGRATION.md` (I can create this)

## ✅ You're Ready!

You now have:
- ✅ Complete local development environment
- ✅ Web + iOS + Android (future) sync
- ✅ Open source backend (no lock-in)
- ✅ $0/month during development
- ✅ $2-10/month when deployed
- ✅ Real-time synchronization
- ✅ Production-ready architecture

**Start developing!** Everything you build locally will work in production.
