import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../utils/string_utils.dart';

class StoriesController extends GetxController {
  final RxList<StoryGroup> storyGroups = <StoryGroup>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStories();
  }

  Future<void> loadStories() async {
    try {
      isLoading.value = true;
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) {
        storyGroups.clear();
        return;
      }

      // Get all active stories (without join)
      final rows = await SupabaseService.getActiveStories();
      print('DEBUG: Found ${rows.length} total active stories');
      print('DEBUG: Stories data: $rows');
      
      // Get matched user IDs
      final matches = await SupabaseService.getMatches();
      final matchedUserIds = <String>{};
      for (final match in matches) {
        final userId1 = (match['user_id_1'] ?? '').toString();
        final userId2 = (match['user_id_2'] ?? '').toString();
        if (userId1 == currentUserId) {
          matchedUserIds.add(userId2);
        } else if (userId2 == currentUserId) {
          matchedUserIds.add(userId1);
        }
      }
      
      // Always include current user's own stories
      matchedUserIds.add(currentUserId);
      
      print('DEBUG: Matched user IDs: $matchedUserIds');
      
      // Group stories by user, but only for matched users
      final Map<String, List<StoryItem>> groupedStories = {};
      
      // Preload needed profiles for matched users (joinless)
      final neededIds = rows
          .map((r) => (r['user_id'] ?? '').toString())
          .where((id) => id.isNotEmpty && matchedUserIds.contains(id))
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> idToProfile = {};
      if (neededIds.isNotEmpty) {
        try {
          final prows = await SupabaseService.client
              .from('profiles')
              .select('id,name,photos')
              .inFilter('id', neededIds);
          if (prows is List) {
            for (final p in prows) {
              final pid = (p['id'] ?? '').toString();
              idToProfile[pid] = (p as Map).cast<String, dynamic>();
            }
          }
        } catch (_) {}
      }

      for (final row in rows) {
        final storyUserId = (row['user_id'] ?? '').toString();

        // Only include stories from matched users or current user
        if (!matchedUserIds.contains(storyUserId)) continue;

        final profile = idToProfile[storyUserId];
        final List photos = (profile?['photos'] ?? []) as List? ?? [];

        final story = StoryItem(
          id: (row['id'] ?? '').toString(),
          userId: storyUserId,
          userName: StringUtils.formatName((profile?['name'] ?? 'User').toString()),
          avatarUrl: photos.isNotEmpty ? photos.first.toString() : '',
          mediaUrl: (row['media_url'] ?? '').toString(),
          timeLabel: _timeAgo((row['created_at'] ?? '').toString()),
          postedAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
        );

        groupedStories.putIfAbsent(storyUserId, () => []);
        groupedStories[storyUserId]!.add(story);
      }
      
      print('DEBUG: Grouped stories for ${groupedStories.length} users');
      
      // Convert to StoryGroup objects and sort by most recent
      final groups = groupedStories.entries.map((entry) {
        final stories = entry.value;
        stories.sort((a, b) => b.postedAt.compareTo(a.postedAt));
        
        return StoryGroup(
          userId: entry.key,
          userName: StringUtils.formatName(stories.first.userName),
          avatarUrl: stories.first.avatarUrl,
          stories: stories,
          hasUnviewed: true, // TODO: Implement viewed tracking
        );
      }).toList();
      
      // Sort groups by most recent story, but prioritize current user's stories
      groups.sort((a, b) {
        // Current user's stories come first
        if (a.userId == currentUserId && b.userId != currentUserId) return -1;
        if (b.userId == currentUserId && a.userId != currentUserId) return 1;
        // Then sort by most recent
        return b.stories.first.postedAt.compareTo(a.stories.first.postedAt);
      });
      
      storyGroups.assignAll(groups);
      print('DEBUG: Final story groups count: ${groups.length}');
      
      // Add dummy stories for testing UI (after real stories are loaded)
      _addDummyStories();
    } catch (e) {
      print('Error loading stories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _timeAgo(String postedAtIso) {
    try {
      final dt = DateTime.tryParse(postedAtIso);
      if (dt == null) return '';
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} h ago';
      return '${diff.inDays} d ago';
    } catch (_) {
      return '';
    }
  }

  Future<void> addStory(String mediaUrl) async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      
      final expiresAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
      await SupabaseService.client.from('stories').insert({
        'user_id': uid,
        'media_url': mediaUrl,
        'expires_at': expiresAt,
      });
      
      await loadStories();
    } catch (e) {
      print('Error adding story: $e');
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await SupabaseService.client.from('stories').delete().eq('id', storyId);
      await loadStories();
    } catch (e) {
      print('Error deleting story: $e');
    }
  }

  void _addDummyStories() {
    // Add dummy story groups for testing UI
    final dummyStories = [
      StoryGroup(
        userId: 'dummy_user_1',
        userName: StringUtils.formatName('Emma'),
        avatarUrl: 'https://picsum.photos/200/200?random=1',
        stories: [
          StoryItem(
            id: 'dummy_story_1',
            userId: 'dummy_user_1',
            userName: StringUtils.formatName('Emma'),
            avatarUrl: 'https://picsum.photos/200/200?random=1',
            mediaUrl: 'https://picsum.photos/400/600?random=10',
            timeLabel: '2h ago',
            postedAt: DateTime.now().subtract(Duration(hours: 2)),
          ),
          StoryItem(
            id: 'dummy_story_2',
            userId: 'dummy_user_1',
            userName: StringUtils.formatName('Emma'),
            avatarUrl: 'https://picsum.photos/200/200?random=1',
            mediaUrl: 'https://picsum.photos/400/600?random=11',
            timeLabel: '4h ago',
            postedAt: DateTime.now().subtract(Duration(hours: 4)),
          ),
        ],
        hasUnviewed: true,
      ),
      StoryGroup(
        userId: 'dummy_user_2',
        userName: StringUtils.formatName('Alex'),
        avatarUrl: 'https://picsum.photos/200/200?random=2',
        stories: [
          StoryItem(
            id: 'dummy_story_3',
            userId: 'dummy_user_2',
            userName: StringUtils.formatName('Alex'),
            avatarUrl: 'https://picsum.photos/200/200?random=2',
            mediaUrl: 'https://picsum.photos/400/600?random=12',
            timeLabel: '1h ago',
            postedAt: DateTime.now().subtract(Duration(hours: 1)),
          ),
        ],
        hasUnviewed: true,
      ),
      StoryGroup(
        userId: 'dummy_user_3',
        userName: StringUtils.formatName('Sophia'),
        avatarUrl: 'https://picsum.photos/200/200?random=3',
        stories: [
          StoryItem(
            id: 'dummy_story_4',
            userId: 'dummy_user_3',
            userName: StringUtils.formatName('Sophia'),
            avatarUrl: 'https://picsum.photos/200/200?random=3',
            mediaUrl: 'https://picsum.photos/400/600?random=13',
            timeLabel: '30m ago',
            postedAt: DateTime.now().subtract(Duration(minutes: 30)),
          ),
          StoryItem(
            id: 'dummy_story_5',
            userId: 'dummy_user_3',
            userName: StringUtils.formatName('Sophia'),
            avatarUrl: 'https://picsum.photos/200/200?random=3',
            mediaUrl: 'https://picsum.photos/400/600?random=14',
            timeLabel: '1d ago',
            postedAt: DateTime.now().subtract(Duration(days: 1)),
          ),
          StoryItem(
            id: 'dummy_story_6',
            userId: 'dummy_user_3',
            userName: StringUtils.formatName('Sophia'),
            avatarUrl: 'https://picsum.photos/200/200?random=3',
            mediaUrl: 'https://picsum.photos/400/600?random=15',
            timeLabel: '2d ago',
            postedAt: DateTime.now().subtract(Duration(days: 2)),
          ),
        ],
        hasUnviewed: true,
      ),
    ];

    // Add dummy stories to existing story groups
    storyGroups.addAll(dummyStories);
    print('DEBUG: Added ${dummyStories.length} dummy story groups for testing');
  }
}

class StoryGroup {
  final String userId;
  final String userName;
  final String avatarUrl;
  final List<StoryItem> stories;
  final bool hasUnviewed;

  StoryGroup({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.stories,
    required this.hasUnviewed,
  });
}

class StoryItem {
  final String id;
  final String userId;
  final String userName;
  final String avatarUrl;
  final String mediaUrl;
  final String timeLabel;
  final DateTime postedAt;

  StoryItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.mediaUrl,
    required this.timeLabel,
    required this.postedAt,
  });
}
