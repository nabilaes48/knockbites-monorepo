# KnockBites Email Templates for Supabase

## Setup Instructions

1. Go to **Supabase Dashboard** → **Authentication** → **Email Templates**
2. Click on each template type and paste the corresponding HTML
3. Update the Subject line as noted below
4. Save changes

## Templates & Subjects

### Auth Templates (with confirmation links)
| Template | Subject Line | File |
|----------|--------------|------|
| Confirm Sign Up | `Welcome to KnockBites! Please confirm your email` | `confirm-signup.html` |
| Reset Password | `Reset your KnockBites password` | `reset-password.html` |
| Magic Link | `Your KnockBites sign-in link` | `magic-link.html` |
| Change Email | `Confirm your new email address - KnockBites` | `change-email.html` |
| Invite User | `You're invited to join KnockBites!` | `invite-user.html` |

### Security Notifications (no links needed)
| Template | Subject Line | File |
|----------|--------------|------|
| Password Changed | `Your KnockBites password was changed` | `password-changed.html` |
| Email Changed | `Your KnockBites email was changed` | `email-changed.html` |
| Phone Changed | `Your KnockBites phone number was changed` | `phone-changed.html` |
| Identity Linked | `New login method added to your KnockBites account` | `identity-linked.html` |

## Logo Setup

The templates use `{{ .SiteURL }}/email-logo.png` for the logo. Ensure `email-logo.png` is deployed in your web root.

## Brand Colors

- **Primary Orange:** `#F5A623`
- **Secondary Orange:** `#FF9500`
