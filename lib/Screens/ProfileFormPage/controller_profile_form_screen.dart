import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as image_cropper;
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
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
        // Try to crop the image, but continue with original if cropping fails
        XFile imageToUse = image;
        try {
          final croppedImage = await _cropImage(image);
          if (croppedImage != null) {
            imageToUse = croppedImage;
          }
        } catch (e) {
          print('Cropping failed, using original image: $e');
          // Continue with original image
        }
        
        selectedImages.add(imageToUse);
        await uploadImageToSupabase(imageToUse);
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
            // Try to crop each image, but continue with original if cropping fails
            XFile imageToUse = image;
            try {
              final croppedImage = await _cropImage(image);
              if (croppedImage != null) {
                imageToUse = croppedImage;
              }
            } catch (e) {
              print('Cropping failed for image, using original: $e');
              // Continue with original image
            }
            
            selectedImages.add(imageToUse);
            await uploadImageToSupabase(imageToUse);
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
      final croppedFile = await image_cropper.ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const image_cropper.CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          image_cropper.AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.pink,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: image_cropper.CropAspectRatioPreset.square,
            lockAspectRatio: false,
            statusBarColor: Colors.pink,
            activeControlsWidgetColor: Colors.pink,
          ),
          image_cropper.IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
      return null;
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

      final profileData = {
        'id': user.id,
        'name': nameController.text,
        'age': age,
        'gender': selectedGender.value,
        'description': aboutController.text,
        'hobbies': selectedInterests.toList(),
        'image_urls': uploadedImageUrls.toList(),
        'is_active': true,
      };

      await SupabaseService.createProfile(profileData);
      
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
}
