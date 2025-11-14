-- ============================================
-- Supabase Migration: Feed Feature & Follow System
-- ============================================
-- This migration adds:
-- 1. Posts table for the feed feature
-- 2. Post likes table
-- 3. User follows table
-- 4. Updates to user_profiles if needed
-- ============================================

-- ============================================
-- 1. Create Posts Table
-- ============================================
CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  car_spot_id UUID REFERENCES car_spots(id) ON DELETE SET NULL,
  image_url TEXT,
  description TEXT,
  hashtags TEXT[], -- Array of hashtags
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_car_spot_id ON posts(car_spot_id);

-- ============================================
-- 2. Create Post Likes Table
-- ============================================
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id) -- Prevent duplicate likes
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);

-- ============================================
-- 3. Create User Follows Table
-- ============================================
CREATE TABLE IF NOT EXISTS user_follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id), -- Prevent duplicate follows
  CHECK (follower_id != following_id) -- Prevent self-follow
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following_id ON user_follows(following_id);

-- ============================================
-- 4. Update User Profiles (if table exists)
-- ============================================
-- Add followers_count and following_count if they don't exist
DO $$ 
BEGIN
  -- Add followers_count column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'followers_count'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN followers_count INTEGER DEFAULT 0;
  END IF;

  -- Add following_count column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'following_count'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN following_count INTEGER DEFAULT 0;
  END IF;

  -- Add posts_count column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'posts_count'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN posts_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- ============================================
-- 5. Enable Row Level Security (RLS)
-- ============================================

-- Enable RLS on posts table
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Enable RLS on post_likes table
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_follows table
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. RLS Policies for Posts
-- ============================================

-- Policy: Users can view all posts (public feed)
CREATE POLICY "Anyone can view posts" ON posts
  FOR SELECT
  USING (true);

-- Policy: Users can create their own posts
CREATE POLICY "Users can create their own posts" ON posts
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own posts
CREATE POLICY "Users can update their own posts" ON posts
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own posts
CREATE POLICY "Users can delete their own posts" ON posts
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 7. RLS Policies for Post Likes
-- ============================================

-- Policy: Anyone can view likes
CREATE POLICY "Anyone can view post likes" ON post_likes
  FOR SELECT
  USING (true);

-- Policy: Users can like posts
CREATE POLICY "Users can like posts" ON post_likes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can unlike their own likes
CREATE POLICY "Users can unlike posts" ON post_likes
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 8. RLS Policies for User Follows
-- ============================================

-- Policy: Anyone can view follows
CREATE POLICY "Anyone can view follows" ON user_follows
  FOR SELECT
  USING (true);

-- Policy: Users can follow others
CREATE POLICY "Users can follow others" ON user_follows
  FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

-- Policy: Users can unfollow (delete their own follows)
CREATE POLICY "Users can unfollow" ON user_follows
  FOR DELETE
  USING (auth.uid() = follower_id);

-- ============================================
-- 9. Functions to Update Counts
-- ============================================

-- Function to update post likes count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts 
    SET likes_count = likes_count + 1 
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts 
    SET likes_count = GREATEST(likes_count - 1, 0)
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update likes count
DROP TRIGGER IF EXISTS trigger_update_post_likes_count ON post_likes;
CREATE TRIGGER trigger_update_post_likes_count
  AFTER INSERT OR DELETE ON post_likes
  FOR EACH ROW
  EXECUTE FUNCTION update_post_likes_count();

-- Function to update user followers/following counts
CREATE OR REPLACE FUNCTION update_user_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment following count for follower
    UPDATE user_profiles 
    SET following_count = following_count + 1 
    WHERE id = NEW.follower_id;
    
    -- Increment followers count for following
    UPDATE user_profiles 
    SET followers_count = followers_count + 1 
    WHERE id = NEW.following_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement following count for follower
    UPDATE user_profiles 
    SET following_count = GREATEST(following_count - 1, 0)
    WHERE id = OLD.follower_id;
    
    -- Decrement followers count for following
    UPDATE user_profiles 
    SET followers_count = GREATEST(followers_count - 1, 0)
    WHERE id = OLD.following_id;
    
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update follow counts
DROP TRIGGER IF EXISTS trigger_update_user_follow_counts ON user_follows;
CREATE TRIGGER trigger_update_user_follow_counts
  AFTER INSERT OR DELETE ON user_follows
  FOR EACH ROW
  EXECUTE FUNCTION update_user_follow_counts();

-- Function to update user posts count
CREATE OR REPLACE FUNCTION update_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE user_profiles 
    SET posts_count = posts_count + 1 
    WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE user_profiles 
    SET posts_count = GREATEST(posts_count - 1, 0)
    WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update posts count
DROP TRIGGER IF EXISTS trigger_update_user_posts_count ON posts;
CREATE TRIGGER trigger_update_user_posts_count
  AFTER INSERT OR DELETE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_user_posts_count();

-- ============================================
-- 10. Function to Get User Feed (Following + Discoveries)
-- ============================================

-- Function to get posts from users you follow
CREATE OR REPLACE FUNCTION get_following_feed(user_uuid UUID, limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  car_spot_id UUID,
  image_url TEXT,
  description TEXT,
  hashtags TEXT[],
  likes_count INTEGER,
  comments_count INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  username TEXT,
  avatar_url TEXT,
  is_liked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.car_spot_id,
    p.image_url,
    p.description,
    p.hashtags,
    p.likes_count,
    p.comments_count,
    p.created_at,
    p.updated_at,
    COALESCE(up.username, 'User') as username,
    up.avatar_url,
    (pl.id IS NOT NULL) as is_liked
  FROM posts p
  INNER JOIN user_follows uf ON p.user_id = uf.following_id
  LEFT JOIN user_profiles up ON p.user_id = up.id
  LEFT JOIN post_likes pl ON pl.post_id = p.id AND pl.user_id = user_uuid
  WHERE uf.follower_id = user_uuid
  ORDER BY p.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get discovery feed (all posts, excluding own)
CREATE OR REPLACE FUNCTION get_discovery_feed(user_uuid UUID, limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  car_spot_id UUID,
  image_url TEXT,
  description TEXT,
  hashtags TEXT[],
  likes_count INTEGER,
  comments_count INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  username TEXT,
  avatar_url TEXT,
  is_liked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.car_spot_id,
    p.image_url,
    p.description,
    p.hashtags,
    p.likes_count,
    p.comments_count,
    p.created_at,
    p.updated_at,
    COALESCE(up.username, 'User') as username,
    up.avatar_url,
    (pl.id IS NOT NULL) as is_liked
  FROM posts p
  LEFT JOIN user_profiles up ON p.user_id = up.id
  LEFT JOIN post_likes pl ON pl.post_id = p.id AND pl.user_id = user_uuid
  ORDER BY p.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 11. Grant Permissions
-- ============================================

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON posts TO authenticated;
GRANT SELECT, INSERT, DELETE ON post_likes TO authenticated;
GRANT SELECT, INSERT, DELETE ON user_follows TO authenticated;
GRANT EXECUTE ON FUNCTION get_following_feed TO authenticated;
GRANT EXECUTE ON FUNCTION get_discovery_feed TO authenticated;

-- ============================================
-- Migration Complete!
-- ============================================
-- To apply this migration:
-- 1. Copy the contents of this file
-- 2. Go to Supabase Dashboard > SQL Editor
-- 3. Paste and run the migration
-- 4. Verify tables and policies are created correctly
-- ============================================

