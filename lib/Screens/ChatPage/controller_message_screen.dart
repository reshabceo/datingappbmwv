import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../shared_prefrence_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageController extends GetxController {
  final RxList<Message> messages = <Message>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  RealtimeChannel? _channel;
  StreamSubscription<List<Map<String, dynamic>>>? _msgStreamSub;
  String? _currentMatchId;

  final List<String> autoResponses = [
    "Interesting!",
    "That sounds amazing! I love hiking too. Which trail did you go to?",
    "Not yet, but it's on my list! Would you recommend it for beginners?",
    "What's up?",
    "Wow, that's incredible! I've always wanted to try that.",
    "Hello friend! Your message made my day. What have you been up to these days? I’d love to hear all about it!",
    "Oh wow!",
    "Thanks for sharing! I'll definitely check it out.",
    "That's so cool! I'm getting inspired to try new adventures.",
    "Hey, how are you?",
    "Sounds like an amazing experience! How long did it take?",
    "I've heard great things about that place!",
    "Love it!",
    "That must have been breathtaking! Any tips for first-timers?",
    "No way! That sounds like such a fun time!",
    "Hello! Just wanted to say I’m really glad you reached out. The days fly by, but our conversations always stand out. Hope you’re doing great!",
    "Good morning!",
    "I've always been curious about that. Tell me more!",
    "That sounds like the perfect weekend getaway.",
    "Hi 😊",
    "It must have been unforgettable! Did you go alone or with friends?",
    "I love how spontaneous that sounds!",
    "Haha, great!",
    "That's definitely going on my bucket list!",
    "Hi again! It’s always a joy seeing your name pop up. What’s been the highlight of your day so far? Let’s reconnect properly!",
    "Did you take any photos? I'd love to see!",
    "Let’s go!",
    "I wish I could have joined you on that adventure!",
    "You always find the coolest places!",
    "Hey friend!",
    "Hi! So glad to hear from you! I’ve been thinking about our last conversation. Hope life’s been treating you kindly lately. Let’s talk soon!",
    "How did you even find out about that?",
    "Sounds fun!",
  ];

  Future<void> sendMessage(String matchId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      // Send to server
      await SupabaseService.sendMessage(matchId: matchId, content: text.trim());
      textController.clear();
      
      // Track message sent
      await AnalyticsService.trackMessageSent(matchId, 'text');
      
      print('DEBUG: Message sent to server: ${text.trim()}');
    } on PostgrestException catch (e) {
      Get.snackbar('Send failed', e.message);
      print('DEBUG: Send failed with Postgres error: ${e.message}');
    } catch (e) {
      Get.snackbar('Send failed', 'Please try again');
      print('DEBUG: Send failed with error: $e');
    }
  }

  void generateAutoResponse() {}

  Future<void> ensureInitialized(String matchId) async {
    if (matchId.isEmpty) return; // stories entry without a chat
    if (_currentMatchId == matchId && _msgStreamSub != null) return;
    _currentMatchId = matchId;

    // Tear down previous subscription if any
    try { _channel?.unsubscribe(); } catch (_) {}
    _channel = null;
    try { _msgStreamSub?.cancel(); } catch (_) {}

    // Load initial messages
    try {
      final rows = await SupabaseService.getMessages(matchId);
      final myId = SupabaseService.currentUser?.id;
      // Fetch story data separately for story reply messages
      final storyReplyMessages = rows.where((r) => (r['is_story_reply'] ?? false) as bool).toList();
      Map<String, Map<String, dynamic>> storyDataMap = {};
      
      if (storyReplyMessages.isNotEmpty) {
        try {
          final storyIds = storyReplyMessages
              .map((r) => (r['story_id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
          
          if (storyIds.isNotEmpty) {
            final stories = await SupabaseService.client
                .from('stories')
                .select('id,media_url,content,created_at,user_id')
                .inFilter('id', storyIds);
            
            for (final story in stories) {
              final storyId = (story['id'] ?? '').toString();
              storyDataMap[storyId] = (story as Map).cast<String, dynamic>();
            }
          }
        } catch (e) {
          print('DEBUG: Error fetching story data: $e');
        }
      }
      
      final loaded = rows.map((r) {
        final storyId = (r['story_id'] ?? '').toString();
        final storyData = storyId.isNotEmpty ? storyDataMap[storyId] : null;
        
        final message = Message(
          text: (r['content'] ?? '').toString(),
          isUser: (r['sender_id'] ?? '').toString() == (myId ?? ''),
          timestamp: DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now(),
          storyId: storyId.isEmpty ? null : storyId,
          isStoryReply: (r['is_story_reply'] ?? false) as bool,
          storyUserName: (r['story_user_name'] ?? '').toString().isEmpty ? null : (r['story_user_name'] ?? '').toString(),
          storyImageUrl: storyData?['media_url']?.toString(),
          storyContent: storyData?['content']?.toString(),
          storyAuthorName: storyData?['user_id']?.toString(), // We'll use user_id for now
          storyCreatedAt: storyData?['created_at'] != null ? DateTime.tryParse(storyData!['created_at'].toString()) : null,
          isDisappearingPhoto: (r['is_disappearing_photo'] ?? false) as bool,
          disappearingPhotoId: (r['disappearing_photo_id'] ?? '').toString().isEmpty ? null : (r['disappearing_photo_id'] ?? '').toString(),
        );
        
        // Debug logging for story reply messages
        if (message.isStoryReply) {
          print('DEBUG: Story reply message - Image: ${message.storyImageUrl}, Content: ${message.storyContent}, Author: ${message.storyAuthorName}');
        }
        
        // Debug logging for regular messages in initial load
        if (!message.isDisappearingPhoto && !message.isStoryReply) {
          print('DEBUG: Initial load - Regular message - Text: "${message.text}", isUser: ${message.isUser}, timestamp: ${message.timestamp}');
        }
        
        return message;
      }).toList();
      
      // Sort by timestamp to ensure correct order
      loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Debug: Print all messages with their timestamps
      print('DEBUG: Initial load - Messages after sorting:');
      for (int i = 0; i < loaded.length; i++) {
        final msg = loaded[i];
        print('  $i: "${msg.text}" (${msg.isUser ? "User" : "Other"}) - ${msg.timestamp}');
      }
      
      messages.assignAll(loaded);
      scrollToBottom();
      print('DEBUG: Initial load - ${loaded.length} messages for match $matchId');
    } catch (e) {
      print('DEBUG: Error loading initial messages: $e');
    }


    // Subscribe to new messages via stream API (works reliably on web)
    try {
        _msgStreamSub = SupabaseService.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('match_id', matchId)
            .order('created_at', ascending: true)
            .listen((rows) {
              print('DEBUG: Stream received ${rows.length} messages');
              final myId = SupabaseService.currentUser?.id;
              final loaded = rows.map((r) {
                final storyData = r['stories'] as Map<String, dynamic>?;
                final profileData = storyData?['profiles'] as Map<String, dynamic>?;
                final message = Message(
                  text: (r['content'] ?? '').toString(),
                  isUser: (r['sender_id'] ?? '').toString() == (myId ?? ''),
                  timestamp: DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now(),
                  storyId: (r['story_id'] ?? '').toString().isEmpty ? null : (r['story_id'] ?? '').toString(),
                  isStoryReply: (r['is_story_reply'] ?? false) as bool,
                  storyUserName: (r['story_user_name'] ?? '').toString().isEmpty ? null : (r['story_user_name'] ?? '').toString(),
                  storyImageUrl: storyData?['media_url']?.toString(),
                  storyContent: storyData?['content']?.toString(),
                  storyAuthorName: profileData?['name']?.toString(),
                  storyCreatedAt: storyData?['created_at'] != null ? DateTime.tryParse(storyData!['created_at'].toString()) : null,
                  isDisappearingPhoto: (r['is_disappearing_photo'] ?? false) as bool,
                  disappearingPhotoId: (r['disappearing_photo_id'] ?? '').toString().isEmpty ? null : (r['disappearing_photo_id'] ?? '').toString(),
                );
                
                // Debug logging for regular messages
                if (!message.isDisappearingPhoto && !message.isStoryReply) {
                  print('DEBUG: Stream - Regular message - Text: "${message.text}", isUser: ${message.isUser}, timestamp: ${message.timestamp}');
                }
                
                return message;
              }).toList();
              // Sort by timestamp to ensure correct order
              loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              
              // Debug: Print all messages with their timestamps
              print('DEBUG: Stream - Messages after sorting:');
              for (int i = 0; i < loaded.length; i++) {
                final msg = loaded[i];
                print('  $i: "${msg.text}" (${msg.isUser ? "User" : "Other"}) - ${msg.timestamp}');
              }
              
              // Update messages
              messages.assignAll(loaded);
              scrollToBottom();
              print('DEBUG: Messages updated, count: ${loaded.length}');
            });
    } catch (_) {}
  }


  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    try { _channel?.unsubscribe(); } catch (_) {}
    try { _msgStreamSub?.cancel(); } catch (_) {}
    super.onClose();
  }
}

// Message Model
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? storyId;
  final bool isStoryReply;
  final String? storyUserName;
  final String? storyImageUrl;
  final String? storyContent;
  final String? storyAuthorName;
  final DateTime? storyCreatedAt;
  final bool isDisappearingPhoto;
  final String? disappearingPhotoId;

  Message({
    required this.text, 
    required this.isUser, 
    required this.timestamp,
    this.storyId,
    this.isStoryReply = false,
    this.storyUserName,
    this.storyImageUrl,
    this.storyContent,
    this.storyAuthorName,
    this.storyCreatedAt,
    this.isDisappearingPhoto = false,
    this.disappearingPhotoId,
  });
}
