import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/astro_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as image_cropper;
import 'dart:io';
import 'dart:typed_data';
import 'package:lovebug/Screens/Common/custom_crop_page.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../services/location_service.dart';
import '../BottomBarPage/bottombar_screen.dart';
import '../BottomBarPage/controller_bottombar_screen.dart';

class ProfileFormController extends GetxController {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  
  // Gender selection
  RxString selectedGender = ''.obs;

  RxList<String> selectedLanguage = <String>[].obs;
  RxList<String> languageList = <String>[
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Chinese',
  ].obs;

  RxList<String> selectedInterests = <String>[].obs;
  RxList<String> interestsList = <String>[
    'Music',
    'Travel',
    'Sports',
    'Movies',
    'Art',
    'Food',
    'Photography',
    'Reading',
    'Gaming',
    'Dancing',
  ].obs;

  RxList<XFile> selectedImages = <XFile>[].obs;
  RxList<String> uploadedImageUrls = <String>[].obs;
  RxBool isUploading = false.obs;
  RxBool isLoading = false.obs;
  
  // Date picker
  Rx<DateTime> birthDate = DateTime(2000).obs;
  
  Future<void> showBirthDatePicker(BuildContext context) async {
    print('🗓️ DEBUG: showBirthDatePicker called');
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: birthDate.value,
        firstDate: DateTime(1920),
        lastDate: DateTime.now().subtract(Duration(days: 365 * 18)), // Minimum 18 years old
        builder: (context, child) {
          print('🗓️ DEBUG: Date picker builder called');
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.pink,
                onPrimary: Colors.white,
                surface: Colors.grey[900]!,
                onSurface: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.pink,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      
      print('🗓️ DEBUG: Date picker result: $picked');
      if (picked != null && picked != birthDate.value) {
        birthDate.value = picked;
        ageController.text = calculateAge(picked).toString();
        dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
        print('🗓️ DEBUG: Date updated - Age: ${ageController.text}, Date: ${dateOfBirthController.text}');
      }
    } catch (e) {
      print('🗓️ DEBUG: Error in showBirthDatePicker: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _checkAuthenticationStatus();
  }

  void _checkAuthenticationStatus() {
    final user = SupabaseService.currentUser;
    final session = SupabaseService.client.auth.currentSession;
    
    print('ProfileFormController - Current user: ${user?.id}');
    print('ProfileFormController - User email: ${user?.email}');
    print('ProfileFormController - Session exists: ${session != null}');
    print('ProfileFormController - Session user: ${session?.user.id}');
    print('ProfileFormController - Session access token: ${session?.accessToken != null}');
    
    if (user == null) {
      print('No authenticated user found in ProfileFormController');
      // Try to restore session
      _tryRestoreSession();
    }
  }

  Future<void> _tryRestoreSession() async {
    try {
      print('Attempting to restore session...');
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        print('Session restored: ${session.user.id}');
      } else {
        print('No session to restore');
        // Show error to user
        Get.snackbar('Authentication Error', 'Please go back and sign in again');
      }
    } catch (e) {
      print('Error restoring session: $e');
    }
  }

  Future<void> pickImageFromCamera(ImageSource type) async {
    try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: type);
    if (image != null) {
        // Try to crop the image. If user cancels (null), do not add/upload.
        try {
          final XFile? croppedImage = await _cropImage(image);
          if (croppedImage == null) {
            print('📷 Image cropping cancelled by user');
            return; // treat as cancel
          }
          selectedImages.add(croppedImage);
          await uploadImageToSupabase(croppedImage);
        } catch (e) {
          print('Cropping failed, using original image: $e');
          // If cropping errored out unexpectedly, proceed with original
          selectedImages.add(image);
          await uploadImageToSupabase(image);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (XFile image in images) {
          if (selectedImages.length < 6) { // Max 6 photos
            try {
              final XFile? croppedImage = await _cropImage(image);
              if (croppedImage == null) {
                print('📷 Multi-select: cropping cancelled for one image');
                continue; // skip this one
              }
              selectedImages.add(croppedImage);
              await uploadImageToSupabase(croppedImage);
            } catch (e) {
              print('Cropping failed for image, using original: $e');
              selectedImages.add(image);
              await uploadImageToSupabase(image);
            }
          }
        }
      }
    } catch (e) {
      print('Error picking multiple images: $e');
      Get.snackbar('Error', 'Failed to pick images: ${e.toString()}');
    }
  }

  Future<void> uploadImageToSupabase(XFile image) async {
    try {
      isUploading.value = true;
      update(); // Trigger UI update
      
      // Check if user is authenticated
      final user = SupabaseService.currentUser;
      print('Upload attempt - Current user: ${user?.id}');
      print('User email: ${user?.email}');
      print('User session: ${SupabaseService.client.auth.currentSession?.user.id}');
      
      if (user == null) {
        print('No user found, showing login error');
        Get.snackbar('Error', 'Please login first. Go back and verify OTP or sign in with email.');
        return;
      }
      
      final bytes = await image.readAsBytes();
      final userId = user.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Use folder structure that matches Supabase policy: userId/filename
      final path = '$userId/$fileName';
      
      print('Uploading image for user: $userId');
      print('Image path: $path');
      
      // Try uploading with a different approach
      try {
        final imageUrl = await SupabaseService.uploadFile(
          bucket: 'profile-photos',
          path: path,
          fileBytes: bytes,
        );
        
        if (imageUrl.isNotEmpty) {
          uploadedImageUrls.add(imageUrl);
          update();
          Get.snackbar('Success', 'Image uploaded successfully');
          print('Image uploaded successfully: $imageUrl');
        } else {
          Get.snackbar('Error', 'Failed to upload image');
        }
      } catch (uploadError) {
        print('Upload error: $uploadError');
        // Fallback: Store image locally for now
        uploadedImageUrls.add('local://$path');
        update();
        Get.snackbar('Warning', 'Image saved locally. Storage permissions need to be fixed.');
      }
    } catch (e) {
      print('Error uploading image: $e');
      String errorMessage = 'Failed to upload image';
      
      if (e.toString().contains('row-level security policy')) {
        errorMessage = 'Storage permissions issue. Please check Supabase storage policies.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied. Please check your authentication.';
      } else if (e.toString().contains('Unauthorized')) {
        errorMessage = 'Unauthorized access. Please sign in again.';
      } else {
        errorMessage = 'Failed to upload image: ${e.toString()}';
      }
      
      Get.snackbar('Error', errorMessage);
    } finally {
      isUploading.value = false;
      update(); // Trigger UI update
    }
  }

  Future<void> removeImage(int index) async {
    if (index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
    if (index < uploadedImageUrls.length) {
      uploadedImageUrls.removeAt(index);
    }
    update(); // Trigger UI update
  }

  // Image cropping method
  Future<XFile?> _cropImage(XFile imageFile) async {
    try {
      if (kIsWeb) {
        // For web, use crop_your_image
        return await _cropImageWeb(imageFile);
      } else {
        // For mobile, use image_cropper
        return await _cropImageMobile(imageFile);
      }
    } catch (e) {
      print('Error cropping image: $e');
      // Return original image if cropping fails to prevent app crash
      return imageFile;
    }
  }

  Future<XFile?> _cropImageMobile(XFile imageFile) async {
    try {
      // Use in-app cropper for better SafeArea spacing
      final bytes = await File(imageFile.path).readAsBytes();
      final Uint8List? croppedBytes = await Get.to(() => CustomCropPage(imageBytes: bytes));
      if (croppedBytes == null) return null; // user cancelled
      return XFile.fromData(
        croppedBytes,
        name: 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );
    } catch (e) {
      print('Error cropping image on mobile: $e');
      return imageFile;
    }
  }

  Future<XFile?> _cropImageWeb(XFile imageFile) async {
    try {
      // For web, just return the original image for now
      // In a real app, you'd implement web-based cropping
      return imageFile;
    } catch (e) {
      print('Error cropping image on web: $e');
      return imageFile;
    }
  }

  Future<Uint8List> _resizeImage(Uint8List bytes, int width, int height) async {
    // Simple image resizing for web
    // This is a basic implementation - in production you'd want to use a proper image library
    return bytes; // For now, return original bytes
  }

  // Calculate age from date of birth
  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> saveProfile() async {
    try {
      isLoading.value = true;
      
      // Check if user is authenticated
      final user = SupabaseService.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login first');
        isLoading.value = false;
        return;
      }

      // Validate required fields
      if (selectedGender.value.isEmpty) {
        Get.snackbar('Error', 'Gender is required');
        isLoading.value = false;
        return;
      }
      
      if (nameController.text.isEmpty) {
        Get.snackbar('Error', 'Name is required');
        isLoading.value = false;
        return;
      }
      
      if (dateOfBirthController.text.isEmpty) {
        Get.snackbar('Error', 'Date of birth is required');
        isLoading.value = false;
        return;
      }
      
      if (uploadedImageUrls.isEmpty) {
        Get.snackbar('Error', 'At least one photo is required');
        isLoading.value = false;
        return;
      }
      
      if (selectedInterests.length < 2) {
        Get.snackbar('Error', 'Please select at least 2 interests');
        isLoading.value = false;
        return;
      }

      // Parse date of birth and calculate age (DD/MM/YYYY format)
      final text = dateOfBirthController.text;
      final parts = text.split('/');
      if (parts.length != 3) {
        Get.snackbar('Error', 'Invalid date format. Use DD/MM/YYYY');
        isLoading.value = false;
        return;
      }
      
      DateTime birthDate;
      int age;
      try {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        birthDate = DateTime(year, month, day);
        age = calculateAge(birthDate);
        if (age < 18) {
          Get.snackbar('Error', 'You must be 18 or older');
          isLoading.value = false;
          return;
        }
      } catch (e) {
        Get.snackbar('Error', 'Invalid date format. Use DD/MM/YYYY');
        isLoading.value = false;
        return;
      }

      // Set is_premium based on gender: Female = premium, Male/Non-binary/Other = normal
      // Use case-insensitive comparison to handle 'Female', 'female', 'FEMALE', etc.
      final bool isPremium = selectedGender.value.trim().toLowerCase() == 'female';
      
      final profileData = {
        'id': user.id,
        'name': nameController.text,
        'age': age,
        'gender': selectedGender.value,
        'description': aboutController.text,
        'hobbies': selectedInterests.toList(),
        'image_urls': uploadedImageUrls.toList(),
        'is_active': true,
        'is_premium': isPremium, // Set premium based on gender: Female = true, others = false
        'birth_date': birthDate.toIso8601String().split('T')[0],
        'zodiac_sign': AstroService.calculateZodiacSign(birthDate),
      };

      // Use upsert instead of insert to handle duplicate key constraint
      await SupabaseService.upsertProfile(profileData);
      
      // Track profile creation analytics
      await AnalyticsService.trackProfileCreated({
        'has_photos': uploadedImageUrls.isNotEmpty,
        'has_bio': aboutController.text.isNotEmpty,
        'age': age,
        'gender': selectedGender.value,
        'interests_count': selectedInterests.length,
        'languages_count': selectedLanguage.length,
      });
      
      // Track profile completion for UAC
      await AnalyticsService.trackProfileCompleted({
        'photos': uploadedImageUrls.toList(),
        'bio': aboutController.text,
        'age': age,
        'gender': selectedGender.value,
        'interests': selectedInterests.toList(),
        'languages': selectedLanguage.toList(),
      });
      
      Get.snackbar('Success', 'Profile created successfully!');
      
      // Hide profile completion banner (if BottomBarController exists)
      try {
        final bottomBarController = Get.find<BottomBarController>();
        bottomBarController.showProfileCompletionBanner.value = false;
      } catch (e) {
        print('BottomBarController not found, skipping banner update: $e');
      }
      
      Get.offAll(() => BottombarScreen()); // Navigate to main app
    } catch (e) {
      print('Error saving profile: $e');
      Get.snackbar('Error', 'Failed to save profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Request location permission during profile completion
  Future<void> requestLocationPermission() async {
    try {
      print('📍 ProfileFormController: Requesting location permission...');
      
      // Import permission_handler to check status directly
      final permissionHandler = await Permission.locationWhenInUse.status;
      print('📍 ProfileFormController: Current permission status: $permissionHandler');
      
      // Check if permanently denied
      if (permissionHandler.isPermanentlyDenied) {
        print('⚠️ ProfileFormController: Permission permanently denied, showing settings dialog');
        // Show dialog to guide user to settings
        final shouldOpenSettings = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Get.theme.scaffoldBackgroundColor,
            title: Text(
              'Location Permission Required',
              style: TextStyle(color: Get.theme.textTheme.titleLarge?.color),
            ),
            content: Text(
              'Location access is required to find nearby matches. Please enable it in your device settings.',
              style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(
                  'Skip',
                  style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(
                  backgroundColor: Get.theme.primaryColor,
                ),
                child: Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        
        if (shouldOpenSettings == true) {
          await LocationService.openAppLocationSettings();
        }
        return;
      }
      
      // Try to request permission
      final granted = await LocationService.requestLocationPermission();
      
      if (granted) {
        print('✅ ProfileFormController: Location permission granted');
        // Update user location after permission is granted
        await LocationService.updateUserLocation();
        Get.snackbar('Success', 'Location access enabled!', 
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          duration: Duration(seconds: 2));
      } else {
        print('❌ ProfileFormController: Location permission denied');
        // Show dialog for denied permission
        await Get.dialog(
          AlertDialog(
            backgroundColor: Get.theme.scaffoldBackgroundColor,
            title: Text(
              'Location Access Needed',
              style: TextStyle(color: Get.theme.textTheme.titleLarge?.color),
            ),
            content: Text(
              'To find matches near you, please enable location access in your device settings.',
              style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'OK',
                  style: TextStyle(color: Get.theme.primaryColor),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ ProfileFormController: Error requesting location permission: $e');
      Get.snackbar('Error', 'Failed to request location permission: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white);
    }
  }
}
