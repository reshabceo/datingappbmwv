import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
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

      // Clean up expired stories first
      await _cleanupExpiredStories();

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
      
      // Always include SS (BFF chat story) - special user ID
      const ssUserId = 'c1ffb3e0-0e25-4176-9736-0db8522fd357';
      matchedUserIds.add(ssUserId);
      
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
              .select('id,name,photos,image_urls')
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

        // Check if story is expired (runtime check)
        final expiresAt = DateTime.tryParse((row['expires_at'] ?? '').toString());
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          print('⏭️ DEBUG: Skipping expired story: ${row['id']} (expired at: $expiresAt)');
          continue;
        }

        // Only include stories from matched users or current user
        if (!matchedUserIds.contains(storyUserId)) continue;

        final profile = idToProfile[storyUserId];
        final List photos = (profile?['photos'] ?? []) as List? ?? [];
        final List imageUrls = (profile?['image_urls'] ?? []) as List? ?? [];
        
        // Debug logging for profile pictures
        print('🔄 DEBUG: Story user $storyUserId - photos: $photos, image_urls: $imageUrls');
        print('🔄 DEBUG: Profile data for $storyUserId: ${profile?.toString()}');
        
        // Try both photos and image_urls fields
        String avatarUrl = '';
        if (photos.isNotEmpty) {
          avatarUrl = photos.first.toString();
          print('🔄 DEBUG: Using photos field for $storyUserId: $avatarUrl');
        } else if (imageUrls.isNotEmpty) {
          avatarUrl = imageUrls.first.toString();
          print('🔄 DEBUG: Using image_urls field for $storyUserId: $avatarUrl');
        } else {
          print('❌ DEBUG: No photos or image_urls found for $storyUserId');
        }
        
        print('🔄 DEBUG: Final avatarUrl for $storyUserId: "$avatarUrl" (length: ${avatarUrl.length})');

        final story = StoryItem(
          id: (row['id'] ?? '').toString(),
          userId: storyUserId,
          userName: StringUtils.formatName((profile?['name'] ?? 'User').toString()),
          avatarUrl: avatarUrl,
          mediaUrl: (row['media_url'] ?? '').toString(),
          content: (row['content'] ?? '').toString().isNotEmpty ? (row['content'] ?? '').toString() : null,
          timeLabel: _timeAgo((row['created_at'] ?? '').toString()),
          postedAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
        );

        groupedStories.putIfAbsent(storyUserId, () => []);
        groupedStories[storyUserId]!.add(story);
      }
      
      print('DEBUG: Grouped stories for ${groupedStories.length} users');
      
      // Convert to StoryGroup objects and sort by most recent
      final groups = groupedStories.entries
          .where((entry) => entry.value.isNotEmpty) // Only include users with stories
          .map((entry) {
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
      
      // Do NOT add SS placeholder group if there are no stories
      
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
      // TODO: Remove this in production
      // _addDummyStories(); // DISABLED: Dummy stories cause match issues
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

  Future<void> addStory(String mediaUrl, {String? content}) async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      
      final expiresAt = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
      final result = await SupabaseService.client.from('stories').insert({
        'user_id': uid,
        'media_url': mediaUrl,
        'content': content,
        'expires_at': expiresAt,
      }).select().single();
      
      // Track story posted analytics
      await AnalyticsService.trackStoryPosted(
        result['id'].toString(),
        'image', // Assuming image for now
      );
      
      await loadStories();
    } catch (e) {
      print('Error adding story: $e');
    }
  }

  void removeStoryFromGroup(int groupIndex, int storyIndex) {
    try {
      if (groupIndex < storyGroups.length && 
          storyIndex < storyGroups[groupIndex].stories.length) {
        storyGroups[groupIndex].stories.removeAt(storyIndex);
        
        // If no stories left in this group, remove the entire group
        if (storyGroups[groupIndex].stories.isEmpty) {
          storyGroups.removeAt(groupIndex);
        }
        
        print('✅ DEBUG: Story removed from controller - group: $groupIndex, story: $storyIndex');
      }
    } catch (e) {
      print('❌ DEBUG: Error removing story from controller: $e');
    }
  }

  void removeStoryById(String storyId) {
    try {
      print('🔄 DEBUG: Removing story by ID: $storyId');
      
      // Find the story group and story index
      for (int groupIndex = 0; groupIndex < storyGroups.length; groupIndex++) {
        final group = storyGroups[groupIndex];
        final storyIndex = group.stories.indexWhere((story) => story.id == storyId);
        
        if (storyIndex >= 0) {
          print('🔄 DEBUG: Found story in group $groupIndex, story $storyIndex');
          
          // Create a new list without the deleted story
          final updatedStories = List<StoryItem>.from(group.stories);
          updatedStories.removeAt(storyIndex);
          
          if (updatedStories.isEmpty) {
            // If no stories left in this group, remove the entire group
            storyGroups.removeAt(groupIndex);
            print('✅ DEBUG: Removed empty story group');
          } else {
            // Create a new StoryGroup with updated stories list
            final updatedGroup = StoryGroup(
              userId: group.userId,
              userName: group.userName,
              avatarUrl: group.avatarUrl,
              stories: updatedStories,
              hasUnviewed: group.hasUnviewed,
            );
            
            // Replace the old group with the new one
            storyGroups[groupIndex] = updatedGroup;
            print('✅ DEBUG: Updated story group with ${updatedStories.length} stories');
          }
          
          return; // Story found and removed
        }
      }
      
      print('❌ DEBUG: Story not found in any group');
    } catch (e) {
      print('❌ DEBUG: Error removing story by ID: $e');
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

  Future<void> _cleanupExpiredStories() async {
    try {
      print('🔄 DEBUG: Cleaning up expired stories...');
      final result = await SupabaseService.client
          .from('stories')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());
      
      print('✅ DEBUG: Cleaned up expired stories: $result');
    } catch (e) {
      print('❌ DEBUG: Error cleaning up expired stories: $e');
    }
  }
  
  // Track story view
  Future<void> trackStoryView(String storyId, String storyUserId) async {
    try {
      await AnalyticsService.trackStoryViewed(storyId, storyUserId);
    } catch (e) {
      print('Error tracking story view: $e');
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
  final String? content;
  final String timeLabel;
  final DateTime postedAt;

  StoryItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.mediaUrl,
    this.content,
    required this.timeLabel,
    required this.postedAt,
  });
}
