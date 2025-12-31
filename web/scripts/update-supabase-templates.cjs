const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env.local') });

// SECURITY: Load credentials from environment variables
// To use this script, set these in your .env.local file:
//   SUPABASE_PROJECT_REF=your_project_ref
//   SUPABASE_ACCESS_TOKEN=your_access_token (from Supabase Dashboard > Settings > API)
const PROJECT_REF = process.env.SUPABASE_PROJECT_REF;
const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN;

if (!PROJECT_REF || !ACCESS_TOKEN) {
  console.error('ERROR: Missing required environment variables.');
  console.error('Please set SUPABASE_PROJECT_REF and SUPABASE_ACCESS_TOKEN in .env.local');
  process.exit(1);
}

const templatesDir = path.join(__dirname, '..', 'email-templates');

// Read all template files
const templates = {
  confirmation: fs.readFileSync(path.join(templatesDir, 'confirm-signup.html'), 'utf8'),
  recovery: fs.readFileSync(path.join(templatesDir, 'reset-password.html'), 'utf8'),
  magic_link: fs.readFileSync(path.join(templatesDir, 'magic-link.html'), 'utf8'),
  email_change: fs.readFileSync(path.join(templatesDir, 'change-email.html'), 'utf8'),
  invite: fs.readFileSync(path.join(templatesDir, 'invite-user.html'), 'utf8'),
  password_changed: fs.readFileSync(path.join(templatesDir, 'password-changed.html'), 'utf8'),
  email_changed: fs.readFileSync(path.join(templatesDir, 'email-changed.html'), 'utf8'),
  phone_changed: fs.readFileSync(path.join(templatesDir, 'phone-changed.html'), 'utf8'),
  identity_linked: fs.readFileSync(path.join(templatesDir, 'identity-linked.html'), 'utf8'),
};

const payload = {
  site_url: 'https://knockbites.com',
  mailer_subjects_confirmation: 'Welcome to KnockBites! Please confirm your email',
  mailer_subjects_recovery: 'Reset your KnockBites password',
  mailer_subjects_magic_link: 'Your KnockBites sign-in link',
  mailer_subjects_email_change: 'Confirm your new email address - KnockBites',
  mailer_subjects_invite: "You're invited to join KnockBites!",
  mailer_subjects_password_changed_notification: 'Your KnockBites password was changed',
  mailer_subjects_email_changed_notification: 'Your KnockBites email was changed',
  mailer_subjects_phone_changed_notification: 'Your KnockBites phone number was changed',
  mailer_subjects_identity_linked_notification: 'New login method added to your KnockBites account',
  mailer_templates_confirmation_content: templates.confirmation,
  mailer_templates_recovery_content: templates.recovery,
  mailer_templates_magic_link_content: templates.magic_link,
  mailer_templates_email_change_content: templates.email_change,
  mailer_templates_invite_content: templates.invite,
  mailer_templates_password_changed_notification_content: templates.password_changed,
  mailer_templates_email_changed_notification_content: templates.email_changed,
  mailer_templates_phone_changed_notification_content: templates.phone_changed,
  mailer_templates_identity_linked_notification_content: templates.identity_linked,
};

async function updateTemplates() {
  console.log('Updating email templates for knockbites-staging...');

  try {
    const response = await fetch(`https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('Error:', response.status, error);
      return;
    }

    const result = await response.json();
    console.log('Successfully updated email templates!');
    console.log('Site URL:', result.site_url);
  } catch (error) {
    console.error('Failed:', error.message);
  }
}

updateTemplates();
