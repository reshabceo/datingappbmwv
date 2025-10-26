import 'package:flutter/material.dart';

enum ActivityType {
  like,
  superLike,
  match,
  bffMatch,
  premiumMessage,
  message,
  bffMessage,
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
      case 'bff_match':
        type = ActivityType.bffMatch;
        break;
      case 'premium_message':
        type = ActivityType.premiumMessage;
        break;
      case 'message':
        type = ActivityType.message;
        break;
      case 'bff_message':
        type = ActivityType.bffMessage;
        break;
      case 'story_reply':
        type = ActivityType.storyReply;
        break;
      default:
        type = ActivityType.like;
    }

    // Clean up photo URL - remove quotes if present
    String? photoUrl = map['other_user_photo'];
    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Remove surrounding quotes from JSONB extraction
      photoUrl = photoUrl.replaceAll('"', '');
      // If empty after cleaning, set to null
      if (photoUrl.isEmpty) photoUrl = null;
    }

    return Activity(
      id: map['activity_id']?.toString() ?? '',
      type: type,
      otherUserId: map['other_user_id']?.toString() ?? '',
      otherUserName: map['other_user_name']?.toString() ?? 'User',
      otherUserPhoto: photoUrl,
      messagePreview: map['message_preview']?.toString(),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      isUnread: map['is_unread'] == true,
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
      case ActivityType.bffMatch:
        return Icons.people_rounded;
      case ActivityType.premiumMessage:
        return Icons.send_rounded;
      case ActivityType.message:
        return Icons.chat_bubble_rounded;
      case ActivityType.bffMessage:
        return Icons.people_outline_rounded;
      case ActivityType.storyReply:
        return Icons.camera_alt_rounded;
    }
  }

  String get displayMessage {
    switch (type) {
      case ActivityType.like:
        return '$otherUserName liked your profile';
      case ActivityType.superLike:
        return '$otherUserName super liked you!';
      case ActivityType.match:
        return 'You matched with $otherUserName!';
      case ActivityType.bffMatch:
        return 'Say hi to your new BFF $otherUserName';
      case ActivityType.premiumMessage:
        // When not premium, otherUserName may be 'Someone' and messagePreview may be null
        if (otherUserName.isEmpty || otherUserName == 'Someone') {
          return 'Someone sent you a message';
        }
        final previewPm = messagePreview != null && messagePreview!.isNotEmpty ? ': ${messagePreview!}' : '';
        return '$otherUserName sent you$previewPm';
      case ActivityType.message:
        final preview = messagePreview != null && messagePreview!.isNotEmpty 
            ? ': ${messagePreview!}' 
            : '';
        return 'New message from $otherUserName$preview';
      case ActivityType.bffMessage:
        final preview = messagePreview != null && messagePreview!.isNotEmpty 
            ? ': ${messagePreview!}' 
            : '';
        return 'New BFF message from $otherUserName$preview';
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

