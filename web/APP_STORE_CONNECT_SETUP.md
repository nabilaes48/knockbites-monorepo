# 📱 App Store Connect Setup Guide - Cameron's Connect
## Step-by-Step Instructions for TestFlight Submission

---

## ✅ Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Apple Developer Account** - $99/year paid membership
  - Sign up at: https://developer.apple.com/programs/
  - Allow 24-48 hours for account approval

- [ ] **Mac with Xcode 15+** - Latest version installed
  - Download from Mac App Store
  - Must be running macOS 13+ (Ventura) or later

- [ ] **iOS Developer Certificate** - Valid distribution certificate
  - Will be created during this process

- [ ] **Physical iPhone Device** - For testing (not just simulator)
  - iOS 15.0 or later recommended

- [ ] **Privacy Policy Live** - Hosted at accessible URL
  - ✅ Already done: http://localhost:8081/privacy (deploy to get public URL)

---

## 📋 Step 1: Prepare App Assets

### 1.1 App Icon (REQUIRED)

**Specifications:**
- Size: 1024x1024 pixels
- Format: PNG
- No transparency
- No rounded corners (iOS adds them automatically)
- No text mentioning "beta" or "alpha"

**Where to create:**
- Use Figma, Canva, or Photoshop
- Include Cameron's Connect branding
- Simple, recognizable design

**Example design ideas:**
- Cameron's 24-7 logo on colored background
- Food item icon (burger, sandwich) with "C" monogram
- Shopping cart with Cameron's branding

**Save as:** `camerons-connect-icon-1024.png`

---

### 1.2 App Screenshots (REQUIRED for App Store, Optional for TestFlight)

**Required Sizes for iPhone:**
- 6.7" Display (iPhone 14 Pro Max): 1290 x 2796 pixels
- 6.5" Display (iPhone 11 Pro Max): 1242 x 2688 pixels
- 5.5" Display (iPhone 8 Plus): 1242 x 2208 pixels

**How to capture:**
```bash
# Run your iOS app in simulator
# Choose "iPhone 15 Pro Max" for 6.7" screenshots
# Navigate to key screens and press Cmd+S to save

# Key screens to capture:
1. Home/Menu browsing (show 61 menu items)
2. Menu category view (Breakfast, Sandwiches, etc.)
3. Item details with customization
4. Shopping cart with items
5. Checkout form
6. Order tracking with status
```

**Tip:** For TestFlight beta, screenshots are optional. You can submit without them initially.

---

### 1.3 App Description Text

**App Name:** Cameron's Connect

**Subtitle (30 characters):**
"Order food from Cameron's 24-7"

**Description (Full - 4000 character limit):**
```
Cameron's Connect is the official mobile ordering app for Cameron's 24-7 stores across New York. Order your favorite breakfast, sandwiches, burgers, and snacks for quick pickup at your nearest location!

FEATURES:
• Browse our complete menu of 61+ items
• Real-time order tracking
• Guest checkout (no account required)
• 29 locations across New York
• Save favorite items
• Special instructions and customizations
• Order history (with account)
• Push notifications for order updates

MENU CATEGORIES:
- Breakfast (eggs, pancakes, breakfast sandwiches)
- Signature Sandwiches (Philly cheesesteak, chicken cutlet, more)
- Classic Sandwiches (BLT, turkey, ham, club sandwiches)
- Burgers (beef, turkey, veggie burgers with toppings)
- Munchies & Sides (fries, wings, appetizers, desserts)

WHY CAMERON'S CONNECT:
✓ Skip the wait - order ahead and pickup when ready
✓ Real-time updates - know exactly when your order is ready
✓ Easy customization - add extra toppings, sauces, and more
✓ 24/7 locations - many stores open around the clock
✓ Guest checkout - no account required to order

CURRENTLY SERVING:
Highland Mills Snack Shop Inc
634 NY-32, Highland Mills, NY 10930
(845) 928-2883

Coming soon to all 29 Cameron's locations!

ABOUT CAMERON'S 24-7:
Family-owned and operated since [year], Cameron's has been serving fresh, made-to-order food to New York communities. We pride ourselves on quality ingredients, generous portions, and friendly service.

SUPPORT:
Questions? Contact us at jaydeli@outonemail.com
Hours: Monday-Sunday, 24/7
```

**Keywords (100 characters):**
```
food,order,delivery,pickup,restaurant,sandwich,burger,breakfast,deli,snacks
```

---

## 📲 Step 2: Set Up App Store Connect

### 2.1 Log in to App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. Sign in with your Apple ID (same as Developer account)
3. Accept any agreements if prompted

### 2.2 Create New App

1. Click **"My Apps"** in top navigation
2. Click the **"+"** button → **"New App"**
3. Fill out the form:

**Platforms:** ✅ iOS

**Name:** Cameron's Connect Customer App
*(Note: For Business app, use "Cameron's Connect Staff")*

**Primary Language:** English (U.S.)

**Bundle ID:**
- Select from dropdown (you'll create this in Xcode)
- Example: `com.cameronsconnect.customer`

**SKU:**
- Unique identifier for your records
- Example: `camerons-connect-customer-001`

**User Access:**
- ✅ Full Access (recommended)

4. Click **"Create"**

---

### 2.3 Complete App Information

#### **Category**
- **Primary Category:** Food & Drink
- **Secondary Category:** (optional) Shopping

#### **Age Rating**
Click **"Edit"** and answer the questionnaire:
- Cartoon or Fantasy Violence: No
- Realistic Violence: No
- Sexual Content or Nudity: No
- Profanity or Crude Humor: No
- Alcohol, Tobacco, or Drug Use: No (unless you sell these)
- Medical/Treatment Information: No
- Horror/Fear Themes: No
- Mature/Suggestive Themes: No
- Gambling: No
- Unre stricted Web Access: No
- Gambling: No

**Result:** Likely **4+** (appropriate for all ages)

#### **Privacy Policy URL** ⚠️ REQUIRED
```
https://cameronsconnect.com/privacy
```
*(Replace with your actual deployed URL - currently you have it at localhost:8081/privacy)*

**Action needed:** Deploy web app to get public URL, or temporarily use:
```
https://your-vercel-app.vercel.app/privacy
```

#### **Support URL** (REQUIRED)
```
https://cameronsconnect.com/contact
```
Or use:
```
mailto:jaydeli@outonemail.com
```

#### **Marketing URL** (optional)
```
https://cameronsconnect.com
```

---

### 2.4 App Privacy Details

Click **"App Privacy"** → **"Get Started"**

**Data Collection:**

1. **Contact Info**
   - ✅ Name
   - ✅ Phone Number
   - Linked to user? **Yes**
   - Used for tracking? **No**
   - Purposes:
     - ✅ App Functionality
     - ✅ Customer Support

2. **User ID** (if using accounts)
   - ✅ User ID
   - Linked to user? **Yes**
   - Used for tracking? **No**
   - Purposes:
     - ✅ App Functionality

**Data NOT Collected:**
- ❌ Precise Location
- ❌ Browsing History
- ❌ Purchase History (if not storing payment info)
- ❌ Financial Info
- ❌ Sensitive Info

Click **"Publish"** when done

---

## 🔧 Step 3: Configure Xcode Project

### 3.1 Open iOS App in Xcode

```bash
# Customer App
cd ~/Developer/camerons-customer-app
open camerons-customer-app.xcodeproj

# Business App (do separately)
cd ~/Developer/camerons-Bussiness-app
open camerons-Bussiness-app.xcodeproj
```

### 3.2 Configure Signing & Capabilities

1. In Xcode, select your project in the navigator (top blue icon)
2. Select your app target (not the project)
3. Go to **"Signing & Capabilities"** tab

**Team:** Select your Apple Developer team

**Bundle Identifier:**
- Customer App: `com.cameronsconnect.customer`
- Business App: `com.cameronsconnect.staff`

**Signing Certificate:**
- ✅ Automatically manage signing (recommended)
- Xcode will create certificates and provisioning profiles

**Deployment Target:**
- Set to **iOS 15.0** (or your minimum supported version)

### 3.3 Set Version and Build Number

1. Still in Xcode, go to **"General"** tab
2. Under **"Identity"** section:

**Version:** `1.0.0`
**Build:** `1`

*(Increment build number for each TestFlight upload: 1, 2, 3, etc.)*

### 3.4 Add App Icon

1. In Xcode, open **Assets.xcassets**
2. Click on **AppIcon**
3. Drag your 1024x1024 PNG into the "App Store 1024pt" slot
4. Xcode will generate all other sizes automatically

### 3.5 Configure Info.plist

1. Find **Info.plist** in project navigator
2. Add these keys if not present:

**Privacy - Location When In Use Usage Description:**
```
"We use your location to show you the nearest Cameron's Connect stores for pickup."
```

**Privacy - Camera Usage Description** (if using camera for any feature):
```
"Camera access is used to scan QR codes for quick order tracking."
```

**Privacy - Photo Library Usage Description** (if applicable):
```
"Photo library access allows you to share your favorite menu items."
```

---

## 📦 Step 4: Build and Archive for TestFlight

### 4.1 Pre-Build Checklist

- [ ] All code changes committed to git
- [ ] Version and build number set correctly
- [ ] App icon added (1024x1024)
- [ ] Signing configured with Apple Developer team
- [ ] Tested on physical device (not just simulator)
- [ ] No crashes or critical bugs
- [ ] Privacy Policy URL updated with public URL

### 4.2 Create Archive

1. In Xcode, select **"Any iOS Device (arm64)"** as the build destination
   - Do NOT select a simulator
   - If you have a physical device connected, you can select it

2. Go to **Product** menu → **Archive**
   - Build will start (takes 2-5 minutes)
   - If successful, Organizer window will open

3. In **Organizer** window:
   - Your archive will be listed
   - Click **"Distribute App"**

### 4.3 Upload to App Store Connect

1. Select **"App Store Connect"** → **Next**
2. Select **"Upload"** → **Next**
3. Distribution options:
   - ✅ Upload your app's symbols... (for crash reports)
   - ✅ Manage Version and Build Number (Xcode does it automatically)
4. Click **"Next"**
5. Review signing certificate → **"Upload"**

**Upload time:** 5-15 minutes depending on app size

6. When complete, click **"Done"**

---

## 🧪 Step 5: Submit to TestFlight

### 5.1 Wait for Processing

1. Log in to App Store Connect
2. Go to **"My Apps"** → Select your app
3. Click **"TestFlight"** tab

Your build will show up with status:
- **Processing** (15-60 minutes) → Wait for this to complete
- **Waiting for Review** → Your next step
- **Ready to Test** → Available for testers!

### 5.2 Add Beta App Information

While waiting for processing:

1. In **TestFlight** tab, click **"App Store Connect Users"** (internal testing)
2. Under **"Beta App Information"**, fill out:

**Beta App Description:**
```
Cameron's Connect is in beta testing! We're looking for feedback on:
- Menu browsing and search functionality
- Order placement and checkout flow
- Real-time order tracking
- Overall user experience

Please test all features and report any bugs or confusing UI elements.
```

**What to Test:**
```
1. Browse all 5 menu categories
2. Search for menu items
3. Add items to cart with customizations
4. Complete checkout (guest and account)
5. Track order status in real-time
6. Test on different network conditions (WiFi, cellular, poor signal)

Please report:
- Crashes or errors
- Confusing UI/UX
- Feature requests
- Any bugs or unexpected behavior
```

**Feedback Email:**
```
jaydeli@outonemail.com
```

### 5.3 Export Compliance

When prompted:

**Does your app use encryption?**
- Select **"Yes"** (HTTPS counts as encryption)

**Is your app exempt from U.S. encryption export compliance requirements?**
- Select **"Yes"**
- Reason: "Uses standard encryption (HTTPS only)"

**Does your app qualify for any export compliance exemptions?**
- Select **"Yes"**
- Check: **(c) Limited to standard cryptographic protocols**

This is standard for apps using HTTPS only.

### 5.4 Submit for Beta App Review

1. Once processing completes, click **"Submit for Review"**
2. Review your settings
3. Click **"Submit"**

**Review Time:** Typically 24-48 hours for first build

---

## 👥 Step 6: Add Testers

### 6.1 Internal Testing (No Review Required)

1. In TestFlight tab, click **"App Store Connect Users"**
2. Click **"+"** to add testers
3. Add by Apple ID email address
4. Select testers → Click **"Add"**

**Internal testers get:**
- Instant access (no review needed for internal)
- Up to 100 internal testers allowed
- Must be App Store Connect users with role assigned

**To give App Store Connect access:**
1. Go to **"Users and Access"** in main menu
2. Click **"+"** → **"Add People"**
3. Enter email → Select role: **"Customer Support"** (or "App Manager")
4. Click **"Invite"**

### 6.2 External Testing (Requires First Build Review)

1. In TestFlight tab, click **"External Testing"**
2. Click **"Create a Group"** or use default "External Testers"
3. Name the group (e.g., "Pilot Testers")
4. Add testers by email address (anyone, no App Store Connect access needed)
5. Select build to test
6. **Important:** First external build requires App Review (24-48 hours)

**External testers:**
- Up to 10,000 external testers allowed
- First build must pass App Review
- Subsequent builds don't need review (unless major changes)
- Get invitation email with TestFlight link

### 6.3 Tester Instructions

Testers will receive an email with:
1. Link to install TestFlight app (if not already installed)
2. Link to install your beta app
3. Instructions on how to provide feedback

**Remind testers to:**
- Provide feedback via TestFlight's built-in feedback feature
- Screenshot any bugs or issues
- Test on their normal network (not just perfect WiFi)

---

## 📊 Step 7: Monitor Beta Testing

### 7.1 Track Metrics in App Store Connect

Go to **TestFlight** tab → **Builds** → Select your build

**Metrics Available:**
- **Installs** - How many testers installed
- **Sessions** - How often they use the app
- **Crashes** - Critical bugs to fix
- **Feedback** - Direct tester comments

### 7.2 Review Feedback

1. In TestFlight tab, click **"Feedback"**
2. Review all tester comments
3. Screenshot any bugs reported
4. Prioritize fixes:
   - **Critical:** Crashes, data loss, security issues
   - **High:** Broken features, confusing UX
   - **Medium:** Minor bugs, UI polish
   - **Low:** Nice-to-have improvements

### 7.3 Upload New Builds

When you fix bugs:

1. Increment **Build Number** in Xcode (e.g., 1 → 2)
2. Keep **Version** the same (1.0.0) for beta
3. Archive and upload again (same process as Step 4)
4. Testers automatically get update notification

**No review needed** for subsequent builds to same testers!

---

## ⚠️ Common Issues & Solutions

### Issue: "No signing identity found"

**Solution:**
1. Open Xcode preferences → **Accounts**
2. Select your Apple ID
3. Click **"Manage Certificates"**
4. Click **"+"** → **"Apple Distribution"**
5. Close and try archiving again

### Issue: "Failed to upload"

**Solution:**
1. Check internet connection
2. Verify Apple Developer account is active ($99 paid)
3. Try **Product** → **Clean Build Folder** (Cmd+Shift+K)
4. Archive again

### Issue: "Build is processing for too long"

**Solution:**
- This is normal for first build (can take up to 60 minutes)
- If stuck for 2+ hours, contact Apple Developer Support

### Issue: "Export compliance questions unclear"

**Solution:**
- If using HTTPS only: Select "Yes" to encryption, then select "exempt"
- If in doubt: Select "No" and Apple will guide you

### Issue: "Privacy Policy URL returns 404"

**Solution:**
- Must deploy web app to get public URL
- Temporary fix: Use `vercel.app` URL from Vercel deployment
- Update App Store Connect with correct URL

---

## ✅ Success Checklist

By the end of this process, you should have:

- [ ] App Store Connect app created
- [ ] Privacy policy live at public URL
- [ ] App icon uploaded (1024x1024)
- [ ] Xcode project configured with signing
- [ ] Build archived and uploaded
- [ ] TestFlight submission complete
- [ ] Beta app information filled out
- [ ] Export compliance declared
- [ ] Internal testers invited (5-10 people)
- [ ] External tester group created
- [ ] Build approved and ready to test
- [ ] Feedback monitoring process in place

---

## 📚 Helpful Resources

### Apple Documentation
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [TestFlight Overview](https://developer.apple.com/testflight/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Xcode Help
- [Distributing Your App](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Configuring Your Xcode Project](https://developer.apple.com/documentation/xcode/configuring-a-new-project)

### Cameron's Connect Specific
- **Privacy Policy:** http://localhost:8081/privacy (deploy for public URL)
- **Support Email:** jaydeli@outonemail.com
- **Phone:** (845) 928-2883
- **Address:** 634 NY-32, Highland Mills, NY 10930

---

## 🚀 Next Steps After TestFlight

Once beta testing is complete and stable:

1. **Prepare for App Store submission:**
   - Create final screenshots (all required sizes)
   - Write marketing description
   - Record optional app preview video
   - Set pricing (free)

2. **Submit for App Store Review:**
   - Review takes 1-7 days (average 1-2 days)
   - May receive requests for clarification
   - Make any required changes

3. **Launch! 🎉**
   - Set release date or release immediately
   - Monitor reviews and ratings
   - Respond to user feedback
   - Plan update releases

---

## 📧 Support

**Questions about this process?**
Email: jaydeli@outonemail.com

**Apple Developer Support:**
https://developer.apple.com/contact/

**Need help with your iOS apps?**
- Customer App Location: `~/Developer/camerons-customer-app/`
- Business App Location: `~/Developer/camerons-Bussiness-app/`

---

**Document Version:** 1.0
**Created:** November 24, 2024
**Last Updated:** November 24, 2024

**Good luck with your TestFlight launch! 🚀**
