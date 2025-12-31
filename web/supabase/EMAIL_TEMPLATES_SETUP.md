# KnockBites Email Templates Setup

## Step 1: Upload Logo Assets to Supabase Storage

1. Go to Supabase Dashboard → Storage
2. Create a new public bucket called `email-assets`
3. Upload the following files from `web/supabase/email-assets/`:
   - `customer-logo.png` - Customer-facing emails
   - `business-logo.png` - Staff/Business emails

After uploading, your logo URLs will be:
- Customer: `https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/customer-logo.png`
- Business: `https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/business-logo.png`

## Step 2: Update Email Templates in Supabase

Go to Supabase Dashboard → Authentication → Email Templates

### Confirm Signup (Customer)
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/customer-logo.png" alt="KnockBites" style="width: 80px; height: 80px; border-radius: 16px;">
    <h1 style="color: #1a1a1a; margin-top: 16px; font-size: 24px;">Welcome to KnockBites!</h1>
  </div>

  <div style="background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); padding: 30px; border-radius: 16px; text-align: center;">
    <p style="color: #1a1a1a; font-size: 16px; margin-bottom: 20px;">
      Thanks for signing up! Please confirm your email address to get started.
    </p>
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: #1a1a1a; color: #fff; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
      Confirm Email
    </a>
  </div>

  <p style="color: #666; font-size: 14px; text-align: center; margin-top: 30px;">
    If you didn't create this account, you can safely ignore this email.
  </p>

  <div style="border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; text-align: center;">
    <p style="color: #999; font-size: 12px;">
      KnockBites - Fresh Food, Fast Delivery
    </p>
  </div>
</div>
```

### Magic Link (Customer)
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/customer-logo.png" alt="KnockBites" style="width: 80px; height: 80px; border-radius: 16px;">
    <h1 style="color: #1a1a1a; margin-top: 16px; font-size: 24px;">Sign In to KnockBites</h1>
  </div>

  <div style="background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); padding: 30px; border-radius: 16px; text-align: center;">
    <p style="color: #1a1a1a; font-size: 16px; margin-bottom: 20px;">
      Click the button below to sign in to your account.
    </p>
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: #1a1a1a; color: #fff; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
      Sign In
    </a>
  </div>

  <p style="color: #666; font-size: 14px; text-align: center; margin-top: 30px;">
    This link will expire in 24 hours. If you didn't request this, you can safely ignore this email.
  </p>

  <div style="border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; text-align: center;">
    <p style="color: #999; font-size: 12px;">
      KnockBites - Fresh Food, Fast Delivery
    </p>
  </div>
</div>
```

### Reset Password (Customer)
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/customer-logo.png" alt="KnockBites" style="width: 80px; height: 80px; border-radius: 16px;">
    <h1 style="color: #1a1a1a; margin-top: 16px; font-size: 24px;">Reset Your Password</h1>
  </div>

  <div style="background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); padding: 30px; border-radius: 16px; text-align: center;">
    <p style="color: #1a1a1a; font-size: 16px; margin-bottom: 20px;">
      We received a request to reset your password. Click below to create a new one.
    </p>
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: #1a1a1a; color: #fff; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
      Reset Password
    </a>
  </div>

  <p style="color: #666; font-size: 14px; text-align: center; margin-top: 30px;">
    This link will expire in 1 hour. If you didn't request a password reset, you can safely ignore this email.
  </p>

  <div style="border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; text-align: center;">
    <p style="color: #999; font-size: 12px;">
      KnockBites - Fresh Food, Fast Delivery
    </p>
  </div>
</div>
```

### Invite User / Staff Invite (Business)
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/business-logo.png" alt="KnockBites Business" style="width: 80px; height: 80px; border-radius: 16px;">
    <h1 style="color: #1a1a1a; margin-top: 16px; font-size: 24px;">You're Invited!</h1>
    <p style="color: #666; font-size: 14px;">KnockBites Business Portal</p>
  </div>

  <div style="background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%); padding: 30px; border-radius: 16px; text-align: center;">
    <p style="color: #fff; font-size: 16px; margin-bottom: 20px;">
      You've been invited to join the KnockBites team. Click below to set up your staff account.
    </p>
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: #fff; color: #1D4ED8; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
      Accept Invitation
    </a>
  </div>

  <p style="color: #666; font-size: 14px; text-align: center; margin-top: 30px;">
    This invitation will expire in 7 days. If you weren't expecting this invite, please contact your manager.
  </p>

  <div style="border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; text-align: center;">
    <p style="color: #999; font-size: 12px;">
      KnockBites Business - Staff Management Portal
    </p>
  </div>
</div>
```

### Change Email Address
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <img src="https://dsmefhuhflixoevexafm.supabase.co/storage/v1/object/public/email-assets/customer-logo.png" alt="KnockBites" style="width: 80px; height: 80px; border-radius: 16px;">
    <h1 style="color: #1a1a1a; margin-top: 16px; font-size: 24px;">Confirm Email Change</h1>
  </div>

  <div style="background: linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%); padding: 30px; border-radius: 16px; text-align: center;">
    <p style="color: #1a1a1a; font-size: 16px; margin-bottom: 20px;">
      Please confirm your new email address by clicking the button below.
    </p>
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; background: #1a1a1a; color: #fff; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px;">
      Confirm New Email
    </a>
  </div>

  <p style="color: #666; font-size: 14px; text-align: center; margin-top: 30px;">
    If you didn't request this change, please contact support immediately.
  </p>

  <div style="border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; text-align: center;">
    <p style="color: #999; font-size: 12px;">
      KnockBites - Fresh Food, Fast Delivery
    </p>
  </div>
</div>
```

## Notes

- Customer-facing emails use the gold/amber brand colors (#FBBF24, #F59E0B)
- Business/Staff emails use blue colors (#3B82F6, #1D4ED8) to differentiate
- All emails are mobile-responsive and use system fonts for best compatibility
- Logos are 80x80px in emails for optimal display

## Email Template Variables

Supabase provides these variables for email templates:
- `{{ .ConfirmationURL }}` - The confirmation/action link
- `{{ .Token }}` - The raw token (if needed)
- `{{ .TokenHash }}` - Hashed token
- `{{ .SiteURL }}` - Your site URL
- `{{ .RedirectTo }}` - Redirect URL after action
