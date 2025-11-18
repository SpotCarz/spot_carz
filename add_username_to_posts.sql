-- ============================================
-- Migration: Add username column to posts table
-- ============================================
-- This migration adds a username column to the posts table
-- to store the user's display name directly in the post for easier retrieval.
-- ============================================

-- Add username column to posts table if it doesn't exist
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS username TEXT;

-- Create index for faster queries by username
CREATE INDEX IF NOT EXISTS idx_posts_username ON posts(username);

-- Update existing posts with username from user_profiles
-- This backfills existing posts with the display name
UPDATE posts p
SET username = COALESCE(
  (SELECT full_name FROM user_profiles up WHERE up.id = p.user_id),
  (SELECT username FROM user_profiles up WHERE up.id = p.user_id),
  'User'
)
WHERE username IS NULL;

-- Add comment to column
COMMENT ON COLUMN posts.username IS 'Display name of the user who created the post (stored for easy retrieval)';

