import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lovebug/services/supabase_service.dart';
import 'package:lovebug/ThemeController/theme_controller.dart';

class AstroCompatibilityWidget extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String otherUserZodiac;
  final bool visible;
  final bool autoGenerateIfMissing;

  const AstroCompatibilityWidget({
    Key? key,
    required this.matchId,
    required this.otherUserName,
    required this.otherUserZodiac,
    this.visible = true,
    this.autoGenerateIfMissing = true,
  }) : super(key: key);

  @override
  State<AstroCompatibilityWidget> createState() => _AstroCompatibilityWidgetState();
}

class _AstroCompatibilityWidgetState extends State<AstroCompatibilityWidget> {
  final ThemeController themeController = Get.find<ThemeController>();
  Map<String, dynamic>? matchEnhancements;
  bool isLoading = true;
  bool hasError = false;
  bool iceBreakersUsed = false;

  @override
  void initState() {
    super.initState();
    loadMatchEnhancements();
  }

  Future<void> loadMatchEnhancements() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Check if enhancements already exist
      final existing = await SupabaseService.client
          .from('match_enhancements')
          .select('*')
          .eq('match_id', widget.matchId)
          .maybeSingle();

      if (existing != null && 
          existing['expires_at'] != null && 
          DateTime.parse(existing['expires_at']).isAfter(DateTime.now())) {
        // Also check if any ice breaker was already used for this match
        await _checkIceBreakerUsage();
        setState(() {
          matchEnhancements = existing;
          isLoading = false;
        });
        return;
      }

      // Do not auto-generate unless enabled
      if (widget.autoGenerateIfMissing) {
        await generateEnhancements();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading match enhancements: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // Exposed to parent via GlobalKey
  Future<void> generateFromParent() async {
    await generateEnhancements();
  }

  void setVisible(bool v) {
    if (mounted) setState(() {});
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

  Future<void> generateEnhancements() async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'generate-match-insights',
        body: {'match_id': widget.matchId},
      );
      
      final data = response.data;

      if (data != null && data['success'] == true) {
        // Reload the data from database
        final updated = await SupabaseService.client
            .from('match_enhancements')
            .select('*')
            .eq('match_id', widget.matchId)
            .maybeSingle();

        setState(() {
          matchEnhancements = updated;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to generate enhancements');
      }
    } catch (e) {
      print('Error generating enhancements: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  String getZodiacEmoji(String sign) {
    const emojis = {
      'aries': '♈', 'taurus': '♉', 'gemini': '♊', 'cancer': '♋',
      'leo': '♌', 'virgo': '♍', 'libra': '♎', 'scorpio': '♏',
      'sagittarius': '♐', 'capricorn': '♑', 'aquarius': '♒', 'pisces': '♓'
    };
    return emojis[sign.toLowerCase()] ?? '⭐';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return SizedBox.shrink();
    if (isLoading) {
      return Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: themeController.isDarkMode.value 
              ? Colors.grey[800] 
              : Colors.purple[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: themeController.isDarkMode.value 
                ? Colors.purple[300]! 
                : Colors.purple[200]!,
          ),
        ),
        child: Row(
          children: [
            CircularProgressIndicator(
              color: Colors.purple[400],
              strokeWidth: 2,
            ),
            SizedBox(width: 12.w),
            Text(
              'Generating compatibility insights...',
              style: TextStyle(
                color: themeController.isDarkMode.value 
                    ? Colors.white 
                    : Colors.purple[700],
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
              ? Colors.red[900] 
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
                'Unable to load compatibility insights',
                style: TextStyle(
                  color: themeController.isDarkMode.value 
                      ? Colors.white 
                      : Colors.red[700],
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: loadMatchEnhancements,
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

    if (matchEnhancements == null) {
      return SizedBox.shrink();
    }

    final astroData = matchEnhancements!['astro_compatibility'] as Map<String, dynamic>?;
    final iceBreakers = matchEnhancements!['ice_breakers'] as List<dynamic>?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          // Astrological Compatibility Card ONLY
          if (astroData != null) _buildCompatibilityCard(astroData),
          // REMOVED: Ice Breakers Card - conversation starters should not appear in astro panel
        ],
      ),
    );
  }

  Widget _buildCompatibilityCard(Map<String, dynamic> astroData) {
    final score = astroData['compatibility_score'] ?? 75;
    final summary = astroData['summary'] ?? 'Great compatibility!';
    final strengths = List<String>.from(astroData['strengths'] ?? []);
    final romanticOutlook = astroData['romantic_outlook'] ?? 'Strong potential!';
    final advice = astroData['advice'] ?? 'Enjoy getting to know each other!';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeController.isDarkMode.value
              ? [Colors.purple[800]!, Colors.pink[800]!]
              : [Colors.purple[50]!, Colors.pink[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeController.isDarkMode.value 
              ? Colors.purple[300]! 
              : Colors.purple[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.purple[400],
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Astrological Compatibility',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: themeController.isDarkMode.value 
                        ? Colors.white 
                        : Colors.purple[700],
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$score% Match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            summary,
            style: TextStyle(
              color: themeController.isDarkMode.value 
                  ? Colors.white70 
                  : Colors.purple[600],
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          if (strengths.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Strengths:',
              style: TextStyle(
                color: themeController.isDarkMode.value 
                    ? Colors.green[300] 
                    : Colors.green[700],
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            ...strengths.take(3).map((strength) => Padding(
              padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
              child: Text(
                '• $strength',
                style: TextStyle(
                  color: themeController.isDarkMode.value 
                      ? Colors.white70 
                      : Colors.purple[600],
                  fontSize: 13.sp,
                ),
              ),
            )),
          ],
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: themeController.isDarkMode.value 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Romantic Outlook',
                  style: TextStyle(
                    color: themeController.isDarkMode.value 
                        ? Colors.pink[300] 
                        : Colors.pink[700],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  romanticOutlook,
                  style: TextStyle(
                    color: themeController.isDarkMode.value 
                        ? Colors.white70 
                        : Colors.purple[600],
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Advice',
                  style: TextStyle(
                    color: themeController.isDarkMode.value 
                        ? Colors.blue[300] 
                        : Colors.blue[700],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  advice,
                  style: TextStyle(
                    color: themeController.isDarkMode.value 
                        ? Colors.white70 
                        : Colors.purple[600],
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceBreakersCard(List<dynamic> iceBreakers) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeController.isDarkMode.value
              ? [Colors.blue[800]!, Colors.cyan[800]!]
              : [Colors.blue[50]!, Colors.cyan[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: themeController.isDarkMode.value 
              ? Colors.blue[300]! 
              : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.blue[400],
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Conversation Starters',
                style: TextStyle(
                  color: themeController.isDarkMode.value 
                      ? Colors.white 
                      : Colors.blue[700],
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...iceBreakers.take(3).map((iceBreaker) => _buildIceBreakerItem(iceBreaker)),
        ],
      ),
    );
  }

  Widget _buildIceBreakerItem(Map<String, dynamic> iceBreaker) {
    final question = iceBreaker['question'] ?? '';
    final category = iceBreaker['category'] ?? 'general';
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: themeController.isDarkMode.value 
            ? Colors.white.withOpacity(0.1) 
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: themeController.isDarkMode.value 
              ? Colors.blue[300]! 
              : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                color: themeController.isDarkMode.value 
                    ? Colors.white 
                    : Colors.blue[800],
                fontSize: 14.sp,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              category.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () async {
              final currentUserId = SupabaseService.currentUser?.id;
              if (currentUserId == null) return;
              try {
                await SupabaseService.client
                    .from('ice_breaker_usage')
                    .insert({
                  'match_id': widget.matchId,
                  'ice_breaker_text': question,
                  'used_by_user_id': currentUserId,
                });
                setState(() {
                  iceBreakersUsed = true;
                });
              } catch (_) {}
            },
            child: Text(
              'Use',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
