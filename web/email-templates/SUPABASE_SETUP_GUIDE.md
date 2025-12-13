# Quick Supabase Email Template Setup Guide

Follow these steps to replace the default Supabase authentication emails with KnockBites branded templates.

## ⚡ Quick Setup (15 minutes)

### Step 1: Access Email Templates

1. Go to https://app.supabase.com
2. Select your project
3. Click **Authentication** (shield icon) in the left sidebar
4. Click **Email Templates**

### Step 2: Update Confirm Signup Template

1. Click on **"Confirm signup"** in the list
2. **Subject line**: Replace with:
   ```
   Welcome to KnockBites - Confirm Your Email
   ```
3. **Message body**:
   - Open `signup-confirmation.html` from this directory
   - Copy the entire HTML content
   - Paste it into the Supabase message body field
   - Verify that `{{ .ConfirmationURL }}` and `{{ .SiteURL }}` are present
4. Click **Save** at the bottom

### Step 3: Update Magic Link Template

1. Click on **"Magic Link"**
2. **Subject line**:
   ```
   Sign In to KnockBites
   ```
3. **Message body**:
   - Open `magic-link.html`
   - Copy and paste the entire content
   - Verify Supabase variables are intact
4. Click **Save**

### Step 4: Update Change Email Template

1. Click on **"Change Email Address"**
2. **Subject line**:
   ```
   Confirm Your Email Change - KnockBites
   ```
3. **Message body**:
   - Open `email-change.html`
   - Copy and paste the entire content
   - Verify Supabase variables are intact
4. Click **Save**

### Step 5: Update Reset Password Template

1. Click on **"Reset Password"**
2. **Subject line**:
   ```
   Reset Your KnockBites Password
   ```
3. **Message body**:
   - Open `password-reset.html`
   - Copy and paste the entire content
   - Verify Supabase variables are intact
4. Click **Save**

### Step 6: Test Your Templates

1. Stay in **Authentication** → **Email Templates**
2. For each template you updated:
   - Click the template name
   - Scroll to bottom and find "Send test email"
   - Enter your email address
   - Click **Send test email**
   - Check your inbox (and spam folder)

3. Verify in each test email:
   - ✅ KnockBites branding appears
   - ✅ Blue-to-orange gradient header displays
   - ✅ Links work correctly
   - ✅ Layout looks good on mobile
   - ✅ All text is readable

## 🎨 Optional: Customize Sender Info

### Update Email Sender Details

1. Go to **Settings** → **Project Settings**
2. Scroll to **Email** section
3. Update:
   - **Sender name**: `KnockBites`
   - **Sender email**: Keep as default (or configure custom SMTP)

### Configure Custom SMTP (Optional, Advanced)

If you want to use your own email server:

1. Go to **Settings** → **Project Settings** → **SMTP Settings**
2. Enable **Enable Custom SMTP**
3. Fill in your SMTP provider details:
   - **Host**: e.g., `smtp.sendgrid.net`
   - **Port**: Usually `587` or `465`
   - **Username**: Your SMTP username
   - **Password**: Your SMTP password
   - **Sender email**: `noreply@knockbites.com`
   - **Sender name**: `KnockBites`
4. Click **Save**
5. Send a test email to verify

## ✅ Verification Checklist

After setup, verify:

- [ ] All 4 authentication email templates updated
- [ ] Subject lines use KnockBites branding
- [ ] Test emails sent and received successfully
- [ ] Links in test emails work correctly
- [ ] Branding looks consistent across all templates
- [ ] Mobile rendering is acceptable
- [ ] Sender name shows "KnockBites" (or configured name)

## 🔍 What Each Template Does

| Template | When It's Sent | User Action |
|----------|----------------|-------------|
| **Confirm signup** | User creates new account | Click link to verify email |
| **Magic Link** | User requests passwordless sign-in | Click link to sign in |
| **Change Email** | User changes email address | Click link to confirm new email |
| **Reset Password** | User clicks "Forgot Password" | Click link to reset password |

## 📱 Testing Scenarios

Test these user flows to ensure everything works:

### Test 1: New User Signup
1. Go to your signup page
2. Create a test account with a real email you can access
3. Check email inbox for confirmation email
4. Verify branding and click confirmation link
5. Ensure you're redirected correctly

### Test 2: Password Reset
1. Go to sign-in page
2. Click "Forgot Password"
3. Enter email and submit
4. Check email for reset link
5. Verify branding and click reset link
6. Ensure password reset flow works

### Test 3: Magic Link Sign-In (if enabled)
1. Use magic link sign-in option
2. Enter email and submit
3. Check email for magic link
4. Verify branding and click link
5. Ensure you're signed in successfully

## 🚨 Troubleshooting

### Template Not Saving
- **Issue**: Changes aren't being saved
- **Solution**: Make sure you scroll down and click the **Save** button at the bottom of each template

### Email Not Received
- **Issue**: Test email doesn't arrive
- **Solution**:
  1. Check spam/junk folder
  2. Wait 5-10 minutes (delivery can be slow)
  3. Check Supabase rate limits (free tier has limits)
  4. Verify email address is correct

### Links Don't Work
- **Issue**: Confirmation links lead to errors
- **Solution**:
  1. Check that `{{ .ConfirmationURL }}` is in the template
  2. Verify Site URL in Settings → Authentication → Site URL
  3. Check redirect URLs in Authentication settings

### Styling Looks Wrong
- **Issue**: Email doesn't look like the template
- **Solution**:
  1. Some email clients strip styles - this is normal
  2. Core branding (colors, layout) should still work
  3. Test in multiple email clients (Gmail, Outlook, Apple Mail)

### Template Variables Not Working
- **Issue**: `{{ .ConfirmationURL }}` shows as text
- **Solution**:
  1. Make sure you copied the ENTIRE HTML template
  2. Don't modify Supabase variable syntax
  3. Variables only work in live emails, not in preview

## 📊 Monitoring Email Delivery

After setup, monitor email performance:

1. **Supabase Dashboard** → **Authentication** → **Users**
   - See which users have confirmed emails
   - Check last sign-in times

2. **Logs** → **All logs**
   - Filter by "auth" to see authentication events
   - Look for email-related errors

3. **Email Provider Dashboard** (if using custom SMTP)
   - Check delivery rates
   - Monitor bounce rates
   - Review spam complaints

## 🔐 Security Checklist

Ensure security best practices:

- [ ] All email links use HTTPS
- [ ] Confirmation links expire (Supabase default: 24 hours)
- [ ] Security notices included in password/email change emails
- [ ] No sensitive data exposed in email templates
- [ ] Sender email is verified (if using custom domain)

## 🎯 Next Steps

After setting up authentication emails:

1. **Test thoroughly** with real user flows
2. **Set up promotional emails** using `coupon-promo.html` template
3. **Configure email analytics** to track open/click rates
4. **Create order confirmation emails** (future enhancement)
5. **Set up automated coupon campaigns** for customer retention

## 📚 Additional Resources

- [Supabase Email Templates Documentation](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Email Client CSS Support](https://www.campaignmonitor.com/css/)
- [CAN-SPAM Compliance](https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business)

---

**Setup Time**: ~15 minutes
**Difficulty**: Easy
**Requires**: Supabase project admin access

Need help? Check the main `README.md` in this directory for detailed information.
