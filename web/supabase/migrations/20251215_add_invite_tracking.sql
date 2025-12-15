-- Add invite tracking fields to user_profiles
-- This allows tracking pending invitations and reminder emails

-- Add invite_status column
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'accepted'
CHECK (invite_status IN ('pending', 'accepted'));

-- Add invited_at timestamp
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ;

-- Add last_reminder_sent timestamp
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS last_reminder_sent TIMESTAMPTZ;

-- Add email field for easier invite tracking
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS email TEXT;

-- Update existing records to have 'accepted' status (they're already active)
UPDATE user_profiles
SET invite_status = 'accepted'
WHERE invite_status IS NULL;

-- Create index for finding pending invites
CREATE INDEX IF NOT EXISTS idx_user_profiles_invite_status
ON user_profiles(invite_status) WHERE invite_status = 'pending';

-- Comment on columns
COMMENT ON COLUMN user_profiles.invite_status IS 'pending = awaiting acceptance, accepted = user has logged in';
COMMENT ON COLUMN user_profiles.invited_at IS 'When the invite was first sent';
COMMENT ON COLUMN user_profiles.last_reminder_sent IS 'When the last reminder email was sent';
