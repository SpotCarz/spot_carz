import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../services/verification_service.dart';
import '../services/auth_service.dart';
import '../widgets/background_container.dart';
import '../widgets/verification_badge.dart';
import '../widgets/verification_result_widget.dart';
import '../models/verification_result.dart';
import '../examples/verification_example.dart';

class CarDetailPage extends StatefulWidget {
  final CarSpot carSpot;
  
  const CarDetailPage({super.key, required this.carSpot});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  final VerificationService _verificationService = VerificationService();
  VerificationResult? _verificationResult;
  bool _isLoadingVerification = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationResult();
  }

  Future<void> _loadVerificationResult() async {
    if (widget.carSpot.imageUrls.isEmpty) {
      debugPrint('CarDetailPage: No image URLs available');
      return;
    }
    
    setState(() {
      _isLoadingVerification = true;
    });

    try {
      final authService = AuthService();
      final userId = authService.currentUser?.id ?? 'anonymous';
      
      debugPrint('CarDetailPage: Loading verification history for user: $userId');
      
      // Try to get verification history and find matching image
      final history = await _verificationService.getVerificationHistory(userId);
      
      debugPrint('CarDetailPage: Found ${history.length} verification results');
      
      if (history.isEmpty) {
        debugPrint('CarDetailPage: No verification history found');
        if (mounted) {
          setState(() {
            _isLoadingVerification = false;
          });
        }
        return;
      }
      
      // Find verification result for this image
      final imageUrl = widget.carSpot.imageUrls.first;
      debugPrint('CarDetailPage: Looking for verification for image: $imageUrl');
      VerificationResult? result;
      
      // Try to match by image URL
      try {
        result = history.firstWhere(
          (r) => r.imageUrl.contains(imageUrl.split('/').last) || 
                 imageUrl.contains(r.imageUrl.split('/').last),
        );
        debugPrint('CarDetailPage: Found verification by URL match');
      } catch (e) {
        debugPrint('CarDetailPage: URL match failed, trying timestamp match');
        // Try to match by timestamp (within 5 minutes of car spot creation)
        try {
          result = history.firstWhere(
            (r) => r.timestamp.isAfter(widget.carSpot.createdAt.subtract(const Duration(minutes: 5))) &&
                   r.timestamp.isBefore(widget.carSpot.createdAt.add(const Duration(minutes: 5))),
          );
          debugPrint('CarDetailPage: Found verification by timestamp match');
        } catch (e2) {
          // Use most recent verification if available
          result = history.isNotEmpty ? history.first : null;
          debugPrint('CarDetailPage: Using most recent verification: ${result != null}');
        }
      }

      if (mounted) {
        setState(() {
          _verificationResult = result;
          _isLoadingVerification = false;
        });
        debugPrint('CarDetailPage: Verification result loaded: ${result != null}');
      }
    } catch (e) {
      debugPrint('CarDetailPage: Error loading verification: $e');
      if (mounted) {
        setState(() {
          _isLoadingVerification = false;
        });
      }
    }
  }

  void _showVerificationDetails() {
    debugPrint('CarDetailPage: _showVerificationDetails called');
    debugPrint('CarDetailPage: _verificationResult is ${_verificationResult != null ? "not null" : "null"}');
    
    if (_verificationResult == null) {
      debugPrint('CarDetailPage: No verification result available');
      
      // Show a dialog explaining why there's no verification
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'No Verification Available',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 155, 155, 155),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This car spot has not been verified yet.',
                style: GoogleFonts.roboto(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'To verify an image:',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Go to the verification example page\n'
                '2. Select an image\n'
                '3. Click "Verify Image Authenticity"\n'
                '4. The verification will be saved automatically',
                style: GoogleFonts.roboto(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerificationExamplePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 145, 1, 202),
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Verification Page'),
            ),
          ],
        ),
      );
      return;
    }
    
    debugPrint('CarDetailPage: Showing verification dialog with result');
    debugPrint('CarDetailPage: Verification score: ${_verificationResult!.verificationScore}');
    debugPrint('CarDetailPage: Verification status: ${_verificationResult!.status.displayName}');
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Verification Details',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: VerificationResultWidget(result: _verificationResult!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Car Card',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Verification Badge
                    if (_isLoadingVerification)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (_verificationResult != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('CarDetailPage: Header badge tapped');
                            _showVerificationDetails();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: VerificationBadge(
                            status: _verificationResult!.status,
                            score: _verificationResult!.verificationScore,
                            showScore: true,
                          ),
                        ),
                      )
                    else
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('CarDetailPage: Unverified badge tapped');
                            _showVerificationDetails();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const UnverifiedBadge(),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Trading Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Center(
                    child: _buildTradingCard(),
                  ),
                ),
              ),
            ],
          ),
      ),
      ),
    );
  }

  Widget _buildTradingCard() {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCardColor(),
                _getCardColor().withValues(alpha: 0.8),
                _getCardColor().withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Column(
            children: [
              // Card Header
              _buildCardHeader(),
              
              // Car Image
              _buildCardImage(),
              
              // Card Content
              _buildCardContent(),
              
              // Card Footer
              _buildCardFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.carSpot.brand.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CAR SPOT CARD',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.carSpot.rarityScore}/10',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            widget.carSpot.imageUrls.isNotEmpty
                ? Image.network(
                    widget.carSpot.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
            // Verification badge overlay on image
            if (_verificationResult != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      debugPrint('CarDetailPage: Image badge tapped');
                      _showVerificationDetails();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: VerificationBadge(
                      status: _verificationResult!.status,
                      score: _verificationResult!.verificationScore,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[700]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 60,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Model Name
          Text(
            widget.carSpot.model.toUpperCase(),
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Stats Grid
          _buildStatsGrid(),
          
          const SizedBox(height: 16),
          
          // Description
          if (widget.carSpot.description != null && widget.carSpot.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.carSpot.description!,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Verification Info Button
          if (_verificationResult != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showVerificationDetails,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View Verification Details',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('YEAR', widget.carSpot.year?.toString() ?? 'N/A'),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildStatItem('COLOR', widget.carSpot.color ?? 'N/A'),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildStatItem('SPOTTED', widget.carSpot.spottedAt.toString().split(' ')[0]),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Likes
          _buildFooterItem(Icons.favorite, widget.carSpot.likesCount.toString()),
          
          // Comments
          _buildFooterItem(Icons.comment, widget.carSpot.commentsCount.toString()),
          
          // License Plate
          if (widget.carSpot.licensePlate != null && widget.carSpot.licensePlate!.isNotEmpty)
            _buildFooterItem(Icons.local_parking, widget.carSpot.licensePlate!),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Color _getCardColor() {
    // Different colors based on brand
    switch (widget.carSpot.brand.toUpperCase()) {
      case 'FERRARI':
        return const Color(0xFFDC143C); // Crimson Red
      case 'BMW':
        return const Color(0xFF0066CC); // BMW Blue
      case 'MERCEDES':
        return const Color(0xFF000000); // Black
      case 'AUDI':
        return const Color(0xFFCC0000); // Audi Red
      case 'PORSCHE':
        return const Color(0xFF000000); // Black
      case 'LAMBORGHINI':
        return const Color(0xFFFFD700); // Gold
      case 'MCLAREN':
        return const Color(0xFFFF6600); // Orange
      case 'ASTON_MARTIN':
        return const Color(0xFF003366); // Dark Blue
      case 'BENTLEY':
        return const Color(0xFF8B4513); // Saddle Brown
      case 'ROLLS_ROYCE':
        return const Color(0xFFC0C0C0); // Silver
      case 'TESLA':
        return const Color(0xFF00FF00); // Electric Green
      default:
        return const Color(0xFF666666); // Default Gray
    }
  }
}
