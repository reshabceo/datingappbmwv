import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/analytics_service.dart';
import '../../shared_prefrence_helper.dart';
import '../../widgets/upgrade_prompt_widget.dart';
import '../../Screens/SubscriptionPage/ui_subscription_screen.dart';
import '../../models/audio_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageController extends GetxController {
  final RxList<Message> messages = <Message>[].obs;
  final RxList<AudioMessage> audioMessages = <AudioMessage>[].obs;
  final RxList<dynamic> allSortedMessages = <dynamic>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  RealtimeChannel? _channel;
  StreamSubscription<List<Map<String, dynamic>>>? _msgStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _audioStreamSub;
  String? _currentMatchId;
  bool _isBffMode = false;

  final RxSet<String> selectedMessageKeys = <String>{}.obs;
  final RxBool isSelectionMode = false.obs;
  final RxBool canDeleteForEveryone = false.obs;

  final RxBool isPremiumUser = false.obs;
  final RxString userGender = ''.obs;
  final Rxn<DateTime> flameStartedAt = Rxn<DateTime>();
  final Rxn<DateTime> flameExpiresAt = Rxn<DateTime>();
  final RxInt flameSecondsRemaining = 0.obs;
  final RxBool isFlameActive = false.obs;
  final RxBool hasFlameEnded = false.obs;
  final RxBool hasDismissedFlameBanner = false.obs;
  final Rxn<DateTime> nextMessageAvailableAt = Rxn<DateTime>();

  Timer? _flameTimer;
  bool _flameInitialized = false;

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

  bool get isBffMode => _isBffMode;
  bool get isFreeTierMale => !isPremiumUser.value && userGender.value.toLowerCase() == 'male';
  bool get shouldBlockPostFlameMessaging => hasFlameEnded.value && isFreeTierMale && !isFlameActive.value;
  bool get shouldShowFlameBanner => isFlameActive.value || (hasFlameEnded.value && !hasDismissedFlameBanner.value);

  String get formattedFlameCountdown {
    final seconds = flameSecondsRemaining.value;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String get formattedNextMessageTime {
    final next = nextMessageAvailableAt.value;
    if (next == null) return '';
    return DateFormat('MMM d • h:mm a').format(next);
  }

  Future<void> sendMessage(String matchId, String text) async {
    if (text.trim().isEmpty) return;
    if (!await ensureMessagingAllowed()) return;
    final bypass = isFlameActive.value;
    try {
      // Send to server
      await SupabaseService.sendMessage(
        matchId: matchId,
        content: text.trim(),
        bypassFreemium: bypass,
      );
      textController.clear();
      
      // Mark ice breakers as used (so they disappear for both users)
      await _markIceBreakersAsUsed(matchId);
      
      // Track message sent
      await AnalyticsService.trackMessageSent(matchId, 'text');
      
      print('DEBUG: Message sent to server: ${text.trim()}');
    } on PostgrestException catch (e) {
      // Check if it's a freemium limit error
      if (e.message.contains('Daily message limit reached')) {
        _showMessageLimitDialog();
      } else {
        Get.snackbar('Send failed', e.message);
      }
      print('DEBUG: Send failed with Postgres error: ${e.message}');
    } catch (e) {
      // Check if it's a freemium limit error
      if (e.toString().contains('Daily message limit reached')) {
        _showMessageLimitDialog();
      } else {
        Get.snackbar('Send failed', 'Please try again');
      }
      print('DEBUG: Send failed with error: $e');
    }
  }

  // Mark ice breakers as used when any message is sent
  Future<void> _markIceBreakersAsUsed(String matchId) async {
    try {
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Check if ice breakers are already marked as used
      final existing = await SupabaseService.client
          .from('ice_breaker_usage')
          .select('id')
          .eq('match_id', matchId)
          .limit(1);

      if ((existing as List).isEmpty) {
        // Mark ice breakers as used with a generic message
        await SupabaseService.client
            .from('ice_breaker_usage')
            .insert({
          'match_id': matchId,
          'ice_breaker_text': 'User sent custom message',
          'used_by_user_id': currentUserId,
        });
        print('DEBUG: Ice breakers marked as used for match $matchId');
      }
    } catch (e) {
      print('DEBUG: Error marking ice breakers as used: $e');
      // Don't show error to user, this is background logic
    }
  }

  void generateAutoResponse() {}

  Future<void> ensureInitialized(String matchId, {bool isBffMatch = false}) async {
    if (matchId.isEmpty) return; // stories entry without a chat
    if (_currentMatchId == matchId && _msgStreamSub != null) return;
    _currentMatchId = matchId;
    _isBffMode = isBffMatch;
    clearSelection();
    
    // Load user summary to check premium status
    await _loadUserSummary();
    
    // Check if banner was dismissed for this match (for premium users)
    final isPremium = isPremiumUser.value;
    final wasDismissed = SharedPreferenceHelper.getBool(
      'flame_banner_dismissed_$matchId',
      defaultValue: false,
    );
    
    // For premium users who have dismissed before, keep it dismissed
    // Otherwise reset it (will be re-checked after flame status loads)
    if (isPremium && wasDismissed) {
      hasDismissedFlameBanner.value = true;
      print('✅ DEBUG: Restored flame banner dismissal for premium user, match: $matchId');
    } else {
      hasDismissedFlameBanner.value = false;
    }
    
    _resetFlameState();
    _flameInitialized = false;

    // Tear down previous subscription if any
    try { _channel?.unsubscribe(); } catch (_) {}
    _channel = null;
    try { _msgStreamSub?.cancel(); } catch (_) {}
    try { _audioStreamSub?.cancel(); } catch (_) {}

    // Load both text and audio messages together
    await _loadAllMessages(matchId, isBffMatch);

    if (!_flameInitialized) {
      _flameInitialized = true;
      await _initializeFlameState(matchId);
    } else {
      await _refreshFlameStatus(matchId);
    }


    // Subscribe to new messages via stream API (works reliably on web)
    try {
        _msgStreamSub = SupabaseService.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('match_id', matchId)
            .order('created_at', ascending: true)
            .listen((rows) async {
              print('DEBUG: Stream received ${rows.length} messages');
              final myId = SupabaseService.currentUser?.id;
              
              // Fetch story data for story reply messages in stream
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
                  print('DEBUG: Error fetching story data in stream: $e');
                }
              }
              
              final loaded = rows.map((r) {
                final storyId = (r['story_id'] ?? '').toString();
                final storyData = storyId.isNotEmpty ? storyDataMap[storyId] : null;
                final senderId = (r['sender_id'] ?? '').toString();
                final id = (r['id'] ?? '').toString();
                final deletedByRaw = r['deleted_by'];
                final deletedByList = deletedByRaw is List
                    ? deletedByRaw.map((e) => e.toString()).toList()
                    : <String>[];

                if (deletedByList.contains(myId)) {
                  return null; // Skip messages deleted for current user
                }

                final message = Message(
                  id: id.isEmpty ? null : id,
                  senderId: senderId,
                  text: (r['content'] ?? '').toString(),
                  isUser: senderId == (myId ?? ''),
                  // Parse UTC and convert to local (consistent with audio messages)
                  timestamp: (DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now()).toLocal(),
                  storyId: storyId.isEmpty ? null : storyId,
                  isStoryReply: (r['is_story_reply'] ?? false) as bool,
                  storyUserName: (r['story_user_name'] ?? '').toString().isEmpty ? null : (r['story_user_name'] ?? '').toString(),
                  storyImageUrl: storyData?['media_url']?.toString(),
                  storyContent: storyData?['content']?.toString(),
                  storyAuthorName: storyData?['user_id']?.toString(),
                  storyCreatedAt: storyData?['created_at'] != null ? DateTime.tryParse(storyData!['created_at'].toString()) : null,
                  isDisappearingPhoto: (r['is_disappearing_photo'] ?? false) as bool,
                  disappearingPhotoId: (r['disappearing_photo_id'] ?? '').toString().isEmpty ? null : (r['disappearing_photo_id'] ?? '').toString(),
                  deletedForEveryone: (r['deleted_for_everyone'] ?? false) as bool,
                  deletedBy: deletedByList,
                  deletedAt: r['deleted_at'] != null
                      ? DateTime.tryParse(r['deleted_at'].toString())?.toLocal()
                      : null,
                );
                
                // Debug logging for story reply messages
                if (message.isStoryReply) {
                  print('DEBUG: Stream - Story reply message - Image: ${message.storyImageUrl}, Content: ${message.storyContent}, Author: ${message.storyAuthorName}');
                }
                
                // Debug logging for regular messages
                if (!message.isDisappearingPhoto && !message.isStoryReply) {
                  print('DEBUG: Stream - Regular message - Text: "${message.text}", isUser: ${message.isUser}, timestamp: ${message.timestamp}');
                }
                
                return message;
              }).whereType<Message>().toList();
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
              _pruneSelection();
              _recalculateSelectionState(prune: false);
              
              // Update allSortedMessages with current text messages + existing audio messages
              _updateAllSortedMessages();
              
              scrollToBottom();
              print('DEBUG: Messages updated, count: ${loaded.length}');
            });
    } catch (_) {}

    // Subscribe to audio messages for real-time updates
    try {
      _audioStreamSub = SupabaseService.client
          .from('audio_messages')
          .stream(primaryKey: ['id'])
          .eq('match_id', matchId)
          .order('created_at', ascending: true)
          .listen((rows) async {
            print('🔊 DEBUG: Audio stream received ${rows.length} audio messages');
            final myId = SupabaseService.currentUser?.id;
            
            // Process audio messages
            final loadedAudio = rows.map((r) {
              final audio = AudioMessage.fromMap(r);
              print('🔊 DEBUG: Audio message - ID: ${audio.id}, Sender: ${audio.senderId}, Duration: ${audio.duration}');
              return audio;
            }).where((audio) {
              if (myId == null) return true;
              return !audio.deletedBy.contains(myId);
            }).toList();
            
            // Update audio messages
            audioMessages.assignAll(loadedAudio);
            _pruneSelection();
            _recalculateSelectionState(prune: false);
            
            // Update allSortedMessages with current text messages + updated audio messages
            _updateAllSortedMessages();
            
            scrollToBottom();
            print('🔊 DEBUG: Audio messages updated, count: ${loadedAudio.length}');
          });
    } catch (e) {
      print('❌ Error setting up audio message stream: $e');
    }
  }


  Future<void> _initializeFlameState(String matchId) async {
    await _loadUserSummary();
    final meta = await SupabaseService.startFlameChat(matchId);
    if (meta.isNotEmpty) {
      _applyFlameMeta(meta);
    } else {
      final status = await SupabaseService.getFlameStatus(matchId);
      if (status.isNotEmpty) {
        _applyFlameMeta(status);
      }
    }
  }

  Future<void> _refreshFlameStatus(String matchId) async {
    final meta = await SupabaseService.getFlameStatus(matchId);
    if (meta.isNotEmpty) {
      _applyFlameMeta(meta);
    }
  }

  Future<void> _loadUserSummary() async {
    if (userGender.value.isNotEmpty) return;
    final summary = await SupabaseService.getCurrentUserSummary();
    final gender = (summary['gender'] ?? '').toString();
    userGender.value = gender;
    final genderLower = gender.toLowerCase();
    if (genderLower == 'female') {
      isPremiumUser.value = true;
    } else {
      isPremiumUser.value = summary['is_premium'] == true;
    }
  }

  Future<void> _applyFlameMeta(Map<String, dynamic> meta) async {
    final startedRaw = meta['flame_started_at'];
    final expiresRaw = meta['flame_expires_at'];

    final bool wasActive = isFlameActive.value;
    final bool wasEnded = hasFlameEnded.value;

    final started = startedRaw == null
        ? null
        : DateTime.tryParse(startedRaw.toString())?.toLocal();
    final expires = expiresRaw == null
        ? null
        : DateTime.tryParse(expiresRaw.toString())?.toLocal();

    flameStartedAt.value = started;
    flameExpiresAt.value = expires;

    if (expires != null) {
      final remaining = expires.difference(DateTime.now());
      if (remaining.inSeconds > 0) {
        isFlameActive.value = true;
        hasFlameEnded.value = false;
        flameSecondsRemaining.value = remaining.inSeconds;
        nextMessageAvailableAt.value = null;
        if (!wasActive) {
          hasDismissedFlameBanner.value = false;
        }
        _startFlameTicker();
        return;
      }
    }

    isFlameActive.value = false;
    flameSecondsRemaining.value = 0;
    if (started != null) {
      hasFlameEnded.value = true;
      if (!wasEnded) {
        // Check if premium user has dismissed before
        final isPremium = isPremiumUser.value;
        if (isPremium && _currentMatchId != null) {
          final wasDismissed = SharedPreferenceHelper.getBool(
            'flame_banner_dismissed_${_currentMatchId}',
            defaultValue: false,
          );
          hasDismissedFlameBanner.value = wasDismissed;
          if (wasDismissed) {
            print('✅ DEBUG: Flame ended, banner already dismissed for premium user');
          }
        } else {
          hasDismissedFlameBanner.value = false;
        }
      }
      final expiresAt = expires ?? DateTime.now();
      nextMessageAvailableAt.value = expiresAt.add(const Duration(days: 1));
    } else {
      hasFlameEnded.value = false;
      nextMessageAvailableAt.value = null;
    }
    _stopFlameTicker();
  }

  void _startFlameTicker() {
    _stopFlameTicker();
    _flameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expires = flameExpiresAt.value;
      if (expires == null) {
        _handleFlameExpired();
        return;
      }
      final remaining = expires.difference(DateTime.now());
      if (remaining.inSeconds <= 0) {
        _handleFlameExpired();
        return;
      }
      flameSecondsRemaining.value = remaining.inSeconds;
    });
  }

  void _stopFlameTicker() {
    _flameTimer?.cancel();
    _flameTimer = null;
  }

  void _handleFlameExpired() async {
    _stopFlameTicker();
    isFlameActive.value = false;
    flameSecondsRemaining.value = 0;
    if (flameStartedAt.value != null) {
      hasFlameEnded.value = true;
      
      // Check if premium user has dismissed before
      final isPremium = isPremiumUser.value;
      if (isPremium && _currentMatchId != null) {
        final wasDismissed = SharedPreferenceHelper.getBool(
          'flame_banner_dismissed_${_currentMatchId}',
          defaultValue: false,
        );
        hasDismissedFlameBanner.value = wasDismissed;
        if (wasDismissed) {
          print('✅ DEBUG: Flame expired, banner already dismissed for premium user');
        }
      } else {
        hasDismissedFlameBanner.value = false;
      }
      
      final expires = flameExpiresAt.value ?? DateTime.now();
      nextMessageAvailableAt.value = expires.add(const Duration(days: 1));
    }
  }

  Future<bool> ensureMessagingAllowed() async {
    if (isFlameActive.value) {
      return true;
    }
    if (shouldBlockPostFlameMessaging) {
      _showPostFlameUpgradePrompt();
      return false;
    }
    return true;
  }

  void _showPostFlameUpgradePrompt() {
    final next = nextMessageAvailableAt.value;
    final formatted = next != null
        ? DateFormat('MMM d • h:mm a').format(next)
        : 'tomorrow';

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: UpgradePromptWidget(
          title: 'Continue Chat',
          message: 'You can send your next message $formatted. Upgrade to keep chatting without waiting.',
          action: 'Upgrade Now',
          limitType: 'message',
        ),
      ),
      barrierDismissible: true,
    );
  }

  void handleContinueChat() async {
    if (shouldBlockPostFlameMessaging) {
      _showPostFlameUpgradePrompt();
      return;
    }
    hasDismissedFlameBanner.value = true;
    
    // Store dismissal state for premium users so banner doesn't show again
    final isPremium = isPremiumUser.value;
    if (isPremium && _currentMatchId != null) {
      await SharedPreferenceHelper.setBool(
        'flame_banner_dismissed_${_currentMatchId}',
        true,
      );
      print('✅ DEBUG: Stored flame banner dismissal for match: $_currentMatchId');
    }
  }

  void dismissFlameBanner() async {
    hasDismissedFlameBanner.value = true;
    
    // Store dismissal state for premium users so banner doesn't show again
    final isPremium = isPremiumUser.value;
    if (isPremium && _currentMatchId != null) {
      await SharedPreferenceHelper.setBool(
        'flame_banner_dismissed_${_currentMatchId}',
        true,
      );
      print('✅ DEBUG: Stored flame banner dismissal for match: $_currentMatchId');
    }
  }

  void _resetFlameState() {
    _stopFlameTicker();
    flameStartedAt.value = null;
    flameExpiresAt.value = null;
    flameSecondsRemaining.value = 0;
    isFlameActive.value = false;
    hasFlameEnded.value = false;
    nextMessageAvailableAt.value = null;
    hasDismissedFlameBanner.value = false;
  }

String? _selectionKeyForItem(dynamic item) {
    if (_isBffMode) return null; // Deletion currently not supported for BFF chat backend
    if (item is Message) {
      if (item.id == null || item.id!.isEmpty) return null;
      if (item.isUploading == true) return null;
      if (item.deletedForEveryone) return null;
      return 'msg:${item.id}';
    }
    if (item is AudioMessage) {
      if (item.id.isEmpty) return null;
      if (item.deletedForEveryone) return null;
      return 'aud:${item.id}';
    }
    return null;
  }

  bool isItemSelectable(dynamic item) => _selectionKeyForItem(item) != null;

  bool isItemSelected(dynamic item) {
    final key = _selectionKeyForItem(item);
    if (key == null) return false;
    return selectedMessageKeys.contains(key);
  }

  void startSelectionForItem(dynamic item) {
    final key = _selectionKeyForItem(item);
    if (key == null) return;
    selectedMessageKeys
      ..clear()
      ..add(key);
    selectedMessageKeys.refresh();
    _recalculateSelectionState();
  }

  void toggleSelectionForItem(dynamic item) {
    final key = _selectionKeyForItem(item);
    if (key == null) return;
    if (selectedMessageKeys.contains(key)) {
      selectedMessageKeys.remove(key);
    } else {
      selectedMessageKeys.add(key);
    }
    selectedMessageKeys.refresh();
    _recalculateSelectionState();
  }

  void clearSelection() {
    if (selectedMessageKeys.isEmpty) {
      isSelectionMode.value = false;
      canDeleteForEveryone.value = false;
      return;
    }
    selectedMessageKeys.clear();
    selectedMessageKeys.refresh();
    _recalculateSelectionState(prune: false);
  }

  Future<void> deleteSelectedMessages({required bool forEveryone}) async {
    final items = _collectSelectedItems();
    if (items.isEmpty) {
      clearSelection();
      return;
    }

    final messageIds = <String>[];
    final audioIds = <String>[];

    for (final item in items) {
      if (item.isAudio) {
        audioIds.add(item.audioMessage!.id);
      } else if (item.message?.id != null) {
        messageIds.add(item.message!.id!);
      }
    }

    if (messageIds.isEmpty && audioIds.isEmpty) {
      clearSelection();
      return;
    }

    try {
      if (forEveryone) {
        await SupabaseService.deleteMessagesForEveryone(
          messageIds: messageIds,
          audioMessageIds: audioIds,
        );

        final now = DateTime.now();

        for (final msgId in messageIds) {
          final index = _indexOfMessage(msgId);
          if (index != -1) {
            final existing = messages[index];
            messages[index] = existing.copyWith(
              deletedForEveryone: true,
              deletedAt: now,
            );
          }
        }

        for (final audioId in audioIds) {
          final index = _indexOfAudioMessage(audioId);
          if (index != -1) {
            final existing = audioMessages[index];
            audioMessages[index] = existing.copyWith(
              deletedForEveryone: true,
              deletedAt: now,
            );
          }
        }

        messages.refresh();
        audioMessages.refresh();
      } else {
        await SupabaseService.deleteMessagesForMe(
          messageIds: messageIds,
          audioMessageIds: audioIds,
        );

        if (messageIds.isNotEmpty) {
          messages.removeWhere((m) => m.id != null && messageIds.contains(m.id));
        }
        if (audioIds.isNotEmpty) {
          audioMessages.removeWhere((a) => audioIds.contains(a.id));
        }
      }

      _updateAllSortedMessages();
      clearSelection();
    } catch (e) {
      print('❌ Error deleting messages: $e');
      Get.snackbar('Error', 'Failed to delete messages');
    }
  }

  List<_SelectableChatItem> _collectSelectedItems() {
    final items = <_SelectableChatItem>[];
    for (final key in selectedMessageKeys) {
      final resolved = _resolveSelectableByKey(key);
      if (resolved != null) {
        items.add(resolved);
      }
    }
    return items;
  }

  _SelectableChatItem? _resolveSelectableByKey(String key) {
    if (key.startsWith('msg:')) {
      final id = key.substring(4);
      final message = _findMessageById(id);
      if (message == null) return null;
      return _SelectableChatItem(message: message);
    }
    if (key.startsWith('aud:')) {
      final id = key.substring(4);
      final audio = _findAudioById(id);
      if (audio == null) return null;
      return _SelectableChatItem(audioMessage: audio);
    }
    return null;
  }

  Message? _findMessageById(String id) {
    for (final message in messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  AudioMessage? _findAudioById(String id) {
    for (final audio in audioMessages) {
      if (audio.id == id) return audio;
    }
    return null;
  }

  void _pruneSelection() {
    if (selectedMessageKeys.isEmpty) return;
    final toRemove = <String>[];
    for (final key in selectedMessageKeys) {
      if (_resolveSelectableByKey(key) == null) {
        toRemove.add(key);
      }
    }
    if (toRemove.isNotEmpty) {
      selectedMessageKeys.removeAll(toRemove);
      selectedMessageKeys.refresh();
    }
  }

  void _recalculateSelectionState({bool prune = true}) {
    if (prune) {
      _pruneSelection();
    }

    final hasSelection = selectedMessageKeys.isNotEmpty;
    isSelectionMode.value = hasSelection;

    if (!hasSelection) {
      canDeleteForEveryone.value = false;
      return;
    }

    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) {
      canDeleteForEveryone.value = false;
      return;
    }

    final items = _collectSelectedItems();
    if (items.isEmpty) {
      selectedMessageKeys.clear();
      isSelectionMode.value = false;
      canDeleteForEveryone.value = false;
      return;
    }

    final now = DateTime.now();
    bool allOwned = true;
    bool withinWindow = true;
    bool noneDeleted = true;

    for (final item in items) {
      if (item.senderId != currentUserId) {
        allOwned = false;
        break;
      }

      final elapsed = now.difference(item.timestamp);
      if (elapsed.isNegative || elapsed > const Duration(minutes: 10)) {
        withinWindow = false;
      }

      if (item.isDeletedForEveryone) {
        noneDeleted = false;
      }
    }

    canDeleteForEveryone.value = allOwned && withinWindow && noneDeleted;
  }

  int _indexOfMessage(String id) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].id == id) return i;
    }
    return -1;
  }

  int _indexOfAudioMessage(String id) {
    for (var i = 0; i < audioMessages.length; i++) {
      if (audioMessages[i].id == id) return i;
    }
    return -1;
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) {
        return;
      }

      // Avoid attaching to multiple list views simultaneously (can happen during rebuilds)
      if (scrollController.positions.length != 1) {
        return;
      }

      final position = scrollController.positions.first;
      scrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _updateAllSortedMessages() {
    // Combine text and audio messages
    final allMessages = <dynamic>[];
    allMessages.addAll(messages);
    allMessages.addAll(audioMessages);
    
    print('🔊 DEBUG: _updateAllSortedMessages - Text: ${messages.length}, Audio: ${audioMessages.length}, Total: ${allMessages.length}');
    
    // Sort by timestamp
    allMessages.sort((a, b) {
      DateTime aTime, bTime;
      if (a is Message) {
        aTime = a.timestamp;
      } else if (a is AudioMessage) {
        aTime = a.createdAt;
      } else {
        return 0;
      }
      
      if (b is Message) {
        bTime = b.timestamp;
      } else if (b is AudioMessage) {
        bTime = b.createdAt;
      } else {
        return 0;
      }
      
      return aTime.compareTo(bTime);
    });
    
    // Debug: Print the sorted order
    print('🔍 DEBUG: _updateAllSortedMessages - Final sorted order:');
    for (int i = 0; i < allMessages.length; i++) {
      final msg = allMessages[i];
      if (msg is Message) {
        print('  $i: TEXT "${msg.text}" at ${msg.timestamp}');
      } else if (msg is AudioMessage) {
        print('  $i: AUDIO at ${msg.createdAt}');
      }
    }
    
    allSortedMessages.assignAll(allMessages);
    print('🔍 DEBUG: Updated allSortedMessages with ${allMessages.length} total messages');
  }

  // Audio message methods
  void addAudioMessage(AudioMessage audioMessage) {
    print('🔊 DEBUG: Adding audio message to controller: ${audioMessage.id}');
    print('🔊 DEBUG: Audio message URL: ${audioMessage.audioUrl}');
    print('🔊 DEBUG: Audio messages count before: ${audioMessages.length}');
    audioMessages.add(audioMessage);
    print('🔊 DEBUG: Audio messages count after: ${audioMessages.length}');
    
    // Update allSortedMessages with current text messages + updated audio messages
    _updateAllSortedMessages();
    
    scrollToBottom();
  }

  Future<void> loadAudioMessages(String matchId) async {
    try {
      final response = await SupabaseService.client
          .from('audio_messages')
          .select('*')
          .eq('match_id', matchId)
          .order('created_at', ascending: true);

      final loaded = response.map((data) => AudioMessage.fromMap(data)).toList();
      audioMessages.assignAll(loaded);
    } catch (e) {
      print('❌ Error loading audio messages: $e');
    }
  }

  Future<void> _loadAllMessages(String matchId, bool isBffMatch) async {
    try {
      // Load text messages
      final rows = isBffMatch 
          ? await SupabaseService.getBffMessages(matchId)
          : await SupabaseService.getMessages(matchId);
      final myId = SupabaseService.currentUser?.id;
      
      // Load audio messages
      final audioResponse = await SupabaseService.client
          .from('audio_messages')
          .select('*')
          .eq('match_id', matchId)
          .order('created_at', ascending: true);

      // Process text messages
      final textMessages = rows.map((r) {
        final storyId = (r['story_id'] ?? '').toString();
        // Parse UTC timestamp from database and convert to local time (like audio messages)
        final utcTimestamp = DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now();
        final timestamp = utcTimestamp.toLocal(); // Convert UTC to local
        print('📝 DEBUG: Text message timestamp: $timestamp (${timestamp.toIso8601String()})');

        final senderId = (r['sender_id'] ?? '').toString();
        final id = (r['id'] ?? '').toString();
        final deletedByRaw = r['deleted_by'];
        final deletedByList = deletedByRaw is List
            ? deletedByRaw.map((e) => e.toString()).toList()
            : <String>[];

        if (!isBffMatch && deletedByList.contains(myId)) {
          return null; // Skip messages deleted for current user
        }

        final message = Message(
          id: id.isEmpty ? null : id,
          senderId: senderId,
          text: isBffMatch
              ? (r['text'] ?? '').toString()
              : (r['content'] ?? '').toString(),
          isUser: senderId == (myId ?? ''),
          timestamp: timestamp,
          storyId: storyId.isEmpty ? null : storyId,
          isStoryReply: isBffMatch ? false : (r['is_story_reply'] ?? false) as bool,
          storyUserName: isBffMatch ? null : ((r['story_user_name'] ?? '').toString().isEmpty ? null : (r['story_user_name'] ?? '').toString()),
          storyImageUrl: isBffMatch ? null : null, // Simplified for now
          storyContent: isBffMatch ? null : null,
          storyAuthorName: isBffMatch ? null : null,
          storyCreatedAt: isBffMatch ? null : null,
          isDisappearingPhoto: isBffMatch ? false : (r['is_disappearing_photo'] ?? false) as bool,
          disappearingPhotoId: isBffMatch ? null : ((r['disappearing_photo_id'] ?? '').toString().isEmpty ? null : (r['disappearing_photo_id'] ?? '').toString()),
          deletedForEveryone: isBffMatch ? false : (r['deleted_for_everyone'] ?? false) as bool,
          deletedBy: isBffMatch ? const [] : deletedByList,
          deletedAt: isBffMatch
              ? null
              : r['deleted_at'] != null
                  ? DateTime.tryParse(r['deleted_at'].toString())?.toLocal()
                  : null,
        );
        return message;
      }).whereType<Message>().toList();

      // Process audio messages
      final audioMessagesList = audioResponse.map((data) {
        final audio = AudioMessage.fromMap(data);
        print('🔊 DEBUG: Audio message timestamp: ${audio.createdAt} (${audio.createdAt.toIso8601String()})');
        return audio;
      }).where((audio) {
        if (myId == null) return true;
        return !audio.deletedBy.contains(myId);
      }).toList();

      // Sort all messages by timestamp
      final allMessages = <dynamic>[];
      allMessages.addAll(textMessages);
      allMessages.addAll(audioMessagesList);
      
      // Sort by timestamp
      allMessages.sort((a, b) {
        DateTime aTime, bTime;
        if (a is Message) {
          aTime = a.timestamp;
        } else if (a is AudioMessage) {
          aTime = a.createdAt;
        } else {
          return 0;
        }
        
        if (b is Message) {
          bTime = b.timestamp;
        } else if (b is AudioMessage) {
          bTime = b.createdAt;
        } else {
          return 0;
        }
        
        print('🔍 DEBUG: Comparing ${a.runtimeType} at $aTime vs ${b.runtimeType} at $bTime');
        final result = aTime.compareTo(bTime);
        print('🔍 DEBUG: Sort result: $result (${result < 0 ? 'a before b' : result > 0 ? 'b before a' : 'equal'})');
        return result;
      });

      // Create a single sorted list for the UI
      final sortedMessages = <dynamic>[];
      sortedMessages.addAll(allMessages);
      
      // Update the lists (keep separate for compatibility)
      final sortedTextMessages = <Message>[];
      final sortedAudioMessages = <AudioMessage>[];
      
      for (final msg in allMessages) {
        if (msg is Message) {
          sortedTextMessages.add(msg);
        } else if (msg is AudioMessage) {
          sortedAudioMessages.add(msg);
        }
      }

      messages.assignAll(sortedTextMessages);
      audioMessages.assignAll(sortedAudioMessages);
      
      // Store the combined sorted list for UI
      allSortedMessages.assignAll(sortedMessages);

      _pruneSelection();
      _recalculateSelectionState(prune: false);
      
      print('🔊 DEBUG: Loaded ${sortedTextMessages.length} text and ${sortedAudioMessages.length} audio messages');
      
      // Debug: Show final sorted order
      print('🔍 DEBUG: Final sorted order:');
      for (int i = 0; i < allMessages.length; i++) {
        final msg = allMessages[i];
        if (msg is Message) {
          print('  $i: TEXT "${msg.text}" at ${msg.timestamp}');
        } else if (msg is AudioMessage) {
          print('  $i: AUDIO at ${msg.createdAt}');
        }
      }
      
      scrollToBottom();
      if (_flameInitialized) {
        await _refreshFlameStatus(matchId);
      }
    } catch (e) {
      print('❌ Error loading all messages: $e');
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    try { _channel?.unsubscribe(); } catch (_) {}
    try { _msgStreamSub?.cancel(); } catch (_) {}
    try { _audioStreamSub?.cancel(); } catch (_) {}
    _stopFlameTicker();
    super.onClose();
  }
}

// Message Model
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String senderId;
  final String? storyId;
  final bool isStoryReply;
  final String? storyUserName;
  final String? storyImageUrl;
  final String? storyContent;
  final String? storyAuthorName;
  final DateTime? storyCreatedAt;
  final bool isDisappearingPhoto;
  final String? disappearingPhotoId;
  final String? id;
  final bool? isPhoto;
  final bool? isUploading;
  final Uint8List? photoBytes;
  final String? photoUrl;
  final bool deletedForEveryone;
  final List<String> deletedBy;
  final DateTime? deletedAt;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.senderId = '',
    this.storyId,
    this.isStoryReply = false,
    this.storyUserName,
    this.storyImageUrl,
    this.storyContent,
    this.storyAuthorName,
    this.storyCreatedAt,
    this.isDisappearingPhoto = false,
    this.disappearingPhotoId,
    this.id,
    this.isPhoto = false,
    this.isUploading = false,
    this.photoBytes,
    this.photoUrl,
    bool? deletedForEveryone,
    List<String>? deletedBy,
    this.deletedAt,
  })  : deletedForEveryone = deletedForEveryone ?? false,
        deletedBy = List.unmodifiable(deletedBy ?? const []);

  bool get isDeletedForEveryone => deletedForEveryone;

  Message copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? senderId,
    String? storyId,
    bool? isStoryReply,
    String? storyUserName,
    String? storyImageUrl,
    String? storyContent,
    String? storyAuthorName,
    DateTime? storyCreatedAt,
    bool? isDisappearingPhoto,
    String? disappearingPhotoId,
    String? id,
    bool? isPhoto,
    bool? isUploading,
    Uint8List? photoBytes,
    String? photoUrl,
    bool? deletedForEveryone,
    List<String>? deletedBy,
    DateTime? deletedAt,
  }) {
    return Message(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      storyId: storyId ?? this.storyId,
      isStoryReply: isStoryReply ?? this.isStoryReply,
      storyUserName: storyUserName ?? this.storyUserName,
      storyImageUrl: storyImageUrl ?? this.storyImageUrl,
      storyContent: storyContent ?? this.storyContent,
      storyAuthorName: storyAuthorName ?? this.storyAuthorName,
      storyCreatedAt: storyCreatedAt ?? this.storyCreatedAt,
      isDisappearingPhoto: isDisappearingPhoto ?? this.isDisappearingPhoto,
      disappearingPhotoId: disappearingPhotoId ?? this.disappearingPhotoId,
      id: id ?? this.id,
      isPhoto: isPhoto ?? this.isPhoto,
      isUploading: isUploading ?? this.isUploading,
      photoBytes: photoBytes ?? this.photoBytes,
      photoUrl: photoUrl ?? this.photoUrl,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class _SelectableChatItem {
  final Message? message;
  final AudioMessage? audioMessage;

  const _SelectableChatItem({this.message, this.audioMessage});

  bool get isAudio => audioMessage != null;

  String get senderId => isAudio ? audioMessage!.senderId : (message?.senderId ?? '');

  DateTime get timestamp => isAudio ? audioMessage!.createdAt : (message?.timestamp ?? DateTime.now());

  bool get isDeletedForEveryone => isAudio ? audioMessage!.deletedForEveryone : (message?.deletedForEveryone ?? false);
}

// Add message limit dialog method to MessageController
extension MessageControllerExtensions on MessageController {
  void _showMessageLimitDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          child: MessageLimitWidget(
            onUpgrade: () {
              Get.back(); // Close dialog
              Get.to(() => SubscriptionScreen());
            },
            onDismiss: () => Get.back(),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
