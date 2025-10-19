# Activity Feed - Complete Implementation Plan

## Current Status
✅ **What Exists:**
- Basic UI layout with hardcoded dummy data
- Activity item cards with icons, messages, and timestamps
- Alternating color scheme (pink/purple)

❌ **What's Missing:**
- Real data from database
- Live updates
- Different activity types
- Navigation to relevant screens
- Notifications

---

## Database Tables Available

### 1. **swipes** table
```sql
- id UUID
- swiper_id UUID (person who swiped)
- swiped_id UUID (person who was swiped)
- action TEXT ('like', 'pass', 'super_like')
- created_at TIMESTAMP
```

### 2. **matches** table
```sql
- id UUID
- user_id_1 UUID
- user_id_2 UUID
- status TEXT ('matched', 'unmatched', 'blocked')
- created_at TIMESTAMP
```

### 3. **messages** table
```sql
- id UUID
- match_id UUID
- sender_id UUID
- content TEXT
- message_type TEXT ('text', 'image', 'emoji')
- is_read BOOLEAN
- created_at TIMESTAMP
```

### 4. **stories** table
```sql
- id UUID
- user_id UUID
- media_url TEXT
- expires_at TIMESTAMP
- created_at TIMESTAMP
```

### 5. **profiles** table
```sql
- id UUID
- name TEXT
- photos TEXT[]
- last_seen TIMESTAMP
- etc.
```

---

## Activity Types to Implement

### 1. **Someone Liked You** 👍
**Data Source:** `swipes` table
- **Query:** Find all swipes where `swiped_id = current_user` AND `action = 'like'` OR `action = 'super_like'`
- **Display:** 
  - Icon: ❤️ (pink heart) for like, ⭐ (star) for super_like
  - Message: "[Name] liked your profile" or "[Name] super liked you!"
  - Action: Tap to view their profile in discover screen
- **Filter:** Only show if NOT yet matched (don't show mutual matches here, show those separately)

### 2. **New Match** 🎉
**Data Source:** `matches` table
- **Query:** Find all matches where `(user_id_1 = current_user OR user_id_2 = current_user)` AND `status = 'matched'`
- **Display:**
  - Icon: 💫 (sparkles) or 🔥 (flame)
  - Message: "You matched with [Name]!"
  - Action: Tap to open chat with that match
- **Filter:** Only show matches from last 7 days (configurable)

### 3. **New Message** 💬
**Data Source:** `messages` table
- **Query:** Find all messages where `sender_id != current_user` AND current_user is part of the match AND message is unread
- **Display:**
  - Icon: 💬 (chat bubble)
  - Message: "New message from [Name]: [Preview of message]"
  - Action: Tap to open chat
- **Filter:** Only show unread messages OR messages from last 24 hours

### 4. **Story Reply** 📸
**Data Source:** `messages` table (with `story_id` field)
- **Query:** Find messages that are replies to your stories
- **Note:** This requires adding a `story_id` field to messages table (OPTIONAL)
- **Display:**
  - Icon: 📸 (camera)
  - Message: "[Name] replied to your story"
  - Action: Tap to open chat
- **Filter:** Last 24 hours only

### 5. **Profile Views** 👁️ (OPTIONAL - Requires New Table)
**Data Source:** `profile_views` table (NEW)
- This requires creating a new table to track profile views
- Can be implemented later if needed

---

## Implementation Phases

### **Phase 1: Database Setup** (30 mins)
1. ✅ Verify existing tables have all needed columns
2. ✅ Add `story_id` column to `messages` table (if story replies needed)
3. ✅ Create RLS policies for activity queries
4. ✅ Create a database function to fetch aggregated activities

**SQL Function to Create:**
```sql
CREATE OR REPLACE FUNCTION get_user_activities(p_user_id UUID, p_limit INT DEFAULT 50)
RETURNS TABLE (
  activity_id UUID,
  activity_type TEXT,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_photo TEXT,
  message_preview TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  is_unread BOOLEAN
) AS $$
BEGIN
  -- Combine all activity types and return ordered by created_at
  RETURN QUERY
  SELECT * FROM (
    -- New likes
    SELECT 
      s.id,
      CASE WHEN s.action = 'super_like' THEN 'super_like' ELSE 'like' END,
      s.swiper_id,
      p.name,
      (p.photos[1])::TEXT,
      NULL::TEXT,
      s.created_at,
      TRUE::BOOLEAN
    FROM swipes s
    JOIN profiles p ON p.id = s.swiper_id
    WHERE s.swiped_id = p_user_id 
      AND s.action IN ('like', 'super_like')
      AND NOT EXISTS (
        SELECT 1 FROM matches m 
        WHERE (m.user_id_1 = p_user_id AND m.user_id_2 = s.swiper_id)
           OR (m.user_id_2 = p_user_id AND m.user_id_1 = s.swiper_id)
      )
      AND s.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- New matches
    SELECT 
      m.id,
      'match'::TEXT,
      CASE WHEN m.user_id_1 = p_user_id THEN m.user_id_2 ELSE m.user_id_1 END,
      p.name,
      (p.photos[1])::TEXT,
      NULL::TEXT,
      m.created_at,
      TRUE::BOOLEAN
    FROM matches m
    JOIN profiles p ON p.id = CASE WHEN m.user_id_1 = p_user_id THEN m.user_id_2 ELSE m.user_id_1 END
    WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
      AND m.status = 'matched'
      AND m.created_at > NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- New messages
    SELECT 
      msg.id,
      'message'::TEXT,
      msg.sender_id,
      p.name,
      (p.photos[1])::TEXT,
      SUBSTRING(msg.content, 1, 50),
      msg.created_at,
      NOT msg.is_read
    FROM messages msg
    JOIN matches m ON m.id = msg.match_id
    JOIN profiles p ON p.id = msg.sender_id
    WHERE (m.user_id_1 = p_user_id OR m.user_id_2 = p_user_id)
      AND msg.sender_id != p_user_id
      AND msg.created_at > NOW() - INTERVAL '3 days'
  ) activities
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **Phase 2: Backend Service** (1 hour)
**File:** `lib/services/supabase_service.dart`

1. Add method to fetch activities:
```dart
static Future<List<Map<String, dynamic>>> getUserActivities({int limit = 50}) async {
  final uid = currentUser?.id;
  if (uid == null) return [];
  
  try {
    final response = await client.rpc('get_user_activities', params: {
      'p_user_id': uid,
      'p_limit': limit,
    });
    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('Error fetching activities: $e');
    return [];
  }
}
```

2. Add method to mark messages as read when user views activity:
```dart
static Future<void> markActivityAsRead(String activityId, String activityType) async {
  if (activityType == 'message') {
    await client.from('messages').update({'is_read': true}).eq('id', activityId);
  }
}
```

### **Phase 3: Activity Model** (30 mins)
**File:** `lib/Screens/ActivityPage/models/activity_model.dart` (NEW)

```dart
enum ActivityType {
  like,
  superLike,
  match,
  message,
  storyReply,
}

class Activity {
  final String id;
  final ActivityType type;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String? messagePreview;
  final DateTime createdAt;
  final bool isUnread;

  Activity({
    required this.id,
    required this.type,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.messagePreview,
    required this.createdAt,
    required this.isUnread,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    ActivityType type;
    switch (map['activity_type']) {
      case 'like':
        type = ActivityType.like;
        break;
      case 'super_like':
        type = ActivityType.superLike;
        break;
      case 'match':
        type = ActivityType.match;
        break;
      case 'message':
        type = ActivityType.message;
        break;
      case 'story_reply':
        type = ActivityType.storyReply;
        break;
      default:
        type = ActivityType.like;
    }

    return Activity(
      id: map['activity_id'] ?? '',
      type: type,
      otherUserId: map['other_user_id'] ?? '',
      otherUserName: map['other_user_name'] ?? 'User',
      otherUserPhoto: map['other_user_photo'],
      messagePreview: map['message_preview'],
      createdAt: DateTime.parse(map['created_at']),
      isUnread: map['is_unread'] ?? false,
    );
  }

  IconData get icon {
    switch (type) {
      case ActivityType.like:
        return Icons.favorite_outlined;
      case ActivityType.superLike:
        return Icons.star_rounded;
      case ActivityType.match:
        return Icons.local_fire_department_rounded;
      case ActivityType.message:
        return Icons.chat_bubble_rounded;
      case ActivityType.storyReply:
        return Icons.camera_alt_rounded;
    }
  }

  String get displayMessage {
    switch (type) {
      case ActivityType.like:
        return '$otherUserName liked your profile';
      case ActivityType.superLike:
        return '$otherUserName super liked you! 🌟';
      case ActivityType.match:
        return 'You matched with $otherUserName! 🎉';
      case ActivityType.message:
        return 'New message from $otherUserName: ${messagePreview ?? ""}';
      case ActivityType.storyReply:
        return '$otherUserName replied to your story';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${(diff.inDays / 7).floor()} w ago';
  }
}
```

### **Phase 4: Controller Update** (1 hour)
**File:** `lib/Screens/ActivityPage/controller_activity_screen.dart`

```dart
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import './models/activity_model.dart';

class ActivityController extends GetxController {
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivities();
  }

  Future<void> loadActivities() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      final response = await SupabaseService.getUserActivities();
      
      activities.value = response
          .map((data) => Activity.fromMap(data))
          .toList();
      
      print('Loaded ${activities.length} activities');
    } catch (e) {
      print('Error loading activities: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadActivities();
  }

  void onActivityTap(Activity activity) {
    // Mark as read if it's a message
    if (activity.type == ActivityType.message) {
      SupabaseService.markActivityAsRead(activity.id, 'message');
    }

    // Navigate based on activity type
    switch (activity.type) {
      case ActivityType.like:
      case ActivityType.superLike:
        // Navigate to their profile (in discover screen if possible)
        // OR navigate to discover and show that profile
        print('TODO: Navigate to profile ${activity.otherUserId}');
        break;
      
      case ActivityType.match:
      case ActivityType.message:
      case ActivityType.storyReply:
        // Navigate to chat
        Get.toNamed('/chat', arguments: {
          'matchId': activity.id, // For matches, this is match_id
          'otherUserId': activity.otherUserId,
          'otherUserName': activity.otherUserName,
        });
        break;
    }
  }
}
```

### **Phase 5: UI Update** (1 hour)
**File:** `lib/Screens/ActivityPage/ui_activity_screen.dart`

Update the ListView.builder to use real data:

```dart
Obx(() {
  if (controller.isLoading.value && controller.activities.isEmpty) {
    return Center(
      child: CircularProgressIndicator(
        color: themeController.lightPinkColor,
      ),
    );
  }

  if (controller.hasError.value) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: themeController.lightPinkColor),
          SizedBox(height: 16),
          Text('Failed to load activities', style: TextStyle(color: Colors.white)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.loadActivities(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  if (controller.activities.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: themeController.whiteColor.withValues(alpha: 0.5)),
          SizedBox(height: 16),
          Text(
            'No activities yet',
            style: TextStyle(
              color: themeController.whiteColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: controller.refresh,
    color: themeController.lightPinkColor,
    child: ListView.separated(
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: controller.activities.length,
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final activity = controller.activities[index];
        final isOdd = index % 2 != 0;
        
        return InkWell(
          onTap: () => controller.onActivityTap(activity),
          child: Container(
            // ... existing container styling
            child: Row(
              children: [
                // Profile photo
                CircleAvatar(
                  radius: 22,
                  backgroundImage: activity.otherUserPhoto != null
                      ? NetworkImage(activity.otherUserPhoto!)
                      : null,
                  child: activity.otherUserPhoto == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.displayMessage,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        activity.timeAgo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(activity.icon, color: isOdd ? Colors.pink : Colors.purple),
                SizedBox(width: 8),
                if (activity.isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
})
```

---

## Timeline & Effort Estimate

| Phase | Task | Time | Priority |
|-------|------|------|----------|
| 1 | Database setup (SQL function) | 30 mins | HIGH |
| 2 | Backend service methods | 1 hour | HIGH |
| 3 | Activity model | 30 mins | HIGH |
| 4 | Controller update | 1 hour | HIGH |
| 5 | UI update | 1 hour | HIGH |
| **TOTAL** | **Core Implementation** | **4 hours** | - |
| 6 | Real-time updates (Supabase subscriptions) | 1 hour | MEDIUM |
| 7 | Push notifications setup | 2 hours | LOW |
| 8 | Profile views tracking (optional) | 1 hour | LOW |

---

## Key Features

### ✅ **Included in Core Implementation:**
1. Real-time activity feed from database
2. Different activity types (likes, matches, messages)
3. Pull-to-refresh functionality
4. Tap to navigate to relevant screens
5. Unread indicators
6. Time-based filtering (show recent activities only)
7. Profile photos in activity items

### 🔮 **Future Enhancements (Optional):**
1. Real-time updates using Supabase subscriptions
2. Push notifications for new activities
3. Profile view tracking
4. Activity filters (show only matches, only likes, etc.)
5. Mark all as read functionality
6. Activity grouping (e.g., "3 people liked you")

---

## Testing Checklist

- [ ] Like a profile → Should appear in their activity feed
- [ ] Match with someone → Should appear for both users
- [ ] Send a message → Should appear as new message activity
- [ ] Tap on activity → Should navigate to correct screen
- [ ] Pull to refresh → Should fetch latest activities
- [ ] Empty state → Should show when no activities
- [ ] Error state → Should show retry button on failure
- [ ] Unread indicator → Should show for new activities

---

## Notes

1. **RLS Policies:** Make sure Row Level Security policies allow users to read their own activities
2. **Performance:** The SQL function uses UNION ALL for performance (no deduplication needed)
3. **Indexing:** Ensure `created_at` columns are indexed for fast sorting
4. **Caching:** Consider adding client-side caching if activity feed becomes slow
5. **Privacy:** Never show activities from blocked users

---

## Database Migration Script

Create this file: `activity_feed_setup.sql`

```sql
-- Add story_id to messages for story replies (optional)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS story_id UUID REFERENCES stories(id) ON DELETE SET NULL;

-- Create the get_user_activities function
-- (See Phase 1 above for full function code)

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_activities(UUID, INT) TO authenticated;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_swipes_swiped_created ON swipes(swiped_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_users_created ON matches(user_id_1, user_id_2, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(is_read) WHERE is_read = false;
```

---

## Summary

This plan transforms the Activity screen from hardcoded dummy data to a **fully functional, real-time activity feed** that shows:
- Who liked you
- New matches
- New messages
- Story replies (if implemented)

The implementation is **modular** and can be done in phases, with the core functionality taking approximately **4 hours** to complete.

