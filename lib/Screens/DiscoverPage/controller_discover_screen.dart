import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/services/analytics_service.dart';
import 'package:lovebug/Screens/ChatPage/chat_integration_helper.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';
import 'package:lovebug/widgets/upgrade_prompt_widget.dart';
import 'package:lovebug/Screens/SubscriptionPage/ui_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovebug/services/geocoding_service.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovebug/shared_prefrence_helper.dart';
import 'package:lovebug/services/location_service.dart';
import 'package:collection/collection.dart';
import '../ChatPage/controller_chat_screen.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lovebug/services/payment_service.dart';
import 'package:lovebug/Common/widget_constant.dart';

class DiscoverController extends GetxController {
  // Cache for geocoded locations to avoid redundant Nominatim API calls
  static final Map<String, String> _locationCache = {};

  // Feature flags
  static const bool useSupabaseProfiles = true;

  final profiles = <Profile>[].obs;
  final currentIndex = 0.obs;
  // Index used by neon name overlay to avoid desync with CardSwiper animations
  final overlayIndex = 0.obs;
  // Local session guards to avoid resurfacing within session
  final RxSet<String> seenIds = <String>{}.obs;
  final RxSet<String> passedIds = <String>{}.obs;
  final RxSet<String> likedIds = <String>{}.obs;
  final RxBool isPreloading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxInt preloadedCount = 0.obs;
  
  // Deck version – bump to force CardSwiper to rebuild when order/size changes
  final RxInt deckVersion = 0.obs;
  // Minimum number of cards before first render to avoid instant-jump glitches
  static const int _minInitialDeckCount = 10;
  
  // Track last swiped profile for rewind functionality
  Profile? _lastSwipedProfile;
  int? _lastSwipedIndex;
  CardSwiperDirection? _lastSwipeDirection; // Track swipe direction for reverse animation
  final RxBool isRewinding = false.obs; // Track if we're in rewind animation mode
  
  // Getter for last swipe direction (used by UI for reverse animation)
  CardSwiperDirection? get lastSwipeDirection => _lastSwipeDirection;
  
  // Callback for programmatic swipe (set by UI)
  VoidCallback? _onSwipeRightCallback;
  
  // Set callback for programmatic swipe
  void setSwipeRightCallback(VoidCallback? callback) {
    _onSwipeRightCallback = callback;
  }
  
  // Trigger programmatic swipe right (called after sending premium message)
  void triggerSwipeRight() {
    if (_onSwipeRightCallback != null && currentProfile != null) {
      _onSwipeRightCallback!();
    } else if (currentProfile != null) {
      // Fallback: just call onSwipeRight which will handle backend
      onSwipeRight(currentProfile!);
    }
  }

  // Mode toggle (Dating/BFF)
  final RxString currentMode = 'dating'.obs; // 'dating' or 'bff'
  
  // Separate profile caches for each mode
  final RxList<Profile> datingProfiles = <Profile>[].obs;
  final RxList<Profile> bffProfiles = <Profile>[].obs;
  
  // Filters
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 99.obs;
  final RxString gender = 'Everyone'.obs; // Male, Female, Non-binary, Everyone
  final RxDouble maxDistanceKm = 50.0.obs;
  final RxBool isPremium = false.obs;
  final RxString intent = 'Everyone'.obs; // legacy single intent
  final RxSet<String> selectedIntents = <String>{}.obs; // Casual, Serious, Just Chatting

  // Prefs keys
  static const String _kModeKey = 'discover_mode';
  static const String _kMinAgeKey = 'filters_min_age';
  static const String _kMaxAgeKey = 'filters_max_age';
  static const String _kGenderKey = 'filters_gender';
  static const String _kDistanceKey = 'filters_distance_km';
  static const String _kIntentsKey = 'filters_intents';
  
  // Dummy profiles as fallback
  final dummyProfiles = <Profile>[
    Profile(
      id: 'dummy-1',
      name: 'Sophia',
      age: 23,
      imageUrl:
          'https://cdn.pixabay.com/photo/2023/09/14/08/20/girl-8252502_640.jpg',
      photos: ['https://cdn.pixabay.com/photo/2023/09/14/08/20/girl-8252502_640.jpg'],
      location: 'New York, NY',
      distance: '3 miles away',
      description:
          'Creative photographer who loves exploring the city at night. Looking for someone to share adventures and deep conversations with. Coffee addict and music lover.',
      hobbies: ['Photography', 'Music', 'Art', 'Coffee', 'Travel', 'Gaming'],
      isVerified: true,
      isActiveNow: true,
    ),
    Profile(
      id: 'dummy-2',
      name: 'Eva Elfie',
      age: 28,
      imageUrl:
          'https://i.pinimg.com/736x/ee/b1/9f/eeb19f4a2a3ba58cbbf0a9b825d4b436.jpg',
      photos: ['https://i.pinimg.com/736x/ee/b1/9f/eeb19f4a2a3ba58cbbf0a9b825d4b436.jpg'],
      location: 'Brooklyn, NY',
      distance: '5 miles away',
      description:
          'Software engineer by day, stand-up comedian by night. Always up for a laugh and a slice of pizza. Let\'s swap tech war stories over a cup of joe.',
      hobbies: ['Coding', 'Comedy', 'Pizza Tasting', 'Hiking', 'Chess'],
      isVerified: false,
      isActiveNow: false,
    ),
    Profile(
      id: 'dummy-3',
      name: 'Kate Winslet',
      age: 25,
      imageUrl:
          'https://numero.com/wp-content/uploads/2021/04/kate-winslet-lee-miller-titanic-the-reader-mare-of-easttown.jpg',
      photos: ['https://numero.com/wp-content/uploads/2021/04/kate-winslet-lee-miller-titanic-the-reader-mare-of-easttown.jpg'],
      location: 'Manhattan, NY',
      distance: '1.2 miles away',
      description:
          'Aspiring novelist and tea connoisseur. Weekends are for bookshops and jazz clubs. Looking for someone who can appreciate a good plot twist.',
      hobbies: ['Reading', 'Writing', 'Travel', 'Tea', 'Jazz'],
      isVerified: true,
      isActiveNow: false,
    ),
    Profile(
      id: 'dummy-4',
      name: 'Scarlett Johansson',
      age: 30,
      imageUrl:
          'https://news.northeastern.edu/wp-content/uploads/2024/05/Scarlett-Johansson1400.jpg',
      photos: ['https://news.northeastern.edu/wp-content/uploads/2024/05/Scarlett-Johansson1400.jpg'],
      location: 'Queens, NY',
      distance: '8 miles away',
      description:
          'Fitness coach and vegan food blogger. Passionate about health, wellness, and finding the best smoothie spots in the city.',
      hobbies: ['Gym', 'Vegan Cooking', 'Blogging', 'Yoga'],
      isVerified: false,
      isActiveNow: true,
    ),
    Profile(
      id: 'dummy-5',
      name: 'Elizabeth Olsen',
      age: 28,
      imageUrl:
          'https://assets.vogue.com/photos/5891899f85b3959618474a85/master/pass/elizabeth-olsen-straight-hair.jpg',
      photos: ['https://assets.vogue.com/photos/5891899f85b3959618474a85/master/pass/elizabeth-olsen-straight-hair.jpg'],
      location: 'Queens, NY',
      distance: '8 miles away',
      description:
          'Fitness coach and vegan food blogger. Passionate about health, wellness, and finding the best smoothie spots in the city.',
      hobbies: ['Gym', 'Vegan Cooking', 'Blogging', 'Yoga', 'Acting'],
      isVerified: true,
      isActiveNow: false,
    ),
  ];
  @override
  void onInit() {
    super.onInit();
    // Ensure current auth user has a profile row in DB
    SupabaseService.ensureCurrentUserProfile();
    _checkPremiumStatus();
    _loadModeFromPrefs();
    _loadFiltersFromPrefs(); // This is now async but we don't await it here
    _ensureLocationThenLoad();
  }

  Future<void> _checkPremiumStatus() async {
    // Check both profile flag and active subscription status
    final isProfilePremium = await SupabaseService.isPremiumUser();
    if (isProfilePremium) {
      isPremium.value = true;
    } else {
      isPremium.value = await PaymentService.hasActiveSubscription();
    }
    print('👑 DEBUG: Premium status updated: ${isPremium.value}');
  }

  // Mode management
  void setMode(String mode) async {
    if (mode == 'dating' || mode == 'bff') {
      if (mode == currentMode.value) return;
      
      print('🔄🔄🔄 DEBUG: setMode() called - changing from ${currentMode.value} to $mode');
      print('🔄 DEBUG: isPreloading BEFORE mode change: ${isPreloading.value}');
      
      // Update mode preferences in database
      await SupabaseService.updateModePreferences({
        'dating': mode == 'dating',
        'bff': mode == 'bff',
      });
      
      currentMode.value = mode;
      
      // Force refresh profiles for the new mode
      print('🔄 DEBUG: About to call refreshProfilesForMode($mode)');
      await refreshProfilesForMode(mode);
      print('🔄 DEBUG: refreshProfilesForMode($mode) completed');
      print('🔄 DEBUG: isPreloading AFTER refreshProfilesForMode: ${isPreloading.value}');
      
      await SharedPreferenceHelper.setString(_kModeKey, mode);
      
      // Notify other controllers about mode change
      _notifyModeChange(mode);
      
      print('🔄 DEBUG: setMode() completed. Final isPreloading: ${isPreloading.value}, profiles.length: ${profiles.length}');
    }
  }
  
  void _switchToModeProfiles(String mode) {
    // Show loading indicator when switching modes
    isPreloading.value = true;
    
    if (mode == 'bff') {
      profiles.value = List.from(bffProfiles);
    } else {
      profiles.value = List.from(datingProfiles);
    }
    currentIndex.value = 0;
    
    // Hide loading indicator
    isPreloading.value = false;
  }

  // Method to refresh profiles when switching modes
  Future<void> refreshProfilesForMode(String mode, {bool isFallback = false}) async {
    if (!isFallback) {
      print('🔄🔄 DEBUG: refreshProfilesForMode($mode) STARTED');
      print('🔄 DEBUG: Setting isPreloading = true');
      isPreloading.value = true;
    }
    
    // Show loading indicator immediately
    update();
    
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      final Set<String> excludedIds = await _loadExcludedUserIds();
      
      // Load fresh profiles for the new mode with optimized loading
      List<Map<String, dynamic>> rows;
      if (mode == 'bff') {
        print('🔍 DEBUG: Calling SupabaseService.getBffProfiles()...');
        rows = await SupabaseService.getBffProfiles();
        print('🔍 DEBUG: getBffProfiles() returned ${rows.length} profiles');
      } else {
        print('🔍 DEBUG: Calling SupabaseService.getProfilesWithSuperLikes()...');
        // Pass location parameters if available for backend filtering
        rows = await SupabaseService.getProfilesWithSuperLikes(
          userLatitude: _userLat,
          userLongitude: _userLon,
          maxDistanceKm: (_userLat != null && _userLon != null && maxDistanceKm.value > 0) 
              ? maxDistanceKm.value 
              : null,
        );
        print('🔍 DEBUG: getProfilesWithSuperLikes() returned ${rows.length} profiles');
      }
        if (rows.isEmpty) {
          if (!isFallback) {
            print('⚠️ DEBUG: Initial search returned EMPTY. Triggering automatic fallback...');
            await refreshProfilesForMode(mode, isFallback: true);
            return;
          }
          
          // If we are already in fallback and still have nothing, try Guaranteed Discovery for Dating
          if (mode == 'dating') {
             print('🚨🚨 DEBUG: No profiles even in fallback. Triggering Guaranteed Discovery...');
             // Proceed to the discovery section below by NOT returning
          } else {
             print('⚠️⚠️ DEBUG: NO PROFILES FOUND for $mode mode');
             profiles.clear();
             if (mode == 'bff') bffProfiles.clear(); else datingProfiles.clear();
             currentIndex.value = 0;
             isPreloading.value = false;
             isInitialLoading.value = false;
             update();
             return;
          }
        }
      
      // Process and filter profiles
      print('🔍 DEBUG: Processing ${rows.length} raw rows for $mode mode');
      final List<Profile> loaded = rows
          .where((r) {
            final id = (r['id'] ?? '').toString();
            if (id.isEmpty) return false;
            if (currentUserId != null && id == currentUserId) return false;
            if (excludedIds.contains(id)) return false;
            return true;
          })
          .where((r) {
            final age = (r['age'] ?? 0) as int;
            final isAgeMatch = age >= minAge.value && age <= maxAge.value;
            if (!isAgeMatch) {
              print('🔍 DEBUG: Filtered out ${r['name']} due to age: $age (Filter: ${minAge.value}-${maxAge.value})');
            }

            bool isGenderMatch = true;
            if (gender.value != 'Everyone' && !isFallback) {
              final g = (r['gender'] ?? '').toString();
              
              // Standardize comparison
              final targetGender = gender.value.toLowerCase().trim();
              final profileGender = g.toLowerCase().trim();
              
              isGenderMatch = profileGender.isNotEmpty && profileGender == targetGender;
              
              // 🤝 BFF MODE LENIENCY: If in BFF mode, be less strict about gender 
              // (allow if either is empty OR if profiles are missing)
              if (mode == 'bff') {
                if (profileGender.isEmpty) {
                  print('🔍 DEBUG: BFF Mode - Allowing ${r['name']} with empty gender');
                  isGenderMatch = true;
                }
              }
              
              if (!isGenderMatch) {
                print('🔍 DEBUG: Filtered out ${r['name']} due to gender: "$g" (Filter: "${gender.value}")');
              }
            }

            bool isIntentMatch = true;
            if (selectedIntents.isNotEmpty && !isFallback) {
              final i = (r['intent'] ?? '').toString();
              isIntentMatch = i.isNotEmpty && selectedIntents.map((e) => e.toLowerCase()).contains(i.toLowerCase());
              if (!isIntentMatch) {
                print('🔍 DEBUG: Filtered out ${r['name']} due to intent: "$i" (Filter: $selectedIntents)');
              }
            }
            
            return isAgeMatch && isGenderMatch && isIntentMatch;
          })
          .where((r) {
            if (_userLat == null || _userLon == null || maxDistanceKm.value <= 0) return true;
            final lat = (r['latitude'] as num?)?.toDouble();
            final lon = (r['longitude'] as num?)?.toDouble();
            if (lat == null || lon == null) return true;
            final d = _haversineKm(_userLat!, _userLon!, lat, lon);
            return d <= maxDistanceKm.value;
          })
          .map((r) {
            List<String> photos = _asStringList(r['image_urls']);
            if (photos.isEmpty) photos = _asStringList(r['photos']);
            photos = photos.where((u) => (u is String) && u.toString().trim().isNotEmpty).toList();
            
            // Calculate distance
            String distance = 'Unknown distance';
            final lat = (r['latitude'] as num?)?.toDouble();
            final lon = (r['longitude'] as num?)?.toDouble();
            
            if (_userLat != null && _userLon != null) {
              if (lat != null && lon != null) {
                final d = _haversineKm(_userLat!, _userLon!, lat, lon);
                distance = '${d.round()} miles away';
              }
            }

            // Determine display location
            String displayLocation = (r['location'] ?? '').toString();
            // If location is empty or looks like coordinates, try to use cache or geocode
            if (displayLocation.isEmpty || displayLocation.contains(',')) {
               if (lat != null && lon != null) {
                 final cacheKey = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
                 if (_locationCache.containsKey(cacheKey)) {
                   displayLocation = _locationCache[cacheKey]!;
                 } else {
                   // Start background geocoding
                   GeocodingService.getReadableLocation(lat, lon).then((resolved) {
                     if (resolved != '$lat, $lon') {
                       _locationCache[cacheKey] = resolved;
                       // We don't necessarily need to trigger a full refresh here to avoid jumping UI,
                       // but the next time this profile is rendered/accessed it will be correct.
                     }
                   });
                 }
               }
            }
            
            return Profile(
              id: (r['id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
              age: (r['age'] ?? 0) as int,
              imageUrl: photos.isNotEmpty ? photos.first : '',
              photos: photos,
              location: displayLocation,
              distance: distance,
              description: (r['description'] ?? '').toString(),
              intent: (r['intent'] ?? '').toString(),
              hobbies: _asStringList(r['hobbies']),
              isSuperLiked: (r['is_super_liked'] ?? false) as bool,
              isUnlocked: (r['is_unlocked'] ?? false) as bool,
              conversationMessageCount: (r['conversation_message_count'] ?? 0) as int,
            );
          })
          .toList();
      
      // Filter out non-displayable profiles (no name and no photos)
      final List<Profile> displayable = loaded.where((p) {
        final hasName = (p.name != null) && p.name.toString().trim().isNotEmpty;
        final hasPhoto = (p.photos.isNotEmpty) || (p.imageUrl.isNotEmpty);
        return hasName && hasPhoto;
      }).toList();

      // Session-level filtering to avoid resurfacing cards that were already swiped
      final List<Profile> sessionFiltered = displayable
          .where((p) => !seenIds.contains(p.id) && !passedIds.contains(p.id) && !likedIds.contains(p.id))
          .toList();

      print('🔍 DEBUG: refreshProfilesForMode - Raw: ${rows.length}, Validated: ${displayable.length}, SessionFiltered: ${sessionFiltered.length}');
      
      // Fallback: If too few profiles are found after filtering, automatically retry with relaxed filters
      // REMOVED rows.isNotEmpty check to allow fallback even if first query returned nothing
      if (sessionFiltered.length < 3 && !isFallback) {
        print('⚠️⚠️ DEBUG: No or very few profiles found (${sessionFiltered.length}). Triggering automatic fallback (ignoring gender/intent filters)...');
        await refreshProfilesForMode(mode, isFallback: true);
        return;
      }

      // Second-stage Fallback: Guaranteed Discovery
      if (sessionFiltered.length < 2 && mode == 'dating') {
         print('🚨🚨 DEBUG: Guaranteed Discovery Fallback for Dating. Loading all profiles...');
         try {
           final allRows = await SupabaseService.getProfiles(limit: 50);
           final List<Profile> allLoaded = allRows.map((r) {
              final images = r['photos'] as List? ?? r['image_urls'] as List? ?? [];
              
              // Handle geocoding for fallback profiles
              String displayLocation = (r['location'] ?? '').toString();
              final lat = (r['latitude'] as num?)?.toDouble();
              final lon = (r['longitude'] as num?)?.toDouble();
              
              if (displayLocation.isEmpty || displayLocation.contains(',')) {
                if (lat != null && lon != null) {
                  final cacheKey = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
                  if (_locationCache.containsKey(cacheKey)) {
                    displayLocation = _locationCache[cacheKey]!;
                  } else {
                    GeocodingService.getReadableLocation(lat, lon).then((resolved) {
                      if (resolved != '$lat, $lon') {
                        _locationCache[cacheKey] = resolved;
                      }
                    });
                  }
                }
              }

              return Profile(
                id: (r['id'] ?? '').toString(),
                name: (r['name'] ?? '').toString(),
                age: (r['age'] ?? 0) as int,
                photos: images.map((e) => e.toString()).toList(),
                imageUrl: images.isNotEmpty ? images.first.toString() : '',
                location: displayLocation,
                distance: 'Nearby',
                description: (r['description'] ?? '').toString(),
                hobbies: (r['hobbies'] as List? ?? []).map((e) => e.toString()).toList(),
              );
           }).toList();

           final List<Profile> filteredPool = allLoaded.where((p) {
              return p.id != currentUserId && 
                     !seenIds.contains(p.id) && 
                     !passedIds.contains(p.id) && 
                     !likedIds.contains(p.id) &&
                     p.name.isNotEmpty && 
                     p.photos.isNotEmpty;
           }).toList();
           
           if (filteredPool.isNotEmpty) {
             sessionFiltered.addAll(filteredPool.take(15));
             print('✅ DEBUG: Injected ${filteredPool.length} profiles from guaranteed discovery pool');
           }
         } catch (e) {
           print('❌ DEBUG: Guaranteed Discovery failed: $e');
         }
      }

      // Update profiles list with fresh data - optimized loading order
      profiles.value = sessionFiltered;
      currentIndex.value = 0;
      overlayIndex.value = 0; // keep neon overlay in sync on initial load
      deckVersion.value++; // force deck rebuild with fresh data
      
      // Stop initial loading spinner once data is processed
      isInitialLoading.value = false;
      isPreloading.value = false;
      
      // Update cached profiles for the new mode (FIXED: Use displayable instead of loaded)
      if (mode == 'bff') {
        bffProfiles
          ..clear()
          ..addAll(sessionFiltered);
        print('🔄 DEBUG: Cached ${bffProfiles.length} bff profiles');
      } else {
        datingProfiles
          ..clear()
          ..addAll(sessionFiltered);
        print('🔄 DEBUG: Cached ${datingProfiles.length} dating profiles');
      }
      
      // Debug: Log the first 3 profiles
      for (int i = 0; i < (sessionFiltered.length > 3 ? 3 : sessionFiltered.length); i++) {
        final p = sessionFiltered[i];
        print('🔍 DEBUG: Profile $i: ID=${p.id}, Name="${p.name}", Photos=${p.photos.length}');
        if (p.photos.isNotEmpty) {
          print('🔍 DEBUG:   First photo: "${p.photos.first}"');
        }
      }
      
      // Force immediate UI update for first card
      update();
      
      // Small delay to prevent race conditions with card rendering
      await Future.delayed(Duration(milliseconds: 50));
      
      // Preload remaining cards in background (optimized loading order)
      if (sessionFiltered.length > 1) {
        _preloadRemainingCards(sessionFiltered);
      }
      
      print('✅ Profiles refreshed for mode: $mode, count: ${profiles.length}');
      
      // 🔧 CRITICAL FIX: Set initial loading to false after profiles are loaded
      isInitialLoading.value = false;
      print('🔄 DEBUG: Set isInitialLoading = false, profiles loaded (session-filtered): ${sessionFiltered.length}');
      
    } catch (e) {
      print('❌ Error refreshing profiles for mode $mode: $e');
    } finally {
      isPreloading.value = false;
      isInitialLoading.value = false; // <--- FIX: Ensure loading screen disappears
      update(); // Force UI update
    }
  }

  void _notifyModeChange(String mode) {
    // Notify chat controller if it exists
    if (Get.isRegistered<EnhancedChatController>()) {
      final chatController = Get.find<EnhancedChatController>();
      chatController.onModeChanged(mode);
    }
  }

  void _loadModeFromPrefs() {
    try {
      final savedMode = SharedPreferenceHelper.getString(_kModeKey, defaultValue: 'dating');
      if (savedMode == 'dating' || savedMode == 'bff') {
        currentMode.value = savedMode;
      }
    } catch (_) {}
  }

  Future<void> reloadWithFilters() async {
    print('🔄 DEBUG: reloadWithFilters() called');
    print('🔄 DEBUG: Current mode: $currentMode');
    print('🔄 DEBUG: Clearing profiles list before reload...');
    profiles.clear();
    datingProfiles.clear();
    bffProfiles.clear();
    currentIndex.value = 0;
    deckVersion.value++;
    await _loadActiveProfiles();
    print('🔄 DEBUG: reloadWithFilters() completed - profiles.length: ${profiles.length}');
  }

  Future<void> _loadFiltersFromPrefs() async {
    try {
      minAge.value = SharedPreferenceHelper.getInt(_kMinAgeKey, defaultValue: 18);
      maxAge.value = SharedPreferenceHelper.getInt(_kMaxAgeKey, defaultValue: 99);
      
      // Check if user has saved a gender preference
      final savedGender = SharedPreferenceHelper.getString(_kGenderKey, defaultValue: '');
      
      if (savedGender.isEmpty) {
        // No saved preference, set default based on user's gender
        try {
          final userSummary = await SupabaseService.getCurrentUserSummary();
          final userGenderRaw = (userSummary['gender'] ?? '').toString();
          
          String defaultGender = 'Everyone';
          // Normalize user gender to lowercase for comparison
          final normalizedUserGender = userGenderRaw.toLowerCase().trim();
          
          if (normalizedUserGender == 'female') {
            defaultGender = 'Male';
          } else if (normalizedUserGender == 'male') {
            defaultGender = 'Female';
          } else if (normalizedUserGender == 'non-binary' || normalizedUserGender == 'nonbinary') {
            defaultGender = 'Non-binary';
          }
          
          gender.value = defaultGender;
          print('🔍 DEBUG: Set default gender filter to "$defaultGender" based on user gender "$normalizedUserGender"');
          
          // Save the default so it persists
          await SharedPreferenceHelper.setString(_kGenderKey, defaultGender);
        } catch (e) {
          print('❌ DEBUG: Error getting user gender, defaulting to Everyone: $e');
          gender.value = 'Everyone';
        }
      } else {
        // User has a saved preference, use it
        gender.value = savedGender;
      }
      
      maxDistanceKm.value = SharedPreferenceHelper.getInt(_kDistanceKey, defaultValue: 100).toDouble();
      
      // Clamp distance based on premium status on load
      final double currentMaxAllowed = isPremium.value ? 10726.0 : 200.0;
      if (maxDistanceKm.value > currentMaxAllowed) {
        maxDistanceKm.value = currentMaxAllowed;
        await SharedPreferenceHelper.setInt(_kDistanceKey, currentMaxAllowed.round());
      }
      
      final intents = SharedPreferenceHelper.getStringList(_kIntentsKey, defaultValue: []);
      selectedIntents.value = intents.toSet();
    } catch (e) {
      print('❌ DEBUG: Error loading filters: $e');
      // Fallback to defaults
      gender.value = 'Everyone';
    }
  }

  void resetFilters() {
    minAge.value = 18;
    maxAge.value = 99;
    gender.value = 'Everyone';
    maxDistanceKm.value = 100.0;
    selectedIntents.clear();
  }


  Future<void> saveFilters() async {
    // Clamp distance based on premium status before saving
    final double maxAllowed = isPremium.value ? 10726.0 : 200.0;
    if (maxDistanceKm.value > maxAllowed) {
      maxDistanceKm.value = maxAllowed;
    }

    await SharedPreferenceHelper.setInt(_kMinAgeKey, minAge.value);
    await SharedPreferenceHelper.setInt(_kMaxAgeKey, maxAge.value);
    await SharedPreferenceHelper.setString(_kGenderKey, gender.value);
    await SharedPreferenceHelper.setInt(_kDistanceKey, maxDistanceKm.value.round());
    await SharedPreferenceHelper.setStringList(_kIntentsKey, selectedIntents.toList());
  }

  Future<void> _ensureLocationThenLoad() async {
    try {
      // First try to get location from LocationService (SharedPreferences cache)
      var location = await LocationService.getLocationWithAutoUpdate();
      
      // If no cached location, try to get from user's profile in database
      if (location == null) {
        print('📍 DiscoverPage: No cached location, trying to get from profile...');
        final currentUserId = SupabaseService.currentUser?.id;
        if (currentUserId != null) {
          try {
            final profile = await SupabaseService.getProfile(currentUserId);
            if (profile != null) {
              final lat = (profile['latitude'] as num?)?.toDouble();
              final lon = (profile['longitude'] as num?)?.toDouble();
              if (lat != null && lon != null) {
                _userLat = lat;
                _userLon = lon;
                print('📍 DiscoverPage: Using location from profile - Lat: $_userLat, Lon: $_userLon');
                // Cache it in SharedPreferences for next time
                await SharedPreferenceHelper.setDouble('user_latitude', lat);
                await SharedPreferenceHelper.setDouble('user_longitude', lon);
              } else {
                print('📍 DiscoverPage: Profile has no location data, attempting fresh update...');
                // Try to update location in background (non-blocking)
                LocationService.updateUserLocation().catchError((e) {
                  print('❌ DiscoverPage: Background location update failed: $e');
                });
              }
            }
          } catch (e) {
            print('❌ DiscoverPage: Error getting location from profile: $e');
          }
        }
      } else {
        // Use cached location
        _userLat = location['latitude'];
        _userLon = location['longitude'];
        print('📍 DiscoverPage: Using cached location - Lat: $_userLat, Lon: $_userLon');
        
        // Still try to update location in background if it's been a while (non-blocking)
        // This ensures location stays fresh
        final lastUpdate = SharedPreferenceHelper.getString('last_location_update');
        if (lastUpdate.isNotEmpty) {
          try {
            final lastUpdateTime = DateTime.parse(lastUpdate);
            final now = DateTime.now();
            final timeDiff = now.difference(lastUpdateTime);
            // If location is older than 30 minutes, update in background
            if (timeDiff.inMinutes > 30) {
              print('📍 DiscoverPage: Location is ${timeDiff.inMinutes} minutes old, updating in background...');
              LocationService.updateUserLocation().catchError((e) {
                print('❌ DiscoverPage: Background location update failed: $e');
              });
            }
          } catch (e) {
            // Ignore parse errors, just try to update
            LocationService.updateUserLocation().catchError((_) {});
          }
        }
      }
      
      if (_userLat == null || _userLon == null) {
        print('📍 DiscoverPage: No location available, proceeding without location filter');
        // Still try to get location in background for next time
        LocationService.updateUserLocation().catchError((e) {
          print('❌ DiscoverPage: Background location update failed: $e');
        });
      }
    } catch (e) {
      print('❌ DiscoverPage: Error getting location: $e');
    }
    await _loadActiveProfiles();
  }

  /// Refresh user location and reload profiles
  Future<bool> refreshLocation() async {
    try {
      print('📍 DiscoverPage: Refreshing location...');
      
      // First request permission explicitly
      print('📍 DiscoverPage: Requesting location permission...');
      final hasPermission = await LocationService.hasLocationPermission();
      if (!hasPermission) {
        print('📍 DiscoverPage: No permission, requesting...');
        final granted = await LocationService.requestLocationPermission();
        if (!granted) {
          print('❌ DiscoverPage: Location permission denied');
          return false;
        }
      }
      
      // Force location update
      final success = await LocationService.forceLocationUpdate();
      
      if (success) {
        // Get the updated location
        final location = await LocationService.getCachedLocation();
        if (location != null) {
          _userLat = location['latitude'];
          _userLon = location['longitude'];
          print('📍 DiscoverPage: Location refreshed - Lat: $_userLat, Lon: $_userLon');
          
          // Reload profiles with new location
          await _loadActiveProfiles();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ DiscoverPage: Error refreshing location: $e');
      return false;
    }
  }

  double? _userLat;
  double? _userLon;

  Future<void> _loadActiveProfiles() async {
    print('📥📥 DEBUG: _loadActiveProfiles() proxying to refreshProfilesForMode(${currentMode.value})');
    await refreshProfilesForMode(currentMode.value);
  }

  // Load IDs to exclude from Discover: any pair with current user where status pending or matched
  Future<Set<String>> _loadExcludedUserIds() async {
    final Set<String> ids = {};
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return ids;
    try {
      if (currentMode.value == 'bff') {
        // For BFF mode, check bff_interactions table
        final bffInteractions = await SupabaseService.client
            .from('bff_interactions')
            .select('target_user_id')
            .eq('user_id', uid);
        if (bffInteractions is List) {
          for (final r in bffInteractions) {
            final other = (r['target_user_id'] ?? '').toString();
            if (other.isNotEmpty) ids.add(other);
          }
        }
      } else {
        // For dating mode, check regular swipes table (recent window only)
        final since = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
        final sw = await SupabaseService.client
            .from('swipes')
            .select('swiped_id,created_at')
            .eq('swiper_id', uid)
            .gte('created_at', since);
        if (sw is List) {
          for (final r in sw) {
            final other = (r['swiped_id'] ?? '').toString();
            if (other.isNotEmpty) ids.add(other);
          }
        }
      }

      // 2) Exclude any existing/pending matches
      final tableName = currentMode.value == 'bff' ? 'bff_matches' : 'matches';
      final rows = await SupabaseService.client
          .from(tableName)
          .select('user_id_1,user_id_2,status')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid')
          .filter('status', 'in', '(pending,matched,active)');
      if (rows is List) {
        for (final r in rows) {
          final a = (r['user_id_1'] ?? '').toString();
          final b = (r['user_id_2'] ?? '').toString();
          final other = a == uid ? b : a;
          if (other.isNotEmpty) ids.add(other);
        }
      }
    } catch (_) {}
    return ids;
  }

  String _firstImageUrl(dynamic urls) {
    String? raw;
    if (urls is List && urls.isNotEmpty) raw = urls.first.toString();
    if (urls is String && urls.isNotEmpty) raw = urls;
    if (raw != null && raw.isNotEmpty) {
      // Dev proxy for providers that block hotlinking (e.g., pixabay 403)
      try {
        final u = Uri.parse(raw);
        final host = u.host.toLowerCase();
        if (host.contains('pixabay.com') || host.contains('picsum.photos')) {
          final encoded = Uri.encodeComponent(raw);
          return 'https://images.weserv.nl/?url=$encoded&h=1200&w=900&fit=cover';
        }
        return raw;
      } catch (_) {
        return raw;
      }
    }
    return 'https://picsum.photos/seed/fallback/800/1200';
  }

  List<String> _asStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  // Simple client-side haversine distance in km
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0; // earth radius
    final double dLat = _toRad(lat2 - lat1);
    final double dLon = _toRad(lon2 - lon1);
    final double a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180.0;

  // Match functionality
  Future<bool> onSwipeLeft(Profile profile) async {
    print('🚫 SWIPE LEFT: ${profile.name} (ID: ${profile.id})');
    passedIds.add(profile.id);
    seenIds.add(profile.id);
    _processSwipeInBackground(profile, 'pass');
    return true;
  }

  Future<bool> onSwipeRight(Profile profile) async {
    print('❤️ SWIPE RIGHT: ${profile.name} (ID: ${profile.id})');
    likedIds.add(profile.id);
    seenIds.add(profile.id);
    _processSwipeInBackground(profile, 'like');
    return true;
  }

  Future<bool> onSuperLike(Profile profile) async {
    print('⭐ SUPER LIKE: ${profile.name} (ID: ${profile.id})');
    likedIds.add(profile.id);
    seenIds.add(profile.id);
    _processSwipeInBackground(profile, 'super_like');
    return true;
  }

  Future<void> _processSwipeInBackground(Profile profile, String action) async {
    try {
      await AnalyticsService.trackSwipe(action, profile.id);
      final ok = await _handleSwipe(profile, action: action, deferRemoval: true);
      if (!ok) {
        // If limit reached or error, undo the visual swipe
        undoLastSwipe();
        if (action == 'pass') passedIds.remove(profile.id);
        else likedIds.remove(profile.id);
        seenIds.remove(profile.id);
      }
    } catch (e) {
      print('Error processing swipe in background: $e');
    }
  }

  void _moveToNextCard() {
    print('🔍 DEBUG: _moveToNextCard called - currentIndex=${currentIndex.value}, profiles.length=${profiles.length}');
    
    if (currentIndex.value < profiles.length - 1) {
      currentIndex.value++;
      print('🔍 DEBUG: Moved to next card - new currentIndex=${currentIndex.value}');
      
      // Log the new current profile
      if (currentIndex.value < profiles.length) {
        final newProfile = profiles[currentIndex.value];
        print('🔍 DEBUG: New current profile - ID=${newProfile.id}, Name="${newProfile.name}", Age=${newProfile.age}');
      }
      
      // Check if we need to preload more profiles
      _checkAndPreload();
    } else {
      print('🔍 DEBUG: Reached end of profiles');
      // Don't loop back - let the user see empty state
      // Only refresh if we have no profiles left
      if (profiles.isEmpty) {
        _loadActiveProfiles();
      }
      // Force UI update to hide name overlay when no profiles
      update();
    }
  }

  void _normalizeIndex() {
    if (profiles.isEmpty) {
      currentIndex.value = 0;
    } else if (currentIndex.value >= profiles.length) {
      currentIndex.value = profiles.length - 1;
    }
  }

  Future<bool> _handleSwipe(Profile profile, {required String action, int? previousIndex, bool deferRemoval = true}) async {
    final currentUserId = SupabaseService.currentUser?.id;
    final otherId = profile.id;

    print('DEBUG: Starting swipe $action on profile $otherId by user $currentUserId (RPC path)');

    if (currentUserId == null || otherId.isEmpty) {
      print('DEBUG: Invalid user IDs, skipping swipe');
      _moveToNextCard();
      return true;
    }

    if (otherId == currentUserId) {
      print('DEBUG: Cannot swipe on yourself, skipping');
      _moveToNextCard();
      return true;
    }
  

    try {
      Map<String, dynamic> res;
      bool matched = false;
      String matchId = '';
      
      // Use mode-specific swipe handling
      // Use the proper RPC function for both dating and BFF modes
      res = await SupabaseService.handleSwipe(
        swipedId: otherId, 
        action: action, 
        mode: currentMode.value
      );
      
      // Check for freemium limits
      if (res.containsKey('limit_reached') && res['limit_reached'] == true) {
        _showLimitReachedDialog(res['error'], res['action']);
        return false;
      }
      
      matched = (res['matched'] == true);
      matchId = (res['match_id'] ?? '').toString();

      print('DEBUG: RPC ${currentMode.value == 'bff' ? 'handle_bff_swipe' : 'handle_swipe'} result matched=$matched matchId=$matchId');
      print('DEBUG: Full RPC response: $res');

      // Deck removal is handled by UI after animation to avoid desync
      if (!deferRemoval) {
        _removeProfileAndAdvance(profile);
      }

      if (matched && matchId.isNotEmpty) {
        // Track match creation
        await AnalyticsService.trackMatch(matchId, otherId);
        
        // Generate ice breakers for the new match
        _generateIceBreakersForMatch(matchId);
        
        await Future.delayed(const Duration(milliseconds: 300));
        _showMatchDialog(profile, matchId, currentMode.value);
      }
      return true;
    } catch (e) {
      print('DEBUG: RPC swipe failed, removing card anyway. Error: $e');
      // Keep deck changes deferred to UI to maintain consistency
      return true;
    }
  }

  // Client-side retry helpers removed in RPC path

  // Generate ice breakers for a new match
  Future<void> _generateIceBreakersForMatch(String matchId) async {
    try {
      print('DEBUG: Generating ice breakers for match $matchId');
      
      // Call the edge function to generate ice breakers
      final resp = await SupabaseService.client.functions.invoke(
        'generate-match-insights',
        body: {'match_id': matchId},
      );
      
      if (resp.data != null && resp.data['success'] == true) {
        print('DEBUG: Ice breakers generated successfully for match $matchId');
      } else {
        print('DEBUG: Failed to generate ice breakers for match $matchId: ${resp.data}');
      }
    } catch (e) {
      print('DEBUG: Error generating ice breakers for match $matchId: $e');
      // Don't show error to user, this is background generation
    }
  }

  void _removeProfileSafely(Profile profile) {
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (profiles.contains(profile)) {
        profiles.remove(profile); 
        _normalizeIndex();
        print('DEBUG: Profile removed safely');
        // Force UI update when profiles are removed
        update();
        deckVersion.value++;
      }
    });
  }

  // Remove profile and advance deck immediately (no delay)
  void _removeProfileAndAdvance(Profile profile) {
    final int prevIndex = profiles.indexWhere((p) => p.id == profile.id);
    if (prevIndex == -1) {
      print('🔍 DEBUG: Profile not found in list: ${profile.id}');
      return;
    }

    print('🔍 DEBUG: Removing profile at index $prevIndex: ${profile.name}');
    
    // Remove the profile immediately
    profiles.removeAt(prevIndex);
    
    // If this was the last profile being swiped, clear everything to show empty state
    if (profiles.length <= 1) {
      print('🔍 DEBUG: Last profile swiped - clearing all to show empty state');
      profiles.clear();
      currentIndex.value = 0;
      update();
      return; // Don't continue with preloading
    }
    
    // Adjust current index
    if (profiles.isEmpty) {
      currentIndex.value = 0;
      print('🔍 DEBUG: No more profiles - showing empty state');
      // Force UI update to show empty state
      update();
      return; // Don't continue with preloading if no profiles
    } else {
      // Stay at the same position if possible, otherwise move to last available
      currentIndex.value = prevIndex.clamp(0, profiles.length - 1);
      print('🔍 DEBUG: Advanced to index ${currentIndex.value}, ${profiles.length} profiles remaining');
    }
    
    // Force UI update
    update();
    deckVersion.value++;
    
    // Preload more profiles if needed
    _checkAndPreload();
  }

  // Preload remaining cards in background for optimal performance
  Future<void> _preloadRemainingCards(List<Profile> loadedProfiles) async {
    if (loadedProfiles.length <= 1) return;
    
    // Preload cards 2-5 in background (optimized order)
    final cardsToPreload = loadedProfiles.skip(1).take(4).toList();
    
    for (int i = 0; i < cardsToPreload.length; i++) {
      // Add small delay between preloads to avoid blocking UI
      await Future.delayed(Duration(milliseconds: 100 * i));
      
      // Simulate preloading (in real implementation, this would preload images)
      print('🔄 Preloading card ${i + 2}: ${cardsToPreload[i].name}');
    }
    
    print('✅ Background preloading completed for ${cardsToPreload.length} cards');
  }

  // Remove swiped card first, then set the next visible index to avoid index-shift flicker
  void _advanceDeckAfterSwipe(Profile profile) {
    final int prevIndex = profiles.indexWhere((p) => p.id == profile.id);
    if (prevIndex == -1) {
      _moveToNextCard();
      return;
    }

    print('🔍 DEBUG: _advanceDeckAfterSwipe prevIndex=$prevIndex, currentIndex=${currentIndex.value}, length=${profiles.length}');

    // Remove immediately to avoid delayed reindexing
    profiles.removeAt(prevIndex);

    // Compute the next index: stay at prevIndex unless we were at end
    if (profiles.isEmpty) {
      currentIndex.value = 0;
    } else {
      currentIndex.value = prevIndex.clamp(0, profiles.length - 1);
    }

    print('🔍 DEBUG: After remove - new length=${profiles.length}, new currentIndex=${currentIndex.value}');
    update();

    // Preload ahead if needed
    _checkAndPreload();
  }

  // Variant that uses an absolute deck index (safer with rapid swipes)
  void _advanceDeckAfterSwipeByIndex(int prevIndex, {CardSwiperDirection? direction}) {
    if (prevIndex < 0 || prevIndex >= profiles.length) {
      print('🔍 DEBUG: _advanceDeckAfterSwipeByIndex prevIndex out of range: $prevIndex');
      _moveToNextCard();
      return;
    }
    print('🔍 DEBUG: _advanceDeckAfterSwipeByIndex prevIndex=$prevIndex, currentIndex=${currentIndex.value}, length=${profiles.length}');
    
    // Store last swiped profile and direction for rewind functionality
    _lastSwipedProfile = profiles[prevIndex];
    _lastSwipedIndex = prevIndex;
    _lastSwipeDirection = direction;
    print('🔄 DEBUG: Stored last swiped profile for rewind: ${_lastSwipedProfile?.name}, direction: $direction');
    
    profiles.removeAt(prevIndex);
    if (profiles.isEmpty) {
      currentIndex.value = 0;
    } else {
      currentIndex.value = prevIndex.clamp(0, profiles.length - 1);
    }
    print('🔍 DEBUG: After remove(byIndex) - new length=${profiles.length}, new currentIndex=${currentIndex.value}');
    update();
    deckVersion.value++;
    _checkAndPreload();
  }

  // Public: finalize a swipe by removing the swiped card after animation completes
  void finalizeSwipeAtIndex(int? prevIndex, {CardSwiperDirection? direction}) {
    if (prevIndex == null) return;
    _advanceDeckAfterSwipeByIndex(prevIndex, direction: direction);
  }

  // Undo last swipe - re-insert the last swiped profile at index 0 (smooth animation)
  bool undoLastSwipe() {
    if (_lastSwipedProfile == null || _lastSwipedIndex == null) {
      print('⚠️ DEBUG: No last swiped profile to undo');
      return false;
    }
    
    final profile = _lastSwipedProfile!;
    print('🔄 DEBUG: Undoing last swipe - re-inserting ${profile.name} at index 0, direction: $_lastSwipeDirection');
    
    // Set rewind flag to trigger animation
    isRewinding.value = true;
    
    // Re-insert at index 0 for smooth animation
    profiles.insert(0, profile);
    
    // Reset indices
    currentIndex.value = 0;
    overlayIndex.value = 0;
    
    // Remove from seen/passed/liked sets so it can be swiped again
    seenIds.remove(profile.id);
    passedIds.remove(profile.id);
    likedIds.remove(profile.id);
    
    // Force UI update - this will trigger CardSwiper to rebuild
    update();
    deckVersion.value++;
    
    // Reset rewind flag after animation completes
    Future.delayed(Duration(milliseconds: 500), () {
      isRewinding.value = false;
      _lastSwipedProfile = null;
      _lastSwipedIndex = null;
      _lastSwipeDirection = null;
    });
    
    print('✅ DEBUG: Profile ${profile.name} re-inserted at index 0. Total profiles: ${profiles.length}');
    return true;
  }

  Future<void> _showMatchDialog(Profile profile, String matchId, String mode) async {
    final theme = Get.find<ThemeController>();
    String myAvatar = '';
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid != null) {
        final me = await SupabaseService.client.from('profiles').select('image_urls').eq('id', uid).maybeSingle();
        final urls = me?['image_urls'];
        if (urls is List && urls.isNotEmpty) myAvatar = urls.first.toString();
      }
    } catch (_) {}

    Get.dialog(
      Material(
        color: Colors.black.withValues(alpha: 0.15),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.96, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Transform.scale(scale: t, child: child),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.whiteColor.withValues(alpha: 0.10),
                        theme.whiteColor.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: currentMode.value == 'bff' 
                          ? theme.bffPrimaryColor.withValues(alpha: 0.35) 
                          : theme.getAccentColor().withValues(alpha: 0.35), 
                      width: 1
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentMode.value == 'bff' 
                            ? theme.bffPrimaryColor.withValues(alpha: 0.18) 
                            : theme.getAccentColor().withValues(alpha: 0.18), 
                        blurRadius: 30, 
                        offset: Offset(0, 12)
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 6.h),
                      Text(
                        currentMode.value == 'bff' ? 'Meet your new' : 'It\'s a',
                        style: TextStyle(
                          fontFamily: 'AppFont',
                          fontWeight: FontWeight.w700,
                          fontSize: currentMode.value == 'bff' ? 28.sp : 30.sp,
                          color: theme.whiteColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -18.h),
                        child: Text(
                          currentMode.value == 'bff' ? 'BFF!' : 'Match!',
                          style: GoogleFonts.dancingScript(
                            fontSize: 64.sp,
                            fontWeight: FontWeight.w700,
                            color: currentMode.value == 'bff' 
                                ? theme.bffPrimaryColor 
                                : theme.lightPinkColor,
                            shadows: [
                              Shadow(
                                color: (currentMode.value == 'bff' 
                                    ? theme.bffPrimaryColor 
                                    : theme.lightPinkColor).withValues(alpha: 0.9), 
                                blurRadius: 22
                              ),
                              Shadow(
                                color: (currentMode.value == 'bff' 
                                    ? theme.bffPrimaryColor 
                                    : theme.lightPinkColor).withValues(alpha: 0.6), 
                                blurRadius: 44
                              ),
                              Shadow(
                                color: (currentMode.value == 'bff' 
                                    ? theme.bffPrimaryColor 
                                    : theme.lightPinkColor).withValues(alpha: 0.3), 
                                blurRadius: 66
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _MatchProfileTiles(myUrl: myAvatar, otherUrl: profile.imageUrl),
                      SizedBox(height: 10.h),
                      Text(
                        currentMode.value == 'bff' 
                            ? 'You and ${profile.name} want to be friends!'
                            : 'You and ${profile.name} liked each other',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'AppFont',
                          fontSize: 16.sp,
                          color: theme.whiteColor.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.back();
                              ChatIntegrationHelper.navigateToChat(
                                userName: profile.name,
                                userImage: profile.imageUrl,
                                matchId: matchId,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                gradient: LinearGradient(
                                  colors: currentMode.value == 'bff'
                                      ? [theme.bffPrimaryColor, theme.bffSecondaryColor]
                                      : [theme.lightPinkColor, theme.purpleColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: currentMode.value == 'bff'
                                        ? theme.bffPrimaryColor.withValues(alpha: 0.4)
                                        : theme.lightPinkColor.withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Flexible(
                                    child: Text(
                                      'Start Fire Love Chat (5:00)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'AppFont',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                color: theme.whiteColor.withValues(alpha: 0.06),
                                border: Border.all(
                                  color: currentMode.value == 'bff'
                                      ? theme.bffPrimaryColor.withValues(alpha: 0.35)
                                      : theme.lightPinkColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                'Keep browsing',
                                style: TextStyle(
                                  fontFamily: 'AppFont',
                                  color: theme.whiteColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Removed floating hearts for a cleaner look
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  Profile? get currentProfile {
    if (profiles.isEmpty || currentIndex.value >= profiles.length) {
      print('🔍 DEBUG: currentProfile is null - profiles.length=${profiles.length}, currentIndex=${currentIndex.value}');
      return null;
    }
    final profile = profiles[currentIndex.value];
    print('🔍 DEBUG: currentProfile - Index=${currentIndex.value}, ID=${profile.id}, Name="${profile.name}", Age=${profile.age}');
    return profile;
  }

  // Preload next batch of profiles in background
  Future<void> _preloadNextBatch() async {
    try {
      // Only preload if we have less than 10 profiles remaining
      if (profiles.length - currentIndex.value < 10) {
        print('🔄 Preloading next batch...');
        
        final currentUserId = SupabaseService.currentUser?.id;
        if (currentUserId == null) return;
        
        final Set<String> excludedIds = await _loadExcludedUserIds();
        
        // Use mode-specific profile loading
        List<Map<String, dynamic>> rows;
        if (currentMode.value == 'bff') {
          // For BFF mode, don't preload more - BFF profiles are limited
          print('🔍 DEBUG: BFF mode - not preloading more profiles');
          return;
        } else {
          rows = await SupabaseService.getProfiles(limit: 10, offset: profiles.length);
        }
        
        final loaded = rows
            .where((r) {
              final id = (r['id'] ?? '').toString();
              if (id.isEmpty || id == currentUserId) return false;
              if (excludedIds.contains(id)) return false;
              return true;
            })
            .where((r) {
              final age = (r['age'] ?? 0) as int;
              if (age < minAge.value || age > maxAge.value) return false;
              if (gender.value != 'Everyone') {
                final g = (r['gender'] ?? '').toString();
                if (g.isNotEmpty && g.toLowerCase() != gender.value.toLowerCase()) return false;
              }
              return true;
            })
            .where((r) {
              if (_userLat == null || _userLon == null || maxDistanceKm.value <= 0) return true;
              final lat = (r['latitude'] as num?)?.toDouble();
              final lon = (r['longitude'] as num?)?.toDouble();
              if (lat == null || lon == null) return true;
              final d = _haversineKm(_userLat!, _userLon!, lat, lon);
              return d <= maxDistanceKm.value;
            })
            .map((r) {
              List<String> photos = _asStringList(r['image_urls']);
              if (photos.isEmpty) photos = _asStringList(r['photos']);
              
              // Add fallback image if no photos available
              if (photos.isEmpty) {
                photos = ['https://picsum.photos/seed/${r['id']}/800/1200'];
                print('🖼️ No photos found for ${r['name']}, using fallback image');
              }
              
            return Profile(
                id: (r['id'] ?? '').toString(),
                name: (r['name'] ?? '').toString(),
                age: (r['age'] ?? 0) as int,
                imageUrl: _firstImageUrl(photos.isNotEmpty ? photos.first : r['image_url']),
                photos: photos,
                location: (r['location'] ?? '').toString(),
                distance: _userLat != null && _userLon != null
                    ? '${_haversineKm(_userLat!, _userLon!, (r['latitude'] as num?)?.toDouble() ?? 0, (r['longitude'] as num?)?.toDouble() ?? 0).round()} miles away'
                    : 'Unknown distance',
                description: (r['bio'] ?? r['description'] ?? '').toString(),
                hobbies: _asStringList(r['interests'] ?? r['hobbies'] ?? []),
                isVerified: true,
                isActiveNow: true,
              );
            })
            .toList();

        // Filter: only displayable profiles (non-empty name and at least one photo/image)
        final displayable = loaded.where((p) {
          final hasName = p.name.toString().trim().isNotEmpty;
          final hasPhoto = p.imageUrl.isNotEmpty || p.photos.isNotEmpty;
          return hasName && hasPhoto;
        }).toList();

        if (displayable.isNotEmpty) {
          // Strong de-dupe against existing deck and within this preload batch
          final Set<String> existing = profiles.map((p) => p.id).toSet();
          final Set<String> seenBatch = <String>{};
          final List<Profile> uniques = [];
          for (final p in displayable) {
            if (existing.contains(p.id)) continue;
            if (seenBatch.contains(p.id)) continue;
            seenBatch.add(p.id);
            uniques.add(p);
          }
          if (uniques.isNotEmpty) {
            profiles.addAll(uniques);
          }
          preloadedCount.value = profiles.length;
          print('✅ Preloaded ${uniques.length} more profiles. Total: ${profiles.length}');
        } else {
          print('🔍 DEBUG: No displayable profiles to preload');
        }
      }
    } catch (e) {
      print('❌ Preloading failed: $e');
    }
  }

  // Trigger preloading when user is near the end
  void _checkAndPreload() {
    // Only preload if we have more than 3 profiles left and not already loading
    // AND we haven't reached the maximum limit to prevent infinite loading
    if (currentIndex.value >= profiles.length - 5 && 
        !isPreloading.value && 
        profiles.length < 50) {
      _preloadNextBatch();
    }
  }

  // Show limit reached dialog
  void _showLimitReachedDialog(String error, String action) {
    final themeController = Get.find<ThemeController>();
    final bool isBffMode = currentMode.value == 'bff';
    final Color accent = isBffMode
        ? themeController.bffPrimaryColor
        : themeController.getAccentColor();
    final Color secondaryAccent = isBffMode
        ? themeController.bffSecondaryColor
        : themeController.getSecondaryColor();

    Widget content;
    if (action == 'swipe') {
      content = SwipeLimitWidget(
        onUpgrade: () {
          Get.back();
          Get.to(() => SubscriptionScreen());
        },
        onDismiss: () => Get.back(),
      );
    } else if (action == 'super_like') {
      content = SuperLikeLimitWidget(
        onUpgrade: () {
          Get.back();
          Get.to(() => SubscriptionScreen());
        },
        onBuyMore: () {
          Get.back();
          // TODO: implement super like purchase flow
          showCustomSnackBar(
            title: 'super_loves'.tr,
            message: 'super_love_purchase_coming_soon'.tr,
          );
        },
        onDismiss: () => Get.back(),
      );
    } else {
      content = UpgradePromptWidget(
        title: 'limit_reached'.tr,
        message: error,
        action: 'Upgrade Now',
        limitType: 'swipe',
        gradientColors: [
          accent.withValues(alpha: 0.2),
          secondaryAccent.withValues(alpha: 0.22),
          themeController.blackColor.withValues(alpha: 0.85),
        ],
        onUpgrade: () {
          Get.back();
          Get.to(() => SubscriptionScreen());
        },
        onDismiss: () => Get.back(),
      );
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.24),
                    accent.withValues(alpha: 0.18),
                    secondaryAccent.withValues(alpha: 0.16),
                  ],
                ),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

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
  final bool isSuperLiked;
  final bool isPremium;
  final String? gender;
  final String? matchId;
  final String? intent; // User's intent/tag
  final bool isUnlocked; // Chat-first feature: profile unlocked after conversation
  bool get isLocked => !isUnlocked;
  final int conversationMessageCount; // Number of messages exchanged

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
    this.isVerified = false,
    this.isActiveNow = false,
    this.isSuperLiked = false,
    this.isPremium = false,
    this.gender,
    this.matchId,
    this.intent,
    this.isUnlocked = false,
    this.conversationMessageCount = 0,
  });
}

// Helper widgets for the Match dialog
class _AnimatedAvatar extends StatelessWidget {
  final String url;
  final Alignment align;
  const _AnimatedAvatar({required this.url, required this.align});

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = Get.find<ThemeController>();
    return Align(
      alignment: align,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Transform.scale(scale: t, child: child),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.lightPinkColor.withValues(alpha: 0.6), width: 2),
            boxShadow: [BoxShadow(color: theme.lightPinkColor.withValues(alpha: 0.2), blurRadius: 12)],
          ),
          clipBehavior: Clip.antiAlias,
          child: url.isNotEmpty
              ? Image.network(url, fit: BoxFit.cover)
              : Container(color: theme.whiteColor.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}

class _PulsingHeart extends StatefulWidget {
  final Color color;
  const _PulsingHeart({required this.color});

  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.05)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 16),
          ],
        ),
        child: Icon(Icons.favorite, color: Colors.white, size: 16.sp),
      ),
    );
  }
}

class _FloatingHearts extends StatelessWidget {
  final Color color;
  const _FloatingHearts({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(6, (i) {
        final delay = 200 * i;
        final startY = 40.0 + (i * 12);
        final startX = 0.2 + (i * 0.12);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 1200 + delay),
          builder: (context, t, child) => Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset((startX - 0.5) * 120 * (1 - t), -t * 60 - startY),
              child: Align(
                alignment: Alignment(startX.clamp(0.0, 1.0), 1),
                child: Icon(
                  Icons.favorite,
                  size: 12 + i.toDouble(),
                  color: color.withOpacity(0.4),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MatchProfileTiles extends StatelessWidget {
  final String myUrl;
  final String otherUrl;
  const _MatchProfileTiles({required this.myUrl, required this.otherUrl});

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = Get.find<ThemeController>();
    final DiscoverController discoverController = Get.find<DiscoverController>();
    return SizedBox(
      height: 130.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: my avatar (rounded square)
          _FadeSlide(
            delayMs: 0,
            child: Transform.translate(
              offset: Offset(-35.w, 12.h),
              child: Transform.rotate(
                angle: -8 * 3.14159 / 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: SizedBox(
                    width: 90.w,
                    height: 90.w,
                    child: myUrl.isNotEmpty
                        ? Image.network(myUrl, fit: BoxFit.cover)
                        : Container(color: theme.whiteColor.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            ),
          ),
          // Right: other avatar (rounded rectangle, slightly larger & higher)
          _FadeSlide(
            delayMs: 100,
            child: Transform.translate(
              offset: Offset(40.w, -6.h),
              child: Transform.rotate(
                angle: 6 * 3.14159 / 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: SizedBox(
                    width: 96.w,
                    height: 120.h,
                    child: otherUrl.isNotEmpty
                        ? Image.network(otherUrl, fit: BoxFit.cover)
                        : Container(color: theme.whiteColor.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            ),
          ),
          // Heart/Friend icon at the inner-btm intersection
          Transform.translate(
            offset: Offset(5.w, 25.h),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: discoverController.currentMode.value == 'bff' 
                    ? theme.bffPrimaryColor 
                    : theme.lightPinkColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: discoverController.currentMode.value == 'bff' 
                        ? theme.bffPrimaryColor.withValues(alpha: 0.35) 
                        : theme.lightPinkColor.withValues(alpha: 0.35), 
                    blurRadius: 14
                  )
                ],
              ),
              child: Icon(
                discoverController.currentMode.value == 'bff' 
                    ? Icons.people 
                    : Icons.favorite, 
                color: theme.whiteColor, 
                size: 18.sp
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _FadeSlide({required this.child, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, t, _) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 10), child: child),
      ),
      onEnd: () {},
    );
  }
}
