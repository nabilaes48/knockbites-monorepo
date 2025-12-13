#!/bin/bash

# Cameron's Connect - Quick Start Script
# This script sets up your complete local development environment

set -e  # Exit on error

echo "🚀 Cameron's Connect - Local Development Setup"
echo "================================================"
echo ""

# Step 1: Check prerequisites
echo "📋 Step 1: Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop first:"
    echo "   https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 20+ first:"
    echo "   https://nodejs.org/"
    exit 1
fi

echo "✅ Docker found: $(docker --version)"
echo "✅ Node.js found: $(node --version)"
echo ""

# Step 2: Install dependencies
echo "📦 Step 2: Installing PocketBase SDK..."
npm install pocketbase
echo "✅ PocketBase SDK installed"
echo ""

# Step 3: Setup environment
echo "⚙️  Step 3: Setting up environment..."
if [ ! -f .env.local ]; then
    cp .env.local.example .env.local
    echo "✅ Created .env.local from example"
else
    echo "✅ .env.local already exists"
fi
echo ""

# Step 4: Start Docker services
echo "🐳 Step 4: Starting Docker services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start (30 seconds)..."
sleep 30

# Step 5: Check service health
echo ""
echo "🔍 Step 5: Checking service health..."
docker-compose ps

echo ""
echo "✅ Setup complete!"
echo ""
echo "================================================"
echo "📱 Your services are running:"
echo "================================================"
echo ""
echo "🎯 PocketBase Backend:  http://localhost:8090"
echo "   Admin UI:            http://localhost:8090/_/"
echo "   API Docs:            http://localhost:8090/api/docs"
echo ""
echo "🌐 Frontend Web App:    http://localhost:8080"
echo ""
echo "💾 MinIO Storage UI:    http://localhost:9001"
echo "   Username: minioadmin"
echo "   Password: minioadmin"
echo ""
echo "🗄️  PostgreSQL:         localhost:5432"
echo "   Database: camerons_connect"
echo "   Username: postgres"
echo "   Password: dev_password"
echo ""
echo "================================================"
echo "📱 iOS App Configuration:"
echo "================================================"
echo ""
echo "For iOS Simulator, use:"
echo "  let apiURL = \"http://localhost:8090\""
echo ""
echo "For Physical iPhone, find your Mac's IP:"
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
if [ -n "$MAC_IP" ]; then
    echo "  Your Mac's IP: $MAC_IP"
    echo "  let apiURL = \"http://$MAC_IP:8090\""
else
    echo "  Run: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
    echo "  Then use: let apiURL = \"http://YOUR_MAC_IP:8090\""
fi
echo ""
echo "================================================"
echo "🎉 Next Steps:"
echo "================================================"
echo ""
echo "1. Open PocketBase Admin:  http://localhost:8090/_/"
echo "   - Create admin account (first time only)"
echo ""
echo "2. Open Web App:  http://localhost:8080"
echo "   - Test that it loads and connects to backend"
echo ""
echo "3. Configure your iOS app with the API URL above"
echo ""
echo "4. Test real-time sync between web and iOS!"
echo ""
echo "================================================"
echo "📚 Documentation:"
echo "================================================"
echo ""
echo "- Quick Start:      START_HERE.md"
echo "- Full Guide:       LOCAL_SETUP.md"
echo "- View logs:        docker-compose logs -f"
echo "- Stop services:    docker-compose down"
echo ""
echo "Happy coding! 🚀"
