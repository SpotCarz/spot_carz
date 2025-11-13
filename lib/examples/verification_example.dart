import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/verification_service.dart';
import '../services/auth_service.dart';
import '../widgets/verification_result_widget.dart';

/// Example page showing how to use the verification system
class VerificationExamplePage extends StatefulWidget {
  const VerificationExamplePage({super.key});

  @override
  State<VerificationExamplePage> createState() => _VerificationExamplePageState();
}

class _VerificationExamplePageState extends State<VerificationExamplePage> {
  final VerificationService _verificationService = VerificationService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isVerifying = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        if (mounted) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _verifyImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Get user ID
      final authService = AuthService();
      final userId = authService.currentUser?.id ?? 'anonymous';

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const VerificationProgressWidget(
          message: 'Verifying image authenticity...\nThis may take a few moments.',
        ),
      );

      // Perform verification
      final result = await _verificationService.verifyImageAuthenticity(
        imageFile: _selectedImage!,
        userId: userId,
      );

      // Close progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 190, 190, 190),
            title: Text(
              'Verification Result',
              style: GoogleFonts.righteous(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: VerificationResultWidget(result: result),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              if (result.status.toString() == 'authentic')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Proceed with upload
                    _proceedWithUpload();
                  },
                  child: const Text('Continue'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _proceedWithUpload() {
    // This is where you would proceed with your normal upload flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image verified! Proceeding with upload...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Verification Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select Image',
                      style: GoogleFonts.righteous(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImage != null) ...[
                      Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pick from Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Verify Button
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color.fromARGB(255, 145, 1, 202),
                foregroundColor: Colors.white,
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify Image Authenticity',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'How Verification Works',
                          style: GoogleFonts.righteous(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The verification system checks:\n'
                      '• EXIF metadata (camera, GPS, timestamp)\n'
                      '• Reverse image search (internet matches)\n'
                      '• AI generation detection\n\n'
                      'Results are scored 0-100:\n'
                      '✅ Authentic (81-100)\n'
                      '⚠️ Suspicious (50-80)\n'
                      '❌ Likely Fake (0-49)',
                      style: GoogleFonts.righteous(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

