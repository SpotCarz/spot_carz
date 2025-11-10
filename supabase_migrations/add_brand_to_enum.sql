-- Function to safely add a brand to the car_brand enum if it doesn't exist
CREATE OR REPLACE FUNCTION add_brand_to_enum(brand_name TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  enum_exists BOOLEAN;
  enum_type_oid OID;
BEGIN
  -- Get the enum type OID
  SELECT oid INTO enum_type_oid
  FROM pg_type 
  WHERE typname = 'car_brand';
  
  -- Check if the value already exists in the enum
  SELECT EXISTS (
    SELECT 1 
    FROM pg_enum 
    WHERE enumlabel = LOWER(brand_name) 
    AND enumtypid = enum_type_oid
  ) INTO enum_exists;
  
  -- If it doesn't exist, add it
  IF NOT enum_exists THEN
    -- Note: ALTER TYPE ... ADD VALUE cannot be used in a transaction block
    -- This function must be called outside of a transaction or the transaction
    -- must be committed before the enum value can be used
    EXECUTE format('ALTER TYPE car_brand ADD VALUE %L', LOWER(brand_name));
  END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_brand_to_enum(TEXT) TO authenticated;

