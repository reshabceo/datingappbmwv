# Picture Upload Fix Guide

## Issues Identified

1. **Multiple GoTrueClient instances** - Causing authentication conflicts
2. **Storage policy restrictions** - RLS policies blocking uploads
3. **Poor error handling** - Upload failures not properly displayed
4. **Missing file validation** - No size/type checks

## Solutions Implemented

### 1. Fixed Storage Policies
- Created `web/fix-storage-policies.sql` with simplified, working policies
- Allows authenticated users to upload to profile-photos bucket
- Enables public viewing of profile photos
- Proper user-specific update/delete permissions

### 2. Enhanced Upload Function
- Added comprehensive logging in `web/src/services/api.ts`
- Better error handling and user feedback
- Authentication verification before upload
- Proper error messages

### 3. Improved Components
- Enhanced `ProfileEdit.tsx` with better error handling
- Improved `Step3Photos.tsx` with file validation
- Added file size limits (10MB) and type validation

### 4. Debugging Tools
- Created `web/test-upload.html` for testing uploads
- Added `web/fix-auth-upload.js` for debugging

## Steps to Fix Upload Issues

### Step 1: Apply Storage Policy Fix
Run the SQL script in your Supabase dashboard:
```sql
-- Copy and run the contents of web/fix-storage-policies.sql
```

### Step 2: Test Upload Functionality
1. Open `web/test-upload.html` in your browser
2. Replace the Supabase URL and key with your actual values
3. Test uploading an image file

### Step 3: Check Browser Console
Look for these debug messages:
- `📤 [UPLOAD] Starting upload for user:`
- `📤 [UPLOAD] User authenticated:`
- `📤 [UPLOAD] Upload successful:`
- `📤 [UPLOAD] Public URL generated:`

### Step 4: Verify Database Sync
After successful upload, check that:
1. Image URLs are saved to the `profiles` table
2. Images are accessible via public URLs
3. Both website and app show the same images

## Common Issues and Solutions

### Issue: "User not authenticated"
**Solution**: Check if user is properly logged in before upload

### Issue: "Upload failed: Permission denied"
**Solution**: Run the storage policy fix SQL script

### Issue: "Failed to get public URL"
**Solution**: Verify the bucket is public and policies allow viewing

### Issue: Multiple GoTrueClient instances
**Solution**: Ensure only one Supabase client instance is created

## Testing Checklist

- [ ] User can select image files
- [ ] File validation works (size, type)
- [ ] Upload progress is shown
- [ ] Success/error messages appear
- [ ] Images appear in profile after upload
- [ ] Images are accessible via public URLs
- [ ] Database is updated with image URLs
- [ ] No console errors during upload

## Files Modified

1. `web/src/services/api.ts` - Enhanced upload function
2. `web/src/pages/ProfileEdit.tsx` - Better error handling
3. `web/src/pages/ProfileSetup/Step3Photos.tsx` - File validation
4. `web/fix-storage-policies.sql` - Storage policy fixes
5. `web/test-upload.html` - Upload testing tool
6. `web/fix-auth-upload.js` - Authentication debugging

## Next Steps

1. Apply the storage policy fix
2. Test the upload functionality
3. Verify images appear in both website and app
4. Monitor console for any remaining errors
5. Remove debug logging once everything works

