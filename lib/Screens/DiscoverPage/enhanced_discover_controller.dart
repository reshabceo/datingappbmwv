import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/analytics_service.dart';
import 'package:lovebug/Common/widget_constant.dart';
import 'package:lovebug/Common/text_constant.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/Screens/DiscoverPage/profile_detail_screen.dart';
import 'package:lovebug/Screens/ChatPage/chat_integration_helper.dart';
import 'controller_discover_screen.dart';

class EnhancedDiscoverController extends GetxController {
  final ThemeController themeController = Get.find<ThemeController>();
  
  // Observable lists
  final RxList<Profile> profiles = <Profile>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMoreProfiles = true.obs;
  
  // Filtering options
  final RxList<String> selectedGenders = <String>[].obs;
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 100.obs;
  final RxInt maxDistance = 50.obs; // in km
  
  // Pagination
  final int profilesPerPage = 10;
  int currentOffset = 0;
  
  @override
  void onInit() {
    super.onInit();
    _loadUserPreferences();
    _loadActiveProfiles();
  }

  // Load user preferences from database
  Future<void> _loadUserPreferences() async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseService.client
          .from('user_preferences')
          .select('preferred_gender, min_age, max_age, max_distance')
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (response != null) {
        selectedGenders.value = List<String>.from(response['preferred_gender'] ?? []);
        minAge.value = response['min_age'] ?? 18;
        maxAge.value = response['max_age'] ?? 100;
        maxDistance.value = response['max_distance'] ?? 50;
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  // Save user preferences to database
  Future<void> saveUserPreferences() async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      await SupabaseService.client.rpc('set_user_preferences', params: {
        'p_preferred_gender': selectedGenders.toList(),
        'p_min_age': minAge.value,
        'p_max_age': maxAge.value,
        'p_max_distance': maxDistance.value,
      });

      // Reload profiles with new preferences
      _loadActiveProfiles();
    } catch (e) {
      print('Error saving user preferences: $e');
      Get.snackbar('Error', 'Failed to save preferences');
    }
  }

  // Load profiles using the new filtered function
  Future<void> _loadActiveProfiles() async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      currentOffset = 0;
      
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) {
        profiles.clear();
        return;
      }

      // Use the new filtered function
      final response = await SupabaseService.client
          .rpc('get_filtered_profiles', params: {
        'p_user_id': currentUserId,
        'p_limit': profilesPerPage,
        'p_offset': currentOffset,
      });

      if (response.error != null) {
        print('Error loading profiles: ${response.error}');
        return;
      }

      if (response.data != null) {
        final newProfiles = (response.data as List<dynamic>)
            .map((data) => _mapToProfile(data))
            .where((profile) => profile.id.isNotEmpty)
            .toList();

        profiles.value = newProfiles;
        currentIndex.value = 0;
        hasMoreProfiles.value = newProfiles.length >= profilesPerPage;
        currentOffset += newProfiles.length;
      }
    } catch (e) {
      print('Error loading profiles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load more profiles for pagination
  Future<void> loadMoreProfiles() async {
    if (isLoading.value || !hasMoreProfiles.value) return;
    
    try {
      isLoading.value = true;
      
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseService.client
          .rpc('get_filtered_profiles', params: {
        'p_user_id': currentUserId,
        'p_limit': profilesPerPage,
        'p_offset': currentOffset,
      });

      if (response.error != null) {
        print('Error loading more profiles: ${response.error}');
        return;
      }

      if (response.data != null) {
        final newProfiles = (response.data as List<dynamic>)
            .map((data) => _mapToProfile(data))
            .where((profile) => profile.id.isNotEmpty)
            .toList();

        profiles.addAll(newProfiles);
        hasMoreProfiles.value = newProfiles.length >= profilesPerPage;
        currentOffset += newProfiles.length;
      }
    } catch (e) {
      print('Error loading more profiles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Map database data to Profile object
  Profile _mapToProfile(Map<String, dynamic> data) {
    final photos = <String>[];
    if (data['image_urls'] != null) {
      photos.addAll(List<String>.from(data['image_urls']));
    }
    
    final hobbies = <String>[];
    if (data['hobbies'] != null) {
      hobbies.addAll(List<String>.from(data['hobbies']));
    }

    return Profile(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unknown',
      age: (data['age'] ?? 25) as int,
      imageUrl: photos.isNotEmpty ? photos.first : '',
      photos: photos,
      location: data['location']?.toString() ?? 'Unknown',
      distance: data['distance']?.toString() ?? 'Unknown distance',
      description: data['description']?.toString() ?? 'No description available',
      hobbies: hobbies,
      isVerified: false,
      isActiveNow: true,
      gender: data['gender']?.toString(),
    );
  }

  // Swipe actions
  Future<void> onSwipeLeft(Profile profile) async {
    await AnalyticsService.trackSwipe('pass', profile.id);
    await _handleSwipe(profile, action: 'pass');
  }

  Future<void> onSwipeRight(Profile profile) async {
    await AnalyticsService.trackSwipe('like', profile.id);
    await _handleSwipe(profile, action: 'like');
  }

  Future<void> onSuperLike(Profile profile) async {
    await AnalyticsService.trackSwipe('super_like', profile.id);
    await _handleSwipe(profile, action: 'super_like');
  }

  // Handle swipe with improved error handling
  Future<void> _handleSwipe(Profile profile, {required String action}) async {
    final currentUserId = SupabaseService.currentUser?.id;
    final otherId = profile.id;

    print('DEBUG: Starting swipe $action on profile $otherId by user $currentUserId');

    if (currentUserId == null || otherId.isEmpty) {
      print('DEBUG: Invalid user IDs, skipping swipe');
      _moveToNextCard();
      _removeProfileSafely(profile);
      return;
    }

    // Additional safety check for self-swipe
    if (otherId == currentUserId) {
      print('DEBUG: Cannot swipe on yourself, skipping');
      _moveToNextCard();
      _removeProfileSafely(profile);
      return;
    }

    try {
      // Get current mode from the discover controller
      final discoverController = Get.find<DiscoverController>();
      final currentMode = discoverController.currentMode.value;
      print('🔍 DEBUG: Current mode for swipe: $currentMode');
      
      final res = await SupabaseService.handleSwipe(
        swipedId: otherId, 
        action: action, 
        mode: currentMode
      );
      
      // Check for errors in response
      if (res.containsKey('error')) {
        print('DEBUG: Swipe error: ${res['error']}');
        Get.snackbar('Error', res['error']);
        return;
      }
      
      final bool matched = (res['matched'] == true);
      final String matchId = (res['match_id'] ?? '').toString();

      print('DEBUG: RPC handle_swipe result matched=$matched matchId=$matchId');

      _moveToNextCard();
      _removeProfileSafely(profile);

      if (matched && matchId.isNotEmpty) {
        await AnalyticsService.trackMatch(matchId, otherId);
        
        // Generate ice breakers for the new match
        _generateIceBreakersForMatch(matchId);
        
        await Future.delayed(const Duration(milliseconds: 300));
        _showMatchDialog(profile, matchId, currentMode);
      }
    } catch (e) {
      print('DEBUG: RPC swipe failed: $e');
      Get.snackbar('Error', 'Failed to process swipe. Please try again.');
    }
  }

  void _moveToNextCard() {
    if (currentIndex.value < profiles.length - 1) {
      currentIndex.value++;
    } else {
      // Load more profiles if available
      if (hasMoreProfiles.value) {
        loadMoreProfiles();
      }
      // Don't loop back to prevent cards from reappearing
    }
  }

  // Generate ice breakers for a new match
  Future<void> _generateIceBreakersForMatch(String matchId) async {
    try {
      print('DEBUG: Generating ice breakers for match $matchId');
      
      // Call the edge function to generate ice breakers
      final resp = await SupabaseService.client.functions.invoke(
        'generate-match-insights',
        body: {'matchId': matchId},
      );
      
      if (resp.data != null && resp.data['success'] == true) {
        print('DEBUG: Ice breakers generated successfully for match $matchId');
      } else {
        print('DEBUG: Failed to generate ice breakers for match $matchId: ${resp.data}');
        // Don't show error to user, this is background generation
      }
    } catch (e) {
      print('DEBUG: Error generating ice breakers for match $matchId: $e');
      // Don't show error to user, this is background generation
      // The chat will still work without ice breakers
    }
  }

  void _removeProfileSafely(Profile profile) {
    profiles.removeWhere((p) => p.id == profile.id);
    if (currentIndex.value >= profiles.length) {
      currentIndex.value = math.max(0, profiles.length - 1);
    }
  }

  void _showMatchDialog(Profile profile, String matchId, String mode) {
    Get.dialog(
      Dialog(
        backgroundColor: themeController.transparentColor,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: themeController.blackColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: themeController.primaryColor.value,
              width: 2.w,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextConstant(
                title: mode == 'bff' ? 'Meet Your New BFF! 🤝' : 'It\'s a Match! 🎉',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeController.whiteColor,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: ProfileAvatar(
                      imageUrl: profile.imageUrl,
                      size: 80,
                      borderWidth: 3.w,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: ProfileAvatar(
                      imageUrl: SupabaseService.currentUser?.userMetadata?['avatar_url'] ?? '',
                      size: 80,
                      borderWidth: 3.w,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextConstant(
                title: 'You and ${profile.name} liked each other!',
                fontSize: 16,
                color: themeController.whiteColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        // Navigate to enhanced chat
                        ChatIntegrationHelper.navigateToChat(
                          userImage: profile.imageUrl,
                          userName: profile.name,
                          matchId: matchId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeController.primaryColor.value,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                      ),
                      child: TextConstant(
                        title: 'Send Message',
                        color: themeController.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeController.transparentColor,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                          side: BorderSide(
                            color: themeController.whiteColor.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                      ),
                      child: TextConstant(
                        title: 'Keep Swiping',
                        color: themeController.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter methods
  void updateGenderFilter(List<String> genders) {
    selectedGenders.value = genders;
    saveUserPreferences();
  }

  void updateAgeRange(int min, int max) {
    minAge.value = min;
    maxAge.value = max;
    saveUserPreferences();
  }

  void updateMaxDistance(int distance) {
    maxDistance.value = distance;
    saveUserPreferences();
  }

  // View profile details
  void viewProfile(Profile profile) {
    Get.to(() => ProfileDetailScreen(profile: profile));
  }

  // Refresh profiles
  Future<void> refreshProfiles() async {
    await _loadActiveProfiles();
  }
}

// Profile class extension to include gender
class Profile {
  final String id;
  final String name;
  final int age;
  final String imageUrl;
  final List<String> photos;
  final String location;
  final String distance;
  final String description;
  final List<String> hobbies;
  final bool isVerified;
  final bool isActiveNow;
  final String? gender;
  final bool isSuperLiked;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.photos,
    required this.location,
    required this.distance,
    required this.description,
    required this.hobbies,
    required this.isVerified,
    required this.isActiveNow,
    this.gender,
    this.isSuperLiked = false,
  });
}
