# KnockBites Email Templates

This directory contains branded email templates for KnockBites. All templates feature the brand's signature blue-to-orange gradient, professional styling, and consistent messaging.

## 📧 Available Templates

### Authentication Emails (Supabase)

1. **signup-confirmation.html** - Sent when a new user signs up
2. **password-reset.html** - Sent when a user requests a password reset
3. **magic-link.html** - Sent for passwordless sign-in
4. **email-change.html** - Sent when a user changes their email address

### Marketing Emails

5. **coupon-promo.html** - Template for promotional campaigns and coupon distribution

### Base Template

6. **base-template.html** - Reusable base template with placeholders for custom emails

## 🎨 Brand Identity

All templates use KnockBites's brand colors:

- **Primary Orange**: #FF8C42 (Energy, Friendly)
- **Secondary Pink**: #E84393 (Vibrant, Fun)
- **Accent Green**: #4CAF50 (Fresh, Success)
- **Gradient**: Orange → Pink (Hero sections)

## 🚀 Setup Instructions

### Step 1: Access Supabase Dashboard

1. Go to your Supabase project: https://app.supabase.com
2. Select your KnockBites project
3. Navigate to **Authentication** → **Email Templates** in the left sidebar

### Step 2: Configure Each Email Template

Supabase provides templates for:
- Confirm signup
- Invite user
- Magic Link
- Change Email Address
- Reset Password

For each template:

1. Click on the template name (e.g., "Confirm signup")
2. Replace the default HTML with the corresponding template from this directory
3. Make sure to keep Supabase variables intact:
   - `{{ .ConfirmationURL }}` - The confirmation/action link
   - `{{ .SiteURL }}` - Your site URL
   - `{{ .Token }}` - The verification token (if needed)
   - `{{ .TokenHash }}` - Hashed token (if needed)
4. Update the **Subject line** to match KnockBites brand voice
5. Click **Save**

### Step 3: Template Mapping

Use these files for each Supabase email template:

| Supabase Template | File to Use | Suggested Subject Line |
|------------------|-------------|------------------------|
| Confirm signup | `signup-confirmation.html` | "Welcome to KnockBites - Confirm Your Email" |
| Magic Link | `magic-link.html` | "Sign In to KnockBites" |
| Change Email Address | `email-change.html` | "Confirm Your Email Change - KnockBites" |
| Reset Password | `password-reset.html` | "Reset Your KnockBites Password" |

### Step 4: Test Your Templates

1. In Supabase Dashboard, go to **Authentication** → **Email Templates**
2. Use the "Send test email" feature for each template
3. Check that:
   - ✅ Links work correctly
   - ✅ Colors display properly
   - ✅ Branding looks consistent
   - ✅ Responsive design works on mobile

### Step 5: Configure SMTP Settings (Optional)

For custom email sending (if not using Supabase's default email service):

1. Go to **Settings** → **Project Settings** → **SMTP Settings**
2. Configure your SMTP provider (SendGrid, Postmark, etc.)
3. Update sender email to: `noreply@knockbites.com`
4. Update sender name to: `KnockBites`

## 📝 Customizing Templates

### Supabase Variables

These variables are automatically populated by Supabase:

```html
{{ .ConfirmationURL }}  <!-- Action link (confirm, reset, etc.) -->
{{ .SiteURL }}          <!-- Your site URL from Supabase config -->
{{ .Token }}            <!-- Verification token -->
{{ .TokenHash }}        <!-- Hashed token -->
```

**IMPORTANT**: Never remove or modify these variables - Supabase requires them for authentication to work.

### Custom Variables (For Coupon Template)

For the promotional email template (`coupon-promo.html`), replace these placeholders when sending:

```html
{{PROMO_TITLE}}         <!-- e.g., "Get 20% Off Your Next Order!" -->
{{PROMO_DESCRIPTION}}   <!-- Brief description of the offer -->
{{COUPON_CODE}}         <!-- e.g., "FRESH20" -->
{{EXPIRATION_DATE}}     <!-- e.g., "December 31, 2025" -->
{{OFFER_DETAILS}}       <!-- Full details of the promotion -->
{{ORDER_LINK}}          <!-- Link to ordering page -->
{{WEBSITE_URL}}         <!-- Your website URL -->
{{MENU_URL}}            <!-- Link to menu page -->
{{LOCATIONS_URL}}       <!-- Link to locations page -->
{{ADDITIONAL_TERMS}}    <!-- Any extra terms or conditions -->
{{UNSUBSCRIBE_URL}}     <!-- Unsubscribe link -->
```

### Modifying Design

All styles are inline (required for email clients). To modify:

1. **Colors**: Search for color hex codes and replace:
   - `#FF8C42` - Primary orange
   - `#E84393` - Secondary pink
   - `#4CAF50` - Accent green

2. **Gradient**: Modify the `background` style:
   ```css
   background: linear-gradient(135deg, #FF8C42 0%, #E84393 100%);
   ```

3. **Logo**: To add an image logo:
   ```html
   <img src="https://your-cdn.com/logo.png" alt="KnockBites" style="height: 60px; margin-bottom: 16px;">
   ```

## 📱 Testing Checklist

Before going live, test each template:

- [ ] Desktop email clients (Gmail, Outlook, Apple Mail)
- [ ] Mobile email apps (iOS Mail, Gmail app, Outlook mobile)
- [ ] Dark mode rendering
- [ ] All links are functional
- [ ] Unsubscribe links work (for promotional emails)
- [ ] Images load correctly (if any)
- [ ] Text is readable with email client overrides

## 🔒 Security Best Practices

1. **Never** include sensitive information in email templates
2. **Always** use HTTPS links
3. **Set** email links to expire (Supabase does this automatically)
4. **Include** security notices for password/email changes
5. **Test** that confirmation URLs work only once

## 🎯 Using the Coupon Template

For sending promotional emails:

1. Use a service like SendGrid, Mailchimp, or Customer.io
2. Copy `coupon-promo.html` to your email service
3. Replace all `{{VARIABLE}}` placeholders with actual values
4. Set up proper unsubscribe handling
5. Comply with CAN-SPAM and GDPR regulations

Example with SendGrid dynamic templates:
```javascript
// SendGrid API call
const msg = {
  to: 'customer@example.com',
  from: 'noreply@knockbites.com',
  templateId: 'd-xxxxxxxxxxxxx',
  dynamicTemplateData: {
    PROMO_TITLE: 'Get 20% Off Your Next Order!',
    COUPON_CODE: 'FRESH20',
    EXPIRATION_DATE: 'December 31, 2025',
    // ... other variables
  },
};
```

## 📊 Email Analytics

Track email performance:

1. **Supabase Auth Emails**: Monitor in Authentication → Users
2. **Promotional Emails**: Use your email service provider's analytics
3. **Key Metrics**:
   - Open rate
   - Click-through rate (CTR)
   - Conversion rate
   - Unsubscribe rate

## 🆘 Troubleshooting

### Emails Not Sending

1. Check Supabase email rate limits
2. Verify SMTP configuration (if using custom SMTP)
3. Check spam folders
4. Review Supabase logs in Dashboard → Logs

### Links Not Working

1. Ensure `{{ .ConfirmationURL }}` is present
2. Check redirect URL configuration in Supabase settings
3. Verify your site URL is correctly set

### Styling Issues

1. Test in multiple email clients (they render differently)
2. Use inline styles (never `<style>` tags in `<head>`)
3. Avoid flexbox and grid (poor email support)
4. Use tables for layout (email standard)

## 📞 Support

For issues with:
- **Template design**: Review this README and test in different clients
- **Supabase configuration**: Check Supabase documentation or support
- **Email delivery**: Contact your email service provider

## 🚀 Future Enhancements

Consider adding:
- Welcome email series for new customers
- Order confirmation emails
- Order status update emails
- Loyalty program emails
- Birthday/anniversary offers
- Weekly specials newsletter

---

**Last Updated**: January 2025
**Brand**: KnockBites
**Project**: KnockBites Platform
