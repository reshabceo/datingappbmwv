import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';

class IceBreakerWidget extends StatefulWidget {
  final String matchId;
  final String otherUserName;

  const IceBreakerWidget({
    Key? key,
    required this.matchId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<IceBreakerWidget> createState() => _IceBreakerWidgetState();
}

class _IceBreakerWidgetState extends State<IceBreakerWidget> {
  final ThemeController themeController = Get.find<ThemeController>();
  List<Map<String, dynamic>> iceBreakers = [];
  bool isLoading = true;
  bool hasError = false;
  bool iceBreakersUsed = false;

  @override
  void initState() {
    super.initState();
    loadIceBreakers();
  }

  Future<void> loadIceBreakers() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Check if any ice breaker was already used for this match
      await _checkIceBreakerUsage();
      
      if (iceBreakersUsed) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Check if ice breakers already exist in match_enhancements
      final existing = await SupabaseService.client
          .from('match_enhancements')
          .select('ice_breakers')
          .eq('match_id', widget.matchId)
          .maybeSingle();

      if (existing != null && existing['ice_breakers'] != null) {
        // Ice breakers already exist, use them
        final iceBreakersData = existing['ice_breakers'] as List<dynamic>?;
        if (iceBreakersData != null) {
          setState(() {
            iceBreakers = iceBreakersData.cast<Map<String, dynamic>>();
            isLoading = false;
          });
          return;
        }
      }

      // No ice breakers exist, try to generate them
      await generateIceBreakers();
    } catch (e) {
      print('Error loading ice breakers: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _checkIceBreakerUsage() async {
    try {
      final rows = await SupabaseService.client
          .from('ice_breaker_usage')
          .select('id')
          .eq('match_id', widget.matchId)
          .limit(1);
      setState(() {
        iceBreakersUsed = (rows as List).isNotEmpty;
      });
    } catch (_) {
      setState(() {
        iceBreakersUsed = false;
      });
    }
  }

  Future<void> generateIceBreakers() async {
    try {
      final resp = await SupabaseService.client.functions.invoke(
        'generate-match-insights',
        body: {'matchId': widget.matchId},
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
      print('Error generating ice breakers: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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

    if (hasError) {
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

    if (iceBreakersUsed || iceBreakers.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: _buildIceBreakersCard(),
    );
  }

  Widget _buildIceBreakersCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            'Icebreakers',
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
    );
  }

  Widget _buildIceBreakerBubble(Map<String, dynamic> iceBreaker) {
    final question = iceBreaker['question'] ?? '';
    final category = iceBreaker['category'] ?? 'general';
    
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
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    try {
      // Send the ice breaker as a message
      await SupabaseService.sendMessage(
        matchId: widget.matchId,
        content: question,
      );
      
      // Mark ice breaker as used
      await SupabaseService.client
          .from('ice_breaker_usage')
          .insert({
        'match_id': widget.matchId,
        'ice_breaker_text': question,
        'used_by_user_id': currentUserId,
      });
      
      // Hide the ice breakers
      setState(() {
        iceBreakersUsed = true;
      });
    } catch (e) {
      print('Error sending ice breaker: $e');
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
