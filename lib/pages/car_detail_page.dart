import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../widgets/background_container.dart';

class CarDetailPage extends StatelessWidget {
  final CarSpot carSpot;
  
  const CarDetailPage({super.key, required this.carSpot});

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
                  carSpot.brand.replaceAll('_', ' ').toUpperCase(),
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
              '${carSpot.rarityScore}/10',
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
        child: carSpot.imageUrls.isNotEmpty
            ? Image.network(
                carSpot.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
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
            carSpot.model.toUpperCase(),
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
          if (carSpot.description != null && carSpot.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                carSpot.description!,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('YEAR', carSpot.year?.toString() ?? 'N/A'),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildStatItem('COLOR', carSpot.color ?? 'N/A'),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        Expanded(
          child: _buildStatItem('SPOTTED', carSpot.spottedAt.toString().split(' ')[0]),
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
          _buildFooterItem(Icons.favorite, carSpot.likesCount.toString()),
          
          // Comments
          _buildFooterItem(Icons.comment, carSpot.commentsCount.toString()),
          
          // License Plate
          if (carSpot.licensePlate != null && carSpot.licensePlate!.isNotEmpty)
            _buildFooterItem(Icons.local_parking, carSpot.licensePlate!),
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
    switch (carSpot.brand.toUpperCase()) {
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
