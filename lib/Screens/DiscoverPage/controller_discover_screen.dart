import 'package:get/get.dart';
import 'package:boliler_plate/services/supabase_service.dart';
import 'package:boliler_plate/Screens/ChatPage/ui_message_screen.dart';
import 'package:boliler_plate/ThemeController/theme_controller.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:boliler_plate/shared_prefrence_helper.dart';
import 'package:collection/collection.dart';

class DiscoverController extends GetxController {
  // Feature flags
  static const bool useSupabaseProfiles = true;

  final profiles = <Profile>[].obs;
  final currentIndex = 0.obs;
  // Filters
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 99.obs;
  final RxString gender = 'Everyone'.obs; // Male, Female, Non-binary, Everyone
  final RxDouble maxDistanceKm = 100.0.obs;
  final RxString intent = 'Everyone'.obs; // legacy single intent
  final RxSet<String> selectedIntents = <String>{}.obs; // Casual, Serious, Just Chatting

  // Prefs keys
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
    _loadFiltersFromPrefs();
    _ensureLocationThenLoad();
  }

  Future<void> reloadWithFilters() async {
    await _loadActiveProfiles();
  }

  void _loadFiltersFromPrefs() {
    try {
      minAge.value = SharedPreferenceHelper.getInt(_kMinAgeKey, defaultValue: 18);
      maxAge.value = SharedPreferenceHelper.getInt(_kMaxAgeKey, defaultValue: 99);
      gender.value = SharedPreferenceHelper.getString(_kGenderKey, defaultValue: 'Everyone');
      maxDistanceKm.value = SharedPreferenceHelper.getInt(_kDistanceKey, defaultValue: 100).toDouble();
      final intents = SharedPreferenceHelper.getStringList(_kIntentsKey, defaultValue: []);
      selectedIntents.value = intents.toSet();
    } catch (_) {}
  }

  Future<void> saveFilters() async {
    await SharedPreferenceHelper.setInt(_kMinAgeKey, minAge.value);
    await SharedPreferenceHelper.setInt(_kMaxAgeKey, maxAge.value);
    await SharedPreferenceHelper.setString(_kGenderKey, gender.value);
    await SharedPreferenceHelper.setInt(_kDistanceKey, maxDistanceKm.value.round());
    await SharedPreferenceHelper.setStringList(_kIntentsKey, selectedIntents.toList());
  }

  Future<void> _ensureLocationThenLoad() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // proceed without location
        await _loadActiveProfiles();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        await _loadActiveProfiles();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _userLat = pos.latitude;
      _userLon = pos.longitude;
    } catch (_) {}
    await _loadActiveProfiles();
  }

  double? _userLat;
  double? _userLon;

  Future<void> _loadActiveProfiles() async {
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      final Set<String> excludedIds = await _loadExcludedUserIds();
      // For now, client-side filtering after fetch; can move to RPC later
      final rows = await SupabaseService.getProfiles();

      final loaded = rows
          .where((r) {
            final id = (r['id'] ?? '').toString();
            if (id.isEmpty) return false;
            if (currentUserId != null && id == currentUserId) return false;
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
            // Intent matching is optional in MVP until schema holds it; skip if not present
            if (selectedIntents.isNotEmpty) {
              final i = (r['intent'] ?? '').toString();
              if (i.isNotEmpty && !selectedIntents.map((e) => e.toLowerCase()).contains(i.toLowerCase())) return false;
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
            // photos/image_urls support
            List<String> photos = _asStringList(r['photos']);
            if (photos.isEmpty) photos = _asStringList(r['image_urls']);
            return Profile(
              id: (r['id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
              age: (r['age'] ?? 0) as int,
              imageUrl: photos.isNotEmpty ? photos.first : _firstImageUrl(null),
              photos: photos,
              location: (r['location'] ?? '').toString(),
              distance: '',
              description: (r['bio'] ?? r['description'] ?? '').toString(),
              hobbies: _asStringList(r['interests'] ?? r['hobbies'] ?? []),
              isVerified: true,
              isActiveNow: true,
            );
          })
          .toList();
      profiles.assignAll(loaded);
    } catch (_) {
      // fallback to embedded dummy list; no-op
    }
  }

  // Load IDs to exclude from Discover: any pair with current user where status pending or matched
  Future<Set<String>> _loadExcludedUserIds() async {
    final Set<String> ids = {};
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return ids;
    try {
      // 1) Exclude any users we've already swiped on (any action)
      final sw = await SupabaseService.client
          .from('swipes')
          .select('swiped_id')
          .eq('swiper_id', uid);
      if (sw is List) {
        for (final r in sw) {
          final other = (r['swiped_id'] ?? '').toString();
          if (other.isNotEmpty) ids.add(other);
        }
      }

      // 2) Exclude any existing/pending matches
      final rows = await SupabaseService.client
          .from('matches')
          .select('user_id_1,user_id_2,status')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid')
          .filter('status', 'in', '(pending,matched)');
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
        if (host.contains('pixabay.com')) {
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
    if (v is List) return v.map((e) => e.toString()).toList();
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
  Future<void> onSwipeLeft(Profile profile) async {
    // Record a pass so the same card will not reappear later
    await _handleSwipe(profile, action: 'pass');
  }

  Future<void> onSwipeRight(Profile profile) async {
    // Like via server-side RPC to guarantee atomic swipe+match
    await _handleSwipe(profile, action: 'like');
  }

  Future<void> onSuperLike(Profile profile) async {
    await _handleSwipe(profile, action: 'super_like');
  }

  void _moveToNextCard() {
    if (currentIndex.value < profiles.length - 1) {
      currentIndex.value++;
    } else {
      // Reset to first card when reaching the end
      currentIndex.value = 0;
      // Refresh feed when we loop, to avoid stale/self cards
      _loadActiveProfiles();
    }
  }

  void _normalizeIndex() {
    if (profiles.isEmpty) {
      currentIndex.value = 0;
    } else if (currentIndex.value >= profiles.length) {
      currentIndex.value = profiles.length - 1;
    }
  }

  Future<void> _handleSwipe(Profile profile, {required String action}) async {
    final currentUserId = SupabaseService.currentUser?.id;
    final otherId = profile.id;

    print('DEBUG: Starting swipe $action on profile $otherId by user $currentUserId (RPC path)');

    if (currentUserId == null || otherId.isEmpty) {
      print('DEBUG: Invalid user IDs, skipping swipe');
      _moveToNextCard();
      _removeProfileSafely(profile);
      return;
    }

    if (otherId == currentUserId) {
      print('DEBUG: Cannot swipe on yourself, skipping');
      _moveToNextCard();
      _removeProfileSafely(profile);
      return;
    }
  

    try {
      // Use server-side atomic RPC that upserts swipe and creates ordered match
      final res = await SupabaseService.handleSwipe(swipedId: otherId, action: action);
      final bool matched = (res['matched'] == true);
      final String matchId = (res['match_id'] ?? '').toString();

      print('DEBUG: RPC handle_swipe result matched=$matched matchId=$matchId');
      print('DEBUG: Full RPC response: $res');

      // Swipe recorded regardless of match; proceed to next card
      _moveToNextCard();
      _removeProfileSafely(profile);

      if (matched && matchId.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showMatchDialog(profile, matchId);
      }
    } catch (e) {
      print('DEBUG: RPC swipe failed, keeping card. Error: $e');
      // Keep profile in deck so user can retry
    }
  }

  // Client-side retry helpers removed in RPC path

  void _removeProfileSafely(Profile profile) {
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (profiles.contains(profile)) {
        profiles.remove(profile); 
        _normalizeIndex();
        print('DEBUG: Profile removed safely');
      }
    });
  }

  Future<void> _showMatchDialog(Profile profile, String matchId) async {
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
                    border: Border.all(color: theme.lightPinkColor.withValues(alpha: 0.35), width: 1),
                    boxShadow: [
                      BoxShadow(color: theme.lightPinkColor.withValues(alpha: 0.18), blurRadius: 30, offset: Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 6.h),
                      Text(
                        'It\'s a',
                        style: TextStyle(
                          fontFamily: 'AppFont',
                          fontWeight: FontWeight.w700,
                          fontSize: 30.sp,
                          color: theme.whiteColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -18.h),
                        child: Text(
                          'Match!',
                          style: GoogleFonts.dancingScript(
                            fontSize: 64.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.lightPinkColor,
                            shadows: [
                              Shadow(color: theme.lightPinkColor.withValues(alpha: 0.9), blurRadius: 22),
                              Shadow(color: theme.lightPinkColor.withValues(alpha: 0.6), blurRadius: 44),
                              Shadow(color: theme.lightPinkColor.withValues(alpha: 0.3), blurRadius: 66),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _MatchProfileTiles(myUrl: myAvatar, otherUrl: profile.imageUrl),
                      SizedBox(height: 10.h),
                      Text(
                        'You and ${profile.name} liked each other',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'AppFont',
                          fontSize: 16.sp,
                          color: theme.whiteColor.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.back();
                              Get.to(() => MessageScreen(userName: profile.name, userImage: profile.imageUrl, matchId: matchId));
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                gradient: LinearGradient(colors: [theme.lightPinkColor, theme.purpleColor]),
                                boxShadow: [
                                  BoxShadow(color: theme.lightPinkColor.withValues(alpha: 0.4), blurRadius: 14, offset: Offset(0, 6)),
                                ],
                              ),
                              child: Text('Send message', style: TextStyle(fontFamily: 'AppFont', color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                color: theme.whiteColor.withValues(alpha: 0.06),
                                border: Border.all(color: theme.lightPinkColor.withValues(alpha: 0.35)),
                              ),
                              child: Text('Keep browsing', style: TextStyle(fontFamily: 'AppFont', color: theme.whiteColor, fontWeight: FontWeight.w600)),
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
    if (profiles.isEmpty || currentIndex.value >= profiles.length) return null;
    return profiles[currentIndex.value];
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
    return SizedBox(
      height: 130.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: my avatar (rounded square)
          _FadeSlide(
            delayMs: 0,
            child: Transform.translate(
              offset: Offset(-28.w, 12.h),
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
              offset: Offset(30.w, -6.h),
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
          // Heart chip at the inner-btm intersection
          Transform.translate(
            offset: Offset(10.w, 18.h),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: theme.lightPinkColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: theme.lightPinkColor.withValues(alpha: 0.35), blurRadius: 14)],
              ),
              child: Icon(Icons.favorite, color: theme.whiteColor, size: 18.sp),
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
