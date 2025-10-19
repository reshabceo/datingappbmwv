import 'dart:async';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/string_utils.dart';
import '../DiscoverPage/controller_discover_screen.dart';

class EnhancedChatController extends GetxController {
  final RxList<ChatItem> chatList = <ChatItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingNewMatches = false.obs;
  StreamSubscription<List<Map<String, dynamic>>>? _matchesSub1;
  StreamSubscription<List<Map<String, dynamic>>>? _matchesSub2;
  StreamSubscription<List<Map<String, dynamic>>>? _bffMatchesSub1;
  StreamSubscription<List<Map<String, dynamic>>>? _bffMatchesSub2;
  String _currentMode = 'dating'; // Track current mode

  @override
  void onInit() {
    super.onInit();
    _setupModeListener();
    loadChats();
    _setupRealtimeSubscriptions();
  }

  void _setupModeListener() {
    // Listen to mode changes from DiscoverController
    if (Get.isRegistered<DiscoverController>()) {
      final discoverController = Get.find<DiscoverController>();
      discoverController.currentMode.listen((mode) {
        if (_currentMode != mode) {
          print('DEBUG: Mode changed from $_currentMode to $mode');
          _currentMode = mode;
          loadChats(); // Reload chats when mode changes
        }
      });
    }
  }

  void _setupRealtimeSubscriptions() {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid != null) {
        // Listen to dating matches
        final datingMatches = SupabaseService.client.from('matches').stream(primaryKey: ['id']);
        _matchesSub1 = datingMatches.eq('user_id_1', uid).listen((_) {
          if (_currentMode == 'dating') {
            print('DEBUG: Dating matches updated for user_id_1');
            loadChats();
          }
        });
        _matchesSub2 = datingMatches.eq('user_id_2', uid).listen((_) {
          if (_currentMode == 'dating') {
            print('DEBUG: Dating matches updated for user_id_2');
            loadChats();
          }
        });
        
        // Listen to BFF matches
        final bffMatches = SupabaseService.client.from('bff_matches').stream(primaryKey: ['id']);
        _bffMatchesSub1 = bffMatches.eq('user_id_1', uid).listen((_) {
          if (_currentMode == 'bff') {
            print('DEBUG: BFF matches updated for user_id_1');
            loadChats();
          }
        });
        _bffMatchesSub2 = bffMatches.eq('user_id_2', uid).listen((_) {
          if (_currentMode == 'bff') {
            print('DEBUG: BFF matches updated for user_id_2');
            loadChats();
          }
        });
        
        // Listen to messages table for real-time updates
        SupabaseService.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .listen((_) {
              if (_currentMode == 'dating' || _currentMode == 'bff') {
                loadChats();
              }
            });
      }
    } catch (e) {
      print('Error setting up realtime subscriptions: $e');
    }
  }

  Future<void> loadChats() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    try {
      print('🔍 DEBUG: Loading chats for mode: $_currentMode');
      print('🔍 DEBUG: Current user ID: ${SupabaseService.currentUser?.id}');
      
      if (_currentMode == 'bff') {
        await _loadBffChats();
      } else {
        await _loadDatingChats();
      }
      
      print('✅ DEBUG: Chat loading completed for mode: $_currentMode, count: ${chatList.length}');
      print('✅ DEBUG: Chat list contents: ${chatList.map((c) => '${c.name} (${c.id})').toList()}');
    } catch (e) {
      print('❌ ERROR: Failed to load chats for mode $_currentMode: $e');
      chatList.clear(); // Clear on error
    } finally {
      isLoading.value = false;
    }
  }

  void onModeChanged(String mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      loadChats();
    }
  }

  Future<void> _loadDatingChats() async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;

      print('🔍 DEBUG: Loading dating chats for user: $uid');
      
      // Load ALL matches first (simplified query)
      final allMatches = await SupabaseService.client
          .from('matches')
          .select('id, user_id_1, user_id_2, created_at')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid');

      print('🔍 DEBUG: Found ${allMatches.length} total matches for user');

      // Get BFF match IDs to exclude them from dating
      final bffMatchIds = await SupabaseService.client
          .from('bff_matches')
          .select('id')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid');

      final bffIds = bffMatchIds.map((e) => e['id'].toString()).toSet();
      print('🔍 DEBUG: BFF match IDs to exclude: $bffIds');
      
      // Filter out BFF matches for dating mode
      final datingMatches = allMatches.where((match) => !bffIds.contains(match['id'].toString())).toList();

      print('🔍 DEBUG: Found ${datingMatches.length} dating matches (excluding ${bffIds.length} BFF matches)');
      
      if (datingMatches.isEmpty) {
        print('🔍 DEBUG: No dating matches found, clearing chat list');
        chatList.clear();
        return;
      }

      // Get latest messages for each match
      final chatItems = <ChatItem>[];
      for (final match in datingMatches) {
        try {
          final matchId = match['id'].toString();
          final otherUserId = match['user_id_1'].toString() == uid 
              ? match['user_id_2'].toString() 
              : match['user_id_1'].toString();
          
          // Get other user's profile separately
          final otherUserProfile = await SupabaseService.client
              .from('profiles')
              .select('id, name, image_urls, is_active')
              .eq('id', otherUserId)
              .single();

          // Get latest message
          final messages = await SupabaseService.client
              .from('messages')
              .select('content, created_at, sender_id, message_type')
              .eq('match_id', matchId)
              .order('created_at', ascending: false)
              .limit(1);

          String lastMessage = 'Start a conversation';
          String lastMessageTime = '';
          
          if (messages.isNotEmpty) {
            final message = messages[0];
            lastMessage = message['content'] ?? 'Start a conversation';
            lastMessageTime = _formatTime(DateTime.parse(message['created_at']));
          }

          chatItems.add(ChatItem(
            id: matchId,
            name: otherUserProfile['name'] ?? 'Unknown',
            image: _getProfileImage(otherUserProfile['image_urls']),
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            isBffMatch: false, // This is a dating match
          ));
        } catch (e) {
          print('Error processing dating match: $e');
        }
      }

      // Sort by last message time
      chatItems.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      chatList.value = chatItems;
      print('✅ DEBUG: Dating chats loaded successfully: ${chatItems.length}');
      
    } catch (e) {
      print('Error loading dating chats: $e');
    }
  }

  Future<void> _loadBffChats() async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;

      print('🔍 DEBUG: Loading BFF chats for user: $uid');
      
      // Get BFF matches only (simplified query)
      final bffMatches = await SupabaseService.client
          .from('bff_matches')
          .select('id, user_id_1, user_id_2, created_at')
          .or('user_id_1.eq.$uid,user_id_2.eq.$uid');

      print('🔍 DEBUG: Found ${bffMatches.length} BFF matches for user: $uid');
      
      if (bffMatches.isEmpty) {
        print('🔍 DEBUG: No BFF matches found, clearing chat list');
        chatList.clear();
        return;
      }

      // Get latest messages for each BFF match
      final chatItems = <ChatItem>[];
      for (final match in bffMatches) {
        try {
          final matchId = match['id'].toString();
          final otherUserId = match['user_id_1'].toString() == uid 
              ? match['user_id_2'].toString() 
              : match['user_id_1'].toString();
          
          // Get other user's profile separately
          final otherUserProfile = await SupabaseService.client
              .from('profiles')
              .select('id, name, image_urls, is_active')
              .eq('id', otherUserId)
              .single();

          if (otherUserProfile == null) continue;

          // Get latest message
          final messages = await SupabaseService.client
              .from('messages')
              .select('content, created_at, sender_id, message_type')
              .eq('match_id', matchId)
              .order('created_at', ascending: false)
              .limit(1);

          String lastMessage = 'Start a conversation';
          String lastMessageTime = '';
          
          if (messages.isNotEmpty) {
            final message = messages[0];
            lastMessage = message['content'] ?? 'Start a conversation';
            lastMessageTime = _formatTime(DateTime.parse(message['created_at']));
          }

          chatItems.add(ChatItem(
            id: matchId,
            name: otherUserProfile['name'] ?? 'Unknown',
            image: _getProfileImage(otherUserProfile['image_urls']),
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            isBffMatch: true, // This is a BFF match
          ));
        } catch (e) {
          print('Error processing BFF match: $e');
        }
      }

      // Sort by last message time
      chatItems.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      chatList.value = chatItems;
      print('✅ DEBUG: BFF chats loaded successfully: ${chatItems.length}');
      
    } catch (e) {
      print('Error loading BFF chats: $e');
    }
  }

  String _getProfileImage(dynamic imageUrls) {
    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls[0].toString();
    }
    return '';
  }

  String _formatTime(dynamic timeData) {
    if (timeData == null) return 'Just now';
    
    DateTime dateTime;
    if (timeData is String) {
      dateTime = DateTime.tryParse(timeData) ?? DateTime.now();
    } else if (timeData is DateTime) {
      dateTime = timeData;
    } else {
      return 'Just now';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void onClose() {
    _matchesSub1?.cancel();
    _matchesSub2?.cancel();
    _bffMatchesSub1?.cancel();
    _bffMatchesSub2?.cancel();
    super.onClose();
  }
}

class ChatItem {
  final String id;
  final String name;
  final String image;
  final String lastMessage;
  final String lastMessageTime;
  final bool isBffMatch;

  ChatItem({
    required this.id,
    required this.name,
    required this.image,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isBffMatch,
  });
}
