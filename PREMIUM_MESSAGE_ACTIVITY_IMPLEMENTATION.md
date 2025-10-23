# 🎯 Premium Message Activity Feed Implementation

## **Flow Diagram**

```
PREMIUM USER sends message → STORED in premium_messages table → FREE USER sees notification

FREE USER VIEW:
┌─────────────────────────────────────┐
│ Activity Feed                       │
│ ┌─────────────────────────────────┐ │
│ │ [BLURRED PHOTO]                 │ │
│ │ Someone sent you a message      │ │
│ │ Tap to view with Premium        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ON CLICK:                           │
│ ┌─────────────────────────────────┐ │
│ │ [BLURRED PROFILE]               │ │
│ │ "Upgrade to see who liked you"  │ │
│ │ [UPGRADE BUTTON]                │ │
│ │ (No Match/Unmatch buttons)      │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

AFTER UPGRADE:
┌─────────────────────────────────────┐
│ Activity Feed                       │
│ ┌─────────────────────────────────┐ │
│ │ [CLEAR PHOTO]                   │ │
│ │ John sent you: "Hey there!"     │ │
│ │ Tap to respond                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ON CLICK:                           │
│ ┌─────────────────────────────────┐ │
│ │ [CLEAR PROFILE]                 │ │
│ │ John, 25                        │ │
│ │ Message: "Hey there!"           │ │
│ │ [MATCH] [UNMATCH]               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## **Database Setup**

Already exists: `premium_messages` table
```sql
CREATE TABLE premium_messages (
  id UUID PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id),
  recipient_id UUID REFERENCES profiles(id),
  message_content TEXT NOT NULL,
  is_blurred BOOLEAN DEFAULT true,
  revealed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## **Implementation Steps**

### **Step 1: Modify Activity Model**
Add a new activity type for premium messages.

**File:** `lib/models/activity_model.dart` (or wherever activities are defined)

```dart
enum ActivityType {
  like,
  superLike,
  premiumMessage, // NEW
  match,
  // ... other types
}

class Activity {
  final String id;
  final ActivityType type;
  final String userId; // Who performed the action
  final String? userName; // Blurred if free user
  final String? photoUrl; // Blurred if free user
  final String? message; // Blurred if free user
  final bool isBlurred; // NEW - for free users
  final DateTime timestamp;
  
  // ...
}
```

### **Step 2: Load Premium Messages in Activity Controller**

**File:** `lib/Screens/ActivityPage/controller_activity_screen.dart`

```dart
Future<void> loadActivities() async {
  try {
    isLoading.value = true;
    
    // ... existing code to load likes, matches, etc ...
    
    // Load premium messages received
    final premiumMessages = await SupabaseService.getPremiumMessages();
    
    // Convert to activity items
    for (final msg in premiumMessages) {
      final activity = Activity(
        id: msg['id'],
        type: ActivityType.premiumMessage,
        userId: msg['sender_id'],
        userName: isPremium.value ? msg['sender_name'] : null, // null if free
        photoUrl: isPremium.value ? msg['sender_photo'] : null, // null if free
        message: isPremium.value ? msg['message_content'] : null, // null if free
        isBlurred: !isPremium.value, // Blur for free users
        timestamp: DateTime.parse(msg['created_at']),
      );
      
      allActivities.add(activity);
    }
    
    // Sort by timestamp
    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    activities.assignAll(allActivities);
    
  } catch (e) {
    print('Error loading activities: $e');
    hasError.value = true;
  } finally {
    isLoading.value = false;
  }
}
```

### **Step 3: Modify Activity UI to Show Blurred Items**

**File:** `lib/Screens/ActivityPage/ui_activity_screen.dart`

```dart
// In the itemBuilder:
Widget _buildActivityItem(Activity activity) {
  // For premium messages that are blurred
  if (activity.type == ActivityType.premiumMessage && activity.isBlurred) {
    return BlurredActivityWidget(
      child: Container(
        // ... activity item UI ...
        child: Row(
          children: [
            // Blurred circular avatar
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  color: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white54),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextConstant(
                    title: 'Someone sent you a message',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeController.whiteColor,
                  ),
                  TextConstant(
                    title: 'Tap to view with Premium',
                    fontSize: 12,
                    color: themeController.whiteColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            Icon(Icons.lock, color: Colors.amber, size: 20.sp),
          ],
        ),
      ),
      onTap: () => _showBlurredProfileUpgradePrompt(activity),
    );
  }
  
  // For premium messages that are revealed (user is premium)
  if (activity.type == ActivityType.premiumMessage && !activity.isBlurred) {
    return Container(
      // ... activity item UI with clear photo and message ...
      child: Row(
        children: [
          // Clear circular avatar
          CircleAvatar(
            radius: 25.r,
            backgroundImage: NetworkImage(activity.photoUrl!),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextConstant(
                  title: '${activity.userName} sent you a message',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeController.whiteColor,
                ),
                TextConstant(
                  title: activity.message ?? '',
                  fontSize: 12,
                  color: themeController.whiteColor.withValues(alpha: 0.7),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _showPremiumMessageProfile(activity),
    );
  }
  
  // ... existing activity types ...
}
```

### **Step 4: Show Blurred Profile with Upgrade Prompt**

**File:** `lib/Screens/ActivityPage/controller_activity_screen.dart`

```dart
void _showBlurredProfileUpgradePrompt(Activity activity) {
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: themeController.blackColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blurred profile photo
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 120.w,
                height: 120.h,
                color: Colors.grey.shade800,
                child: Icon(Icons.person, size: 60.sp, color: Colors.white30),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          TextConstant(
            title: 'Upgrade to see who likes you',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 12.h),
          TextConstant(
            title: 'Someone is interested in you! Upgrade to Premium to see their profile and message.',
            fontSize: 14,
            color: themeController.whiteColor.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => SubscriptionScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: TextConstant(
              title: 'Upgrade Now',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => Get.back(),
            child: TextConstant(
              title: 'Maybe Later',
              fontSize: 14,
              color: themeController.whiteColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ),
    isDismissible: true,
  );
}
```

### **Step 5: Show Clear Profile with Match/Unmatch Options**

```dart
void _showPremiumMessageProfile(Activity activity) {
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: themeController.blackColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clear profile photo
          CircleAvatar(
            radius: 60.r,
            backgroundImage: NetworkImage(activity.photoUrl!),
          ),
          SizedBox(height: 16.h),
          TextConstant(
            title: activity.userName!,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeController.whiteColor,
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: themeController.whiteColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: themeController.lightPinkColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextConstant(
                  title: 'Message:',
                  fontSize: 12,
                  color: themeController.whiteColor.withValues(alpha: 0.7),
                ),
                SizedBox(height: 4.h),
                TextConstant(
                  title: activity.message!,
                  fontSize: 16,
                  color: themeController.whiteColor,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    // Match logic
                    _matchWithUser(activity.userId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeController.lightPinkColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: TextConstant(
                    title: 'Match',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    // Unmatch/Reject logic
                    _rejectPremiumMessage(activity.id);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: TextConstant(
                    title: 'Unmatch',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    isDismissible: true,
  );
}
```

## **Summary**

1. ✅ Database table already exists
2. ✅ Service methods already exist
3. ⚠️ Need to integrate into Activity Feed
4. ⚠️ Need blurred/clear rendering
5. ⚠️ Need upgrade prompt
6. ⚠️ Need match/unmatch actions


