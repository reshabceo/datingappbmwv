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
  int _currentStep = 0; // 0: Intro, 1: Challenge, 2: Results

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
            _currentStep = 2; // Move to results step
          });

          if (verified) {
            Get.snackbar(
              '🎉 Verification Successful!',
              'Your profile is now verified! Confidence: ${confidence}%',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          } else {
            Get.snackbar(
              '❌ Verification Failed',
              reason,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getStepTitle(),
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _handleBack(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
        child: Column(
        children: [
              // Progress Indicator
              _buildProgressIndicator(),
              
              const SizedBox(height: 40),
              
              // Step Content
          Expanded(
                child: _buildStepContent(),
              ),
              
              // Navigation Buttons
              _buildNavigationButtons(),
              ],
            ),
          ),
      ),
    );
  }

  // Helper methods for step-by-step flow
  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Get Verified';
      case 1: return 'Take Photo';
      case 2: return 'Results';
      default: return 'Verification';
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Get.back();
    }
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: index <= _currentStep 
                ? const Color(0xFF00D4FF) 
                : Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildIntroStep();
      case 1: return _buildChallengeStep();
      case 2: return _buildResultsStep();
      default: return _buildIntroStep();
    }
  }

  Widget _buildIntroStep() {
    return Column(
      children: [
        // Main Icon
        Container(
          width: 120,
          height: 120,
        decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.verified_user,
            size: 60,
            color: Color(0xFF00D4FF),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Title
        const Text(
          'Get Your Profile Verified',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Subtitle
        Text(
          'Verified profiles get more matches and trust from other users',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // Benefits
        _buildSimpleBenefits(),
      ],
    );
  }

  Widget _buildSimpleBenefits() {
    final benefits = [
      'More profile views',
      'Higher match rate', 
      'Trusted by others',
    ];
    
    return Column(
      children: benefits.map((benefit) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00D4FF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              benefit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildChallengeStep() {
    if (_challenge == null) {
      return _buildGetChallengeView();
    }
    
    return Column(
      children: [
        // Challenge Display
            Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.3),
              width: 1,
            ),
      ),
      child: Column(
        children: [
              const Icon(
                Icons.gesture,
                color: Color(0xFF00D4FF),
                size: 48,
              ),
          const SizedBox(height: 16),
              const Text(
            'Your Challenge:',
            style: TextStyle(
                  color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
              Text(
              _challenge!,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Photo Display or Camera Button
        if (_photoUrl == null) ...[
          _buildCameraButton(),
          const SizedBox(height: 16),
            TextButton(
              onPressed: _getNewChallenge,
            child: const Text(
              'Try Different Challenge',
              style: TextStyle(color: Colors.grey),
            ),
            ),
          ] else ...[
          _buildPhotoPreview(),
          if (_verificationStatus == 'pending')
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'AI is analyzing your photo...',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGetChallengeView() {
    return Column(
                children: [
        const Icon(
          Icons.camera_alt,
          color: Color(0xFF00D4FF),
          size: 80,
        ),
        const SizedBox(height: 24),
                  const Text(
          'Ready to Get Verified?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        const SizedBox(height: 12),
                  Text(
          'Take a photo following our simple challenge to prove you\'re real',
                    style: TextStyle(
            color: Colors.grey[400],
                      fontSize: 16,
                    ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCameraButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _takeVerificationPhoto,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.camera_alt, size: 20),
                SizedBox(width: 8),
                      Text(
                  'Take Photo',
                        style: TextStyle(
                          fontSize: 16,
                    fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_verificationStatus == 'verified') {
      return _buildSuccessView();
    } else if (_verificationStatus == 'rejected') {
      return _buildRejectionView();
    } else {
      return _buildPendingView();
    }
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verification Successful!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your profile is now verified and trusted by other users',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRejectionView() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.cancel,
            size: 60,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verification Failed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please try again with a clearer photo',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPendingView() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const CircularProgressIndicator(
            color: Color(0xFF00D4FF),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verification in Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Our AI is analyzing your photo. This usually takes a few seconds.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            setState(() => _currentStep = 1);
            _getNewChallenge();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Get Started',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (_currentStep == 1) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep = 0),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
          if (_photoUrl != null && _verificationStatus != 'pending') ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (_verificationStatus == 'verified') {
              Get.back();
            } else {
              setState(() {
                _currentStep = 1;
                _photoUrl = null;
                _verificationStatus = 'unverified';
              });
              _getNewChallenge();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _verificationStatus == 'verified' 
              ? Colors.green 
              : const Color(0xFF00D4FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _verificationStatus == 'verified' ? 'Done' : 'Try Again',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }
}
