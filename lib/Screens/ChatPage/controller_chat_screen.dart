import 'dart:async';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/string_utils.dart';

class ChatController extends GetxController {

  final RxList<ChatItem> chatList = <ChatItem>[].obs;
  StreamSubscription<List<Map<String, dynamic>>>? _matchesSub1;
  StreamSubscription<List<Map<String, dynamic>>>? _matchesSub2;

  @override
  void onInit() {
    super.onInit();
    loadChats();
    // Realtime updates using table stream API (works across platforms)
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid != null) {
        final base = SupabaseService.client.from('matches').stream(primaryKey: ['id']);
        _matchesSub1 = base.eq('user_id_1', uid).listen((_) {
          print('DEBUG: Matches updated for user_id_1');
          loadChats();
        });
        _matchesSub2 = base.eq('user_id_2', uid).listen((_) {
          print('DEBUG: Matches updated for user_id_2');
          loadChats();
        });
        
        // Also listen to messages table for real-time updates
        SupabaseService.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .listen((_) {
          print('DEBUG: Messages updated, refreshing chat list');
          loadChats();
        });
      }
    } catch (e) {
      print('DEBUG: Error setting up real-time subscriptions: $e');
    }
  }

  @override
  void onClose() {
    try { _matchesSub1?.cancel(); } catch (_) {}
    try { _matchesSub2?.cancel(); } catch (_) {}
    super.onClose();
  }

  Future<void> loadChats() async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      final matches = await SupabaseService.getMatches();

      print('DEBUG: Found ${matches.length} matches for user $uid');

      final items = <ChatItem>[];
      for (final match in matches) {
        final matchId = (match['id'] ?? '').toString();
        final u1 = (match['user_id_1'] ?? '').toString();
        final u2 = (match['user_id_2'] ?? '').toString();
        
        if (matchId.isEmpty || u1.isEmpty || u2.isEmpty) continue;
        if (u1 != uid && u2 != uid) continue; // Skip if current user not involved
        
        final otherId = (u1 == uid) ? u2 : u1;
        
        // Safety check: skip self-matches
        if (otherId == uid) {
          print('DEBUG: Skipping self-match for user $uid');
          continue;
        }
        
        print('DEBUG: Loading profile for other user: $otherId');
        
        try {
          final otherProfile = await SupabaseService.getProfileById(otherId);
          final name = StringUtils.formatName((otherProfile?['name'] ?? 'User').toString());
          String avatarUrl = '';
          final urls = otherProfile?['photos'] ?? otherProfile?['image_urls'];
          if (urls is List && urls.isNotEmpty) avatarUrl = urls.first.toString();
          
          // Get the latest message for this match
          String lastMessage = '';
          String lastTime = '';
          try {
            final messages = await SupabaseService.getMessages(matchId);
            if (messages.isNotEmpty) {
              final latest = messages.last;
              lastMessage = (latest['content'] ?? '').toString();
              final timestamp = DateTime.tryParse((latest['created_at'] ?? '').toString());
              if (timestamp != null) {
                final now = DateTime.now();
                final diff = now.difference(timestamp);
                if (diff.inDays > 0) {
                  lastTime = '${diff.inDays}d ago';
                } else if (diff.inHours > 0) {
                  lastTime = '${diff.inHours}h ago';
                } else if (diff.inMinutes > 0) {
                  lastTime = '${diff.inMinutes}m ago';
                } else {
                  lastTime = 'Just now';
                }
              }
            }
          } catch (e) {
            print('DEBUG: Error loading messages for match $matchId: $e');
          }
          
          items.add(ChatItem(
            matchId: matchId, 
            name: name, 
            message: lastMessage.isEmpty ? 'Say hi!' : lastMessage, 
            time: lastTime, 
            avatarUrl: avatarUrl
          ));
          print('DEBUG: Added chat item for $name');
        } catch (e) {
          print('DEBUG: Error loading profile $otherId: $e');
        }
      }
      // Rely solely on matches; if none, show empty state

      print('DEBUG: Final chat items count: ${items.length}');
      chatList.assignAll(items);
    } catch (e) {
      print('DEBUG: Error in loadChats: $e');
    }
  }

}

class ChatItem {
  final String matchId;
  final String name;
  final String message;
  final String time;
  final String avatarUrl;

  ChatItem({
    required this.matchId,
    required this.name,
    required this.message,
    required this.time,
    required this.avatarUrl,
  });
}