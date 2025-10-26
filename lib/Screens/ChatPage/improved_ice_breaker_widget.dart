import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';

class ImprovedIceBreakerWidget extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String? currentUserZodiac;

  const ImprovedIceBreakerWidget({
    Key? key,
    required this.matchId,
    required this.otherUserName,
    this.currentUserZodiac,
  }) : super(key: key);

  @override
  State<ImprovedIceBreakerWidget> createState() => _ImprovedIceBreakerWidgetState();
}

class _ImprovedIceBreakerWidgetState extends State<ImprovedIceBreakerWidget> {
  final ThemeController themeController = Get.find<ThemeController>();
  List<Map<String, dynamic>> iceBreakers = [];
  bool isLoading = true;
  bool hasError = false;
  bool iceBreakersUsed = false;
  String? usedByUserId;
  String? usedIceBreakerText;
  DateTime? usedAt;
  
  StreamSubscription? _usageSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadIceBreakers();
    _startUsageMonitoring();
  }

  @override
  void dispose() {
    _usageSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startUsageMonitoring() {
    // Monitor icebreaker usage in real-time
    _usageSubscription = SupabaseService.client
        .from('ice_breaker_usage')
        .stream(primaryKey: ['id'])
        .eq('match_id', widget.matchId)
        .listen((data) {
      print('🔄 Icebreaker usage updated: $data');
      _checkIceBreakerUsage();
    });

    // Also check periodically as backup
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkIceBreakerUsage();
    });
  }

  Future<void> loadIceBreakers() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Check if icebreakers are already used
      await _checkIceBreakerUsage();
      
      if (iceBreakersUsed) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get icebreakers using the new function
      final result = await SupabaseService.client.rpc(
        'get_match_icebreakers',
        params: {
          'p_match_id': widget.matchId,
          'p_user_id': SupabaseService.currentUser?.id ?? '',
        },
      );

      if (result != null && result.isNotEmpty) {
        final data = result.first;
        final shouldShow = data['should_show'] as bool? ?? false;
        final iceBreakersData = data['ice_breakers'] as List<dynamic>?;

        if (shouldShow && iceBreakersData != null) {
          setState(() {
            iceBreakers = iceBreakersData.cast<Map<String, dynamic>>();
            isLoading = false;
          });
        } else {
          setState(() {
            iceBreakersUsed = true;
            isLoading = false;
          });
        }
      } else {
        // No icebreakers exist, try to generate them
        await generateIceBreakers();
      }
    } catch (e) {
      print('❌ Error loading icebreakers: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _checkIceBreakerUsage() async {
    try {
      final result = await SupabaseService.client.rpc(
        'get_icebreaker_usage_status',
        params: {'p_match_id': widget.matchId},
      );

      if (result != null && result.isNotEmpty) {
        final data = result.first;
        final hasBeenUsed = data['has_been_used'] as bool? ?? false;
        
        if (hasBeenUsed && mounted) {
          setState(() {
            iceBreakersUsed = true;
            usedByUserId = data['used_by_user_id']?.toString();
            usedIceBreakerText = data['used_ice_breaker_text']?.toString();
            usedAt = data['used_at'] != null 
                ? DateTime.parse(data['used_at'].toString())
                : null;
          });
        }
      }
    } catch (e) {
      print('❌ Error checking icebreaker usage: $e');
    }
  }

  Future<void> generateIceBreakers() async {
    try {
      final resp = await SupabaseService.client.functions.invoke(
        'generate-match-insights',
        body: {'match_id': widget.matchId},
      );

      if (resp.data != null && resp.data['success'] == true) {
        final iceBreakersData = resp.data['ice_breakers'] as List<dynamic>?;
        if (iceBreakersData != null) {
          setState(() {
            iceBreakers = iceBreakersData.cast<Map<String, dynamic>>();
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error generating icebreakers: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (hasError) {
      return _buildErrorWidget();
    }

    if (iceBreakersUsed) {
      return _buildUsedWidget();
    }

    if (iceBreakers.isEmpty) {
      return SizedBox.shrink();
    }

    return _buildIceBreakersCard();
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeController.isDarkMode.value 
            ? Colors.grey[800] 
            : Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeController.isDarkMode.value 
              ? Colors.blue[300]! 
              : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            color: Colors.blue[400],
            strokeWidth: 2,
          ),
          SizedBox(width: 12.w),
          Text(
            'Generating conversation starters...',
            style: TextStyle(
              color: themeController.isDarkMode.value 
                  ? Colors.white 
                  : Colors.blue[700],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeController.isDarkMode.value 
            ? Colors.red[800] 
            : Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeController.isDarkMode.value 
              ? Colors.red[300]! 
              : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Unable to load conversation starters',
              style: TextStyle(
                color: themeController.isDarkMode.value 
                    ? Colors.white 
                    : Colors.red[700],
                fontSize: 14.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: loadIceBreakers,
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsedWidget() {
    final currentUserId = SupabaseService.currentUser?.id;
    final isUsedByCurrentUser = usedByUserId == currentUserId;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: themeController.isDarkMode.value 
            ? Colors.green[800] 
            : Colors.green[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeController.isDarkMode.value 
              ? Colors.green[300]! 
              : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green[400],
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              isUsedByCurrentUser 
                  ? 'You started the conversation! 🎉'
                  : '${widget.otherUserName} started the conversation! 💬',
              style: TextStyle(
                color: themeController.isDarkMode.value 
                    ? Colors.white 
                    : Colors.green[700],
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceBreakersCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Text(
              'Conversation Starters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Ice breaker bubbles
          ...iceBreakers.take(3).map((iceBreaker) => _buildIceBreakerBubble(iceBreaker)).toList(),
        ],
      ),
    );
  }

  Widget _buildIceBreakerBubble(Map<String, dynamic> iceBreaker) {
    String question = (iceBreaker['question'] ?? '').toString();
    final category = iceBreaker['category'] ?? 'general';

    // Personalize astrology questions
    if (category.toString().toLowerCase() == 'astrology' && (widget.currentUserZodiac ?? '').isNotEmpty) {
      const signs = [
        'aries','taurus','gemini','cancer','leo','virgo','libra','scorpio','sagittarius','capricorn','aquarius','pisces'
      ];
      for (final s in signs) {
        question = question.replaceAll(RegExp('fellow\\s+$s', caseSensitive: false), 'fellow ${widget.currentUserZodiac}');
        question = question.replaceAll(RegExp('as a $s', caseSensitive: false), 'as a ${widget.currentUserZodiac}');
      }
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
      child: GestureDetector(
        onTap: () => _sendIceBreaker(question),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeController.isDarkMode.value
                  ? [themeController.getAccentColor().withOpacity(0.2), Colors.purple.withOpacity(0.15)]
                  : [themeController.getAccentColor().withOpacity(0.15), Colors.purple.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: themeController.isDarkMode.value 
                  ? themeController.getAccentColor().withOpacity(0.3)
                  : themeController.getAccentColor().withOpacity(0.2),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.purple[400],
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendIceBreaker(String question) async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;
    
    try {
      // Send the ice breaker as a message
      await SupabaseService.sendMessage(
        matchId: widget.matchId,
        content: question,
      );
      
      // Mark ice breaker as used using the new function
      await SupabaseService.client.rpc(
        'mark_icebreaker_used',
        params: {
          'p_match_id': widget.matchId,
          'p_ice_breaker_text': question,
          'p_user_id': currentUserId,
        },
      );
      
      // Update local state
      setState(() {
        iceBreakersUsed = true;
        usedByUserId = currentUserId;
        usedIceBreakerText = question;
        usedAt = DateTime.now();
      });
      
      print('✅ Icebreaker sent and marked as used: $question');
    } catch (e) {
      print('❌ Error sending icebreaker: $e');
      Get.snackbar('Error', 'Failed to send conversation starter');
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hobbies':
        return Colors.green[600]!;
      case 'astrology':
        return Colors.purple[600]!;
      case 'lifestyle':
        return Colors.orange[600]!;
      default:
        return Colors.blue[600]!;
    }
  }
}
