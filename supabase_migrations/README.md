# Supabase Database Migrations

This directory contains SQL migration files for the SpotCarz database.

## Setup Instructions

### 1. Add Brand to Enum Function

**IMPORTANT:** You must run this migration before the app can automatically add brands to the enum.

Run the migration file `add_brand_to_enum.sql` in your Supabase SQL Editor:

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `add_brand_to_enum.sql`
5. Click **Run** to execute
6. **Wait a few seconds** for PostgREST to refresh its schema cache

**If you get an error that the function doesn't exist after running the migration:**

1. **Verify the function exists:**
   - Go to **Database** → **Functions** in your Supabase dashboard
   - Verify that `add_brand_to_enum` appears in the list
   - OR run `verify_function.sql` in the SQL Editor to check

2. **If the function doesn't exist:**
   - Re-run the `add_brand_to_enum.sql` migration
   - Check for any error messages in the SQL Editor

3. **If the function exists but still not found:**
   - Wait 1-2 minutes for PostgREST to refresh its schema cache
   - Alternatively, trigger a schema refresh by:
     - Making a small change to any table (add/remove a comment)
     - Or restarting your Supabase project (if you have access)

This creates a function `add_brand_to_enum(brand_name TEXT)` that:
- Checks if a brand value already exists in the `car_brand` enum
- Adds the brand to the enum if it doesn't exist
- Prevents duplicate enum values
- Grants execute permission to authenticated users

### 2. How It Works

When a user tries to create a car spot with a brand that doesn't exist in the database enum:

1. The Flutter app detects the enum error (code 22P02)
2. It checks if the brand exists in `car_brands.dart`
3. If valid, it calls the `add_brand_to_enum` database function
4. The function adds the brand to the enum (if not already present)
5. The app retries the insert operation
6. The car spot is created successfully

### 3. Security

The function uses `SECURITY DEFINER` which means it runs with the privileges of the function creator (typically a database admin). This is necessary because adding enum values requires elevated permissions.

The function is granted to `authenticated` users, so any logged-in user can call it, but it only adds enum values - it doesn't modify other database structures.

### 4. Notes

- Enum values are normalized to lowercase (e.g., "audi", "bmw")
- The function checks for existing values before adding to prevent duplicates
- If the enum value already exists, the function does nothing (no error)
- The function is idempotent - safe to call multiple times

