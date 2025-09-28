# Image Storage & Fetching Guide for App Developer

## **Database Schema**

### **Table: `profiles`**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  image_urls JSONB DEFAULT '[]'::jsonb,  -- Array of image URLs
  location TEXT,
  description TEXT,
  hobbies JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **Key Field: `image_urls`**
- **Type**: `JSONB` (JSON array)
- **Format**: `["url1", "url2", "url3"]`
- **Example**: `["https://dkcitxzvojvecuvacwsp.supabase.co/storage/v1/object/public/profile-photos/user-id/image1.jpg", "https://dkcitxzvojvecuvacwsp.supabase.co/storage/v1/object/public/profile-photos/user-id/image2.jpg"]`

## **Storage Location**

### **Supabase Storage Bucket: `profile-photos`**
- **Bucket Name**: `profile-photos`
- **Public Access**: ✅ Yes (publicly accessible)
- **File Structure**: `{user_id}/{timestamp}_{filename}`
- **Example Path**: `63b22ccf-d6ad-4d08-b741-cc47156c2085/1758708122098_image.jpg`

### **URL Format**
```
https://dkcitxzvojvecuvacwsp.supabase.co/storage/v1/object/public/profile-photos/{user_id}/{filename}
```

## **How to Fetch Images in Flutter App**

### **1. Database Query**
```dart
// Fetch profile with images
final response = await SupabaseService.client
  .from('profiles')
  .select('id, name, age, image_urls, location, description, hobbies')
  .eq('id', userId)
  .single();

final profile = response.data;
```

### **2. Parse Image URLs**
```dart
// Get image URLs from database
List<String> imageUrls = [];
if (profile['image_urls'] != null) {
  final urls = profile['image_urls'] as List;
  imageUrls = urls.map((url) => url.toString()).toList();
}
```

### **3. Display Images**
```dart
// First image (main profile photo)
String? mainImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

// All images (gallery)
List<String> galleryImages = imageUrls;

// Display in UI
if (mainImageUrl != null) {
  Image.network(mainImageUrl)
}

// Gallery
for (String imageUrl in galleryImages) {
  Image.network(imageUrl)
}
```

## **Current App Implementation (Working)**

### **Profile Loading** (`controller_profile_screen.dart`)
```dart
// Lines 62-66: Support both photos/image_urls
if (profile['photos'] != null) {
  myPhotos.value = List<String>.from(profile['photos']);
} else if (profile['image_urls'] != null) {
  myPhotos.value = List<String>.from((profile['image_urls'] as List).map((e) => e.toString()));
}
```

### **Profile Discovery** (`controller_discover_screen.dart`)
```dart
// Lines 210-212: Support both photos/image_urls
List<String> photos = _asStringList(r['photos']);
if (photos.isEmpty) photos = _asStringList(r['image_urls']);
```

### **Profile Updates** (`controller_profile_screen.dart`)
```dart
// Line 141: Use image_urls field
'image_urls': myPhotos.toList(),
```

## **Image Upload Process**

### **1. Upload to Storage**
```dart
// Upload file to Supabase storage
final imageUrl = await SupabaseService.uploadFile(
  bucket: 'profile-photos',
  path: '$userId/$fileName',
  fileBytes: bytes,
);
```

### **2. Save to Database**
```dart
// Update profile with new image URLs
await SupabaseService.client
  .from('profiles')
  .update({
    'image_urls': imageUrls, // Array of all image URLs
  })
  .eq('id', userId);
```

## **Important Notes for App Developer**

### **✅ What's Working**
1. **Database field**: `image_urls` (JSONB array)
2. **Storage bucket**: `profile-photos` (public)
3. **URL format**: Supabase public URLs
4. **App compatibility**: Already supports both `photos` and `image_urls` fields

### **🔧 What to Check**
1. **Field consistency**: Use `image_urls` (not `photos`)
2. **Array format**: Ensure it's a proper JSON array
3. **URL validity**: Check if URLs are accessible
4. **Fallback handling**: Handle cases where `image_urls` is null/empty

### **🐛 Common Issues**
1. **Null/empty arrays**: Check for `image_urls` being null or empty
2. **Invalid URLs**: Verify URLs are properly formatted
3. **Storage permissions**: Ensure bucket is public
4. **Field mismatch**: Use `image_urls` not `photos`

## **Testing Checklist**

- [ ] Profile loads with images from `image_urls` field
- [ ] Images display correctly in UI
- [ ] New uploads save to `image_urls` array
- [ ] Fallback works when `image_urls` is null/empty
- [ ] Both single image and gallery work
- [ ] URLs are accessible (not 404)

## **Example Working Query**

```dart
// Fetch profile with images
final response = await SupabaseService.client
  .from('profiles')
  .select('*')
  .eq('id', userId)
  .single();

final profile = response.data;
final imageUrls = (profile['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [];
```

This should give you all the information needed to properly fetch and display images in the Flutter app!
