import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'car_detail_page.dart';

class BrandDetailPage extends StatefulWidget {
  final String brand;
  
  const BrandDetailPage({super.key, required this.brand});

  @override
  State<BrandDetailPage> createState() => _BrandDetailPageState();
}

class _BrandDetailPageState extends State<BrandDetailPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<CarSpot> _carSpots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrandCars();
  }

  Future<void> _loadBrandCars() async {
    try {
      final allCarSpots = await _databaseService.getCarSpots();
      if (!mounted) return;
      setState(() {
        _carSpots = allCarSpots.where((spot) => spot.brand == widget.brand).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('BrandDetailPage: Error loading brand cars: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.brand.replaceAll('_', ' '),
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_carSpots.length} cars spotted',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    )
                  : _carSpots.isEmpty
                      ? _buildEmptyState()
                      : _buildCarsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No ${widget.brand.replaceAll('_', ' ')} cars spotted yet',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start spotting ${widget.brand.replaceAll('_', ' ')} cars to build your collection',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCarsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ListView.builder(
        itemCount: _carSpots.length,
        itemBuilder: (context, index) {
          final carSpot = _carSpots[index];
          return _buildCarCard(carSpot);
        },
      ),
    );
  }

  Widget _buildCarCard(CarSpot carSpot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarDetailPage(carSpot: carSpot),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              // Car Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: carSpot.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          carSpot.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.directions_car,
                              color: Colors.grey[400],
                              size: 40,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.directions_car,
                        color: Colors.grey[400],
                        size: 40,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Car Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carSpot.model,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (carSpot.year != null)
                      Text(
                        'Year: ${carSpot.year}',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Spotted: ${carSpot.spottedAt.toString().split(' ')[0]}',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
