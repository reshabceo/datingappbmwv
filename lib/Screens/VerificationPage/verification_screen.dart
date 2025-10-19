import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/supabase_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _challenge;
  String? _photoUrl;
  bool _isLoading = false;
  String _verificationStatus = 'unverified';

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final response = await SupabaseService.client
          .from('profiles')
          .select('verification_status, verification_photo_url, verification_challenge, verification_rejection_reason')
          .eq('id', user.id)
          .single();

      setState(() {
        _verificationStatus = response['verification_status'] ?? 'unverified';
        _photoUrl = response['verification_photo_url'];
        _challenge = response['verification_challenge'];
      });
    } catch (e) {
      print('Error loading verification status: $e');
    }
  }

  Future<void> _getNewChallenge() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseService.client
          .rpc('get_random_verification_challenge');
      
      setState(() {
        _challenge = response;
        _photoUrl = null;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to get challenge: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takeVerificationPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload photo to Supabase storage
      final bytes = await image.readAsBytes();
      final userId = SupabaseService.currentUser!.id;
      final fileName = 'verification_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/verification/$fileName';

      final uploadUrl = await SupabaseService.uploadFile(
        bucket: 'profile-photos',
        path: path,
        fileBytes: bytes,
      );

      if (uploadUrl.isNotEmpty) {
        // Call AI verification edge function
        final response = await SupabaseService.client.functions.invoke(
          'ai-verification',
          body: {
            'userId': userId,
            'verificationPhotoUrl': uploadUrl,
            'challenge': _challenge,
          },
        );

        if (response.data != null) {
          final result = response.data as Map<String, dynamic>;
          final verified = result['verified'] as bool? ?? false;
          final confidence = result['confidence'] as int? ?? 0;
          final reason = result['reason'] as String? ?? 'Unknown error';

          setState(() {
            _photoUrl = uploadUrl;
            _verificationStatus = verified ? 'verified' : 'rejected';
          });

          if (verified) {
            Get.snackbar(
              '🎉 Verification Successful!',
              'Your profile is now verified! Confidence: ${confidence}%',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              '❌ Verification Failed',
              reason,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
        } else {
          Get.snackbar('Error', 'AI verification failed. Please try again.');
        }
      } else {
        Get.snackbar('Error', 'Failed to upload photo');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit verification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_verificationStatus) {
      case 'verified':
        statusColor = Colors.green;
        statusText = 'Verified';
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Under Review';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Not Verified';
        statusIcon = Icons.person_off;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Status: $statusText',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_verificationStatus == 'rejected' && _challenge != null)
                  Text(
                    'Please try again with a clearer photo',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    if (_challenge == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue, size: 48),
            const SizedBox(height: 12),
            Text(
              'Get Verified',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo following our challenge to prove you\'re real',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getNewChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Start Verification'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.gesture, color: Colors.purple, size: 48),
          const SizedBox(height: 16),
          Text(
            'Your Challenge:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _challenge!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (_photoUrl == null) ...[
            ElevatedButton.icon(
              onPressed: _takeVerificationPhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _getNewChallenge,
              child: const Text('Get Different Challenge'),
            ),
          ] else ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_verificationStatus == 'pending')
              const Text(
                'AI is analyzing your photo...',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Get Your Profile Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verified profiles get more matches and trust',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Card
            _buildStatusCard(),
            
            const SizedBox(height: 24),
            
            // Challenge Card
            _buildChallengeCard(),
            
            const SizedBox(height: 24),
            
            // Benefits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Benefits of Verification',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('✓ More profile views'),
                  _buildBenefitItem('✓ Higher match rate'),
                  _buildBenefitItem('✓ Trusted by other users'),
                  _buildBenefitItem('✓ Priority in search results'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[700], fontSize: 14),
      ),
    );
  }
}
