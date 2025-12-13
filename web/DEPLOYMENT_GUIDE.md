# Cameron's Connect - Pilot Deployment Guide

This guide covers deploying all three apps for pilot testing.

## Pre-Deployment Checklist

✅ **Supabase** - Already configured at `jwcuebbhkwwilqfblecq.supabase.co`
✅ **Web App** - React app ready with Render config
✅ **iOS Customer App** - Located at `~/Developer/camerons-customer-app/`
✅ **iOS Business App** - Located at `~/Developer/camerons-Bussiness-app/`

All apps share the same Supabase backend.

---

## 1. Deploy Web App to Render

### Option A: One-Click Deploy (Recommended)

1. Go to [render.com](https://render.com) and sign in
2. Click **New** → **Web Service**
3. Connect your GitHub repo: `camerons-connect`
4. Render will auto-detect the `render.yaml` blueprint

### Option B: Manual Setup

1. **Create New Web Service** on Render
2. **Settings**:
   - Name: `camerons-connect`
   - Runtime: `Docker`
   - Branch: `main`
   - Dockerfile Path: `./Dockerfile`

3. **Environment Variables** (add in Render dashboard):
   ```
   VITE_SUPABASE_URL=https://jwcuebbhkwwilqfblecq.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3Y3VlYmJoa3d3aWxxZmJsZWNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MzYxODksImV4cCI6MjA3OTAxMjE4OX0.z03hYyyIIyfdj42Le4XeJFSK2vnd4cHvsaLA03CNM7I
   ```

4. Click **Create Web Service**

### Expected URL
Your app will be live at: `https://camerons-connect.onrender.com` (or similar)

---

## 2. Deploy iOS Customer App to TestFlight

### Prerequisites
- Apple Developer Account ($99/year) - [developer.apple.com](https://developer.apple.com)
- Xcode installed with signing certificates

### Steps

1. **Open in Xcode**
   ```bash
   open ~/Developer/camerons-customer-app/camerons-customer-app.xcodeproj
   ```

2. **Configure Signing**
   - Select project in navigator
   - Go to **Signing & Capabilities**
   - Team: Select your Apple Developer team
   - Bundle ID: `com.cameronsconnect.customer` (or your preferred ID)

3. **Update Version for Pilot**
   - Version: `1.0.0`
   - Build: `1`

4. **Archive for Distribution**
   - Select **Any iOS Device** as build target
   - Menu: **Product** → **Archive**
   - Wait for build to complete

5. **Upload to App Store Connect**
   - In Organizer window, select the archive
   - Click **Distribute App**
   - Choose **App Store Connect** → **Upload**
   - Follow prompts

6. **Setup in App Store Connect**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Create new app if needed
   - App Information:
     - Name: `Cameron's Connect`
     - Primary Language: English
     - Bundle ID: Select your bundle ID
     - SKU: `camerons-customer-001`

7. **TestFlight Setup**
   - Go to **TestFlight** tab
   - Wait for build processing (5-30 min)
   - Add internal testers (your team)
   - Add external testers (pilot customers)

### App Store Metadata (for later full release)
- Category: Food & Drink
- Age Rating: 4+
- Privacy Policy URL: `https://camerons-connect.onrender.com/privacy-policy`

---

## 3. Deploy iOS Business App to TestFlight

Same process as Customer App:

1. **Open in Xcode**
   ```bash
   open ~/Developer/camerons-Bussiness-app/camerons-Bussiness-app.xcodeproj
   ```

2. **Configure Signing**
   - Bundle ID: `com.cameronsconnect.business` (or your preferred ID)

3. **Archive and Upload** (same steps as above)

4. **App Store Connect**
   - Create separate app entry
   - Name: `Cameron's Connect Business`
   - SKU: `camerons-business-001`

---

## Test Accounts

For pilot testing, use these pre-configured accounts:

| Role | Email | Password |
|------|-------|----------|
| Super Admin | admin@jaydeli.com | admin123 |
| Manager | manager@jaydeli.com | manager123 |
| Staff | staff@jaydeli.com | staff123 |

**Customer accounts**: Sign up via the app (automatic customer profile creation)

---

## Verification Checklist

After deployment, verify:

### Web App
- [ ] Homepage loads
- [ ] Menu displays with images
- [ ] Can add items to cart
- [ ] Guest checkout works
- [ ] Order appears in dashboard

### iOS Customer App
- [ ] App launches
- [ ] Menu loads from Supabase
- [ ] Images display correctly
- [ ] Can place an order

### iOS Business App
- [ ] App launches
- [ ] Login with staff credentials
- [ ] Orders appear in real-time
- [ ] Can accept/reject orders

---

## Troubleshooting

### Web App on Render
- Check build logs in Render dashboard
- Verify environment variables are set
- Ensure Docker build succeeds

### iOS TestFlight
- "Missing Compliance" - Go to App Store Connect → TestFlight → Answer encryption questions
- Build stuck processing - Wait up to 30 min, or re-upload

### Supabase Connection Issues
- Verify anon key matches across all apps
- Check RLS policies allow anonymous access for menu/orders
- Test with: `curl https://jwcuebbhkwwilqfblecq.supabase.co/rest/v1/menu_items?limit=1 -H "apikey: YOUR_KEY"`

---

## Next Steps After Pilot

1. **Custom Domain** - Point your domain to Render
2. **App Store Release** - Submit for full review after pilot feedback
3. **Payment Integration** - Add Stripe for online payments
4. **Push Notifications** - For order status updates
