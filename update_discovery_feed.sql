-- Update get_discovery_feed function to include user's own posts
-- Run this in your Supabase SQL Editor

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

