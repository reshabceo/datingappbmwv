import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';

class ProfileController extends GetxController {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController interestController = TextEditingController();

  RxList<String> genderType = <String>['Male', 'Female', 'Non-binary'].obs;
  RxList<String> lookingType = <String>['Men', 'Women', 'Everyone'].obs;

  RxInt selectedGenderIndex = 0.obs;
  RxInt selectedLookingIndex = 1.obs;

  RxBool textInputBold = false.obs;
  RxBool textInputItalic = false.obs;
  RxBool textInputEmoji = false.obs;

  final RxString selectedCountry = ''.obs;
  RxBool isReorderMode = false.obs;

  FocusNode focusNode = FocusNode();

  @override
  void onInit() {
    focusNode.addListener(() {
    if (focusNode.hasFocus) {
      textInputEmoji.value = false;
    }
  });
    loadUserProfile();
    super.onInit();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      print('🔄 Loading user profile...');
      final user = SupabaseService.currentUser;
      print('🔄 Current user: ${user?.id}');
      print('🔄 Current user email: ${user?.email}');
      
      if (user != null) {
        print('🔄 Fetching profile for user ID: ${user.id}');
        final profile = await SupabaseService.getProfile(user.id);
        print('🔄 Profile loaded: $profile');
        print('🔄 Profile is null: ${profile == null}');
        
        // Check if profile is deactivated
        if (profile != null && profile['is_active'] == false) {
          print('🚫 Profile is deactivated - this should not happen after reactivation');
        }
        
        if (profile != null) {
          print('Raw profile data: $profile');
          userProfile.value = profile;
          nameController.text = profile['name'] ?? '';
          ageController.text = profile['age']?.toString() ?? '';
          locationController.text = profile['location'] ?? '';
          // Support both bio/description
          aboutController.text = (profile['bio'] ?? profile['description'] ?? '') as String;
          // Support photos/image_urls - prioritize image_urls over photos to avoid duplicates
          List<String> allPhotos = [];
          if (profile['image_urls'] != null) {
            allPhotos.addAll(List<String>.from((profile['image_urls'] as List).map((e) => e.toString())));
          } else if (profile['photos'] != null) {
            allPhotos.addAll(List<String>.from(profile['photos']));
          }
          // Remove duplicates and empty strings
          myPhotos.value = allPhotos.toSet().where((url) => url.isNotEmpty).toList();
          print('DEBUG: Loaded ${myPhotos.value.length} unique photos: ${myPhotos.value}');
          // Support interests/hobbies
          if (profile['interests'] != null) {
            myInterestList.value = List<String>.from(profile['interests']);
          } else if (profile['hobbies'] != null) {
            myInterestList.value = List<String>.from((profile['hobbies'] as List).map((e) => e.toString()));
          }
          isVerified.value = (profile['is_verified'] ?? false) as bool;
          
          print('Profile data set: ${userProfile.value}');
          print('Name: ${userProfile.value['name']}');
          print('Description: ${userProfile.value['description']}');
          print('Bio: ${userProfile.value['bio']}');
        } else {
          print('❌ No profile found for user - this might be the issue!');
          print('❌ User ID: ${user.id}');
          print('❌ This could be due to RLS policies or database connection issues');
          // Set default values if no profile exists
          userProfile.value = {
            'name': 'User',
            'age': 25,
            'location': 'New York',
            'description': 'Tell us about yourself...',
            'image_urls': [],
            'hobbies': ['Music', 'Sports'],
            'matches_count': 0,
            'profile_views': 0,
            'active_chats': 0,
          };
        }
      } else {
        print('No current user found');
        // Set default values if no user
        userProfile.value = {
          'name': 'User',
          'age': 25,
          'location': 'New York',
          'bio': 'Tell us about yourself...',
          'photos': [],
          'interests': ['Music', 'Sports'],
          'matches_count': 0,
          'profile_views': 0,
          'active_chats': 0,
        };
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e.toString().contains('RLS') || e.toString().contains('policy')) {
        print('❌ This looks like an RLS (Row Level Security) policy issue!');
      }
      Get.snackbar('Error', 'Failed to load profile: $e');
      
      // Set default values on error
      userProfile.value = {
        'name': 'User',
        'age': 25,
        'location': 'New York',
        'bio': 'Tell us about yourself...',
        'photos': [],
        'interests': ['Music', 'Sports'],
        'matches_count': 0,
        'profile_views': 0,
        'active_chats': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    try {
      isLoading.value = true;
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profileData = {
          'name': nameController.text,
          'age': int.tryParse(ageController.text) ?? 0,
          'location': locationController.text,
          'description': aboutController.text, // Use description instead of bio
          'hobbies': myInterestList.toList(), // Use hobbies instead of interests
          'image_urls': myPhotos.toList(), // Use image_urls instead of photos
        };

        print('DEBUG: Updating profile with data: $profileData');
        await SupabaseService.updateProfile(
          userId: user.id,
          data: profileData,
        );
        
        print('DEBUG: Profile updated successfully in database');
        userProfile.value = {...userProfile.value, ...profileData};
        Get.snackbar('Success', 'Profile updated successfully!');
      }
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onReady() {
    textInputEmoji.value = false;
    textInputBold.value = false;
    textInputItalic.value = false;
    super.onReady();
  }


  final List<String> countries = [
    "🇮🇳  India",
    "🇨🇳  China",
    "🇧🇷  Brazil",
    "🇮🇩  Indonesia",
    "🇻🇳  Vietnam",
    "🇳🇬  Nigeria",
    "🇲🇽  Mexico",
    "🇹🇷  Turkey",
    "🇵🇭  Philippines",
    "🇿🇦  South Africa",
    "🇧🇩  Bangladesh",
    "🇸🇦  Saudi Arabia",
    "🇪🇬  Egypt",
    "🇨🇴  Colombia",
    "🇰🇪  Kenya",
    "🇹🇭  Thailand",
    "🇵🇰  Pakistan",
    "🇦🇷  Argentina",
    "🇲🇾  Malaysia",
    "🇨🇱  Chile",
  ];

  RxList<String> myPhotos = <String>[].obs;
  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;
  RxBool isLoading = false.obs;
  RxBool isVerified = false.obs;

  RxList<String> myInterestList = <String>[
    'Music Production',
    'Hiking',
    'Coffee',
    'Restaurants',
    'Photography',
    'Travel',
    'Movies',
    'Art',
  ].obs;

  RxList<String> popularInterestList = <String>[
    'Gaming',
    'Fitness',
    'Reading',
    'Cooking',
    'Dancing',
    'Yoga',
    'Fashion',
    'Technology',
  ].obs;

  Rx<XFile?> selectedImage = Rx<XFile?>(null);

  Future<void> pickImageFromCamera(ImageSource type) async {
    try {
      // Check if user is authenticated
      final user = SupabaseService.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please log in to upload photos');
        return;
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: type);
      if (image != null) {
        selectedImage.value = image;
        
        // Read image bytes
        final bytes = await image.readAsBytes();
        
        // Generate unique filename with user ID as folder
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = image.path.split('.').last;
        final filename = '${user.id}/profile_${timestamp}.$extension';
        
        print('DEBUG: Uploading to bucket: profile-photos');
        print('DEBUG: Uploading to path: $filename');
        print('DEBUG: User ID: ${user.id}');
        print('DEBUG: File size: ${bytes.length} bytes');
        
        // Upload to Supabase storage
        final imageUrl = await SupabaseService.uploadFile(
          bucket: 'profile-photos',
          path: filename,
          fileBytes: bytes,
        );
        
        // Add the URL to myPhotos list
        myPhotos.add(imageUrl);
        print('Image uploaded successfully: $imageUrl');
        print('My photos count: ${myPhotos.length}');
        
        // Update profile in database
        await updateProfile();
        
        Get.snackbar('Success', 'Photo uploaded successfully!');
      }
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }

  Future<void> pickImageList(ImageSource type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: type);
    if (image != null) {
      myPhotos.add(image.path);
    }
  }

  RxBool isProfileVisibility = true.obs;

  profileVisibility() {
    isProfileVisibility.value = !isProfileVisibility.value;
  }

  RxBool isShowAge = true.obs;

  showAge() {
    isShowAge.value = !isShowAge.value;
  }

  RxBool isShowDistance = true.obs;

  showDistance() {
    isShowDistance.value = !isShowDistance.value;
  }
}
