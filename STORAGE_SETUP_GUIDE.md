# Complete Storage & Database Setup Guide

## Long-term Fix for Storage Issues

This guide provides a comprehensive setup for all storage buckets and database tables needed for the LoveBug dating app.

## Step 1: Database Schema Setup

1. **Open Supabase SQL Editor**
2. **Run the database schema first:**
   - Copy and paste the contents of `complete_database_schema.sql`
   - Click "Run" to execute

## Step 2: Storage Buckets Setup

1. **Run the storage setup:**
   - Copy and paste the contents of `complete_storage_setup.sql`
   - Click "Run" to execute

## Step 3: Verify Setup

After running both scripts, verify everything is working:

### Check Storage Buckets
```sql
SELECT id, name, public FROM storage.buckets 
WHERE id IN ('profile-photos', 'chat-photos', 'disappearing-photos', 'stories');
```

### Check Database Tables
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'disappearing_photos';
```

### Check Storage Policies
```sql
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
```

## What This Setup Provides

### Storage Buckets Created:
- **profile-photos**: For user profile pictures
- **chat-photos**: For regular chat photos
- **disappearing-photos**: For Snapchat-like disappearing photos
- **stories**: For story photos

### Database Tables Created:
- **disappearing_photos**: Stores disappearing photo metadata

### Security Features:
- **Row Level Security (RLS)**: All tables have proper RLS policies
- **User-specific access**: Users can only access their own content
- **Match-based access**: Users can only see photos from their matches
- **Expiration handling**: Automatic cleanup of expired photos

## Troubleshooting

### If you get "must be owner" errors:
1. Make sure you're running as the project owner
2. Try running the scripts in smaller chunks
3. Check that you have the correct permissions in Supabase

### If storage uploads fail:
1. Verify the bucket exists: `SELECT * FROM storage.buckets;`
2. Check policies: `SELECT * FROM pg_policies WHERE tablename = 'objects';`
3. Ensure the user is authenticated

### If disappearing photos don't work:
1. Check the table exists: `SELECT * FROM disappearing_photos LIMIT 1;`
2. Verify RLS policies are active
3. Check that the match_id exists in the matches table

## Testing the Setup

After setup, test these features:

1. **Profile Photo Upload**: Should work without errors
2. **Chat Photo Upload**: Should work for both regular and disappearing photos
3. **Disappearing Photos**: Should expire after the set duration
4. **Story Uploads**: Should work for story photos

## Maintenance

The setup includes automatic cleanup functions for expired photos. You can also manually run:

```sql
SELECT cleanup_expired_disappearing_photos();
```

This will remove all expired disappearing photos from the database.
