import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../widgets/background_container.dart';
import '../data/car_brands.dart';
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
  List<String> _allModels = [];
  bool _isLoading = true;
  String? _selectedCoverModel; // Track which model is selected as cover image

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCoverImageSelection();
  }

  Future<void> _loadCoverImageSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedBrand = widget.brand.toUpperCase().replaceAll(' ', '_');
      final coverModel = prefs.getString('brand_cover_$normalizedBrand');
      if (mounted) {
        setState(() {
          _selectedCoverModel = coverModel;
        });
      }
    } catch (e) {
      debugPrint('BrandDetailPage: Error loading cover image selection: $e');
    }
  }

  Future<void> _saveCoverImageSelection(String? model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedBrand = widget.brand.toUpperCase().replaceAll(' ', '_');
      if (model != null) {
        await prefs.setString('brand_cover_$normalizedBrand', model);
      } else {
        await prefs.remove('brand_cover_$normalizedBrand');
      }
      setState(() {
        _selectedCoverModel = model;
      });
    } catch (e) {
      debugPrint('BrandDetailPage: Error saving cover image selection: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final allCarSpots = await _databaseService.getCarSpots();
      
      // Normalize brand name for matching (handle case differences)
      final normalizedBrand = widget.brand.toUpperCase().replaceAll(' ', '_');
      
      // Find cars matching this brand (case-insensitive)
      final brandCars = allCarSpots.where((spot) {
        final spotBrand = spot.brand.toUpperCase().replaceAll(' ', '_');
        return spotBrand == normalizedBrand;
      }).toList();
      
      debugPrint('BrandDetailPage: Loading data for brand: ${widget.brand}');
      debugPrint('BrandDetailPage: Normalized brand: $normalizedBrand');
      debugPrint('BrandDetailPage: Found ${brandCars.length} cars for this brand');
      if (brandCars.isNotEmpty) {
        debugPrint('BrandDetailPage: Car spots: ${brandCars.map((c) => '${c.brand} - ${c.model}').join(', ')}');
      }
      
      // Try to get models - handle different brand name formats
      // car_brands.dart uses uppercase brand names like "FERRARI", "ASTON_MARTIN"
      String brandKey = widget.brand.toUpperCase().replaceAll(' ', '_');
      _allModels = CarBrandsData.getModelsForBrand(brandKey);
      
      // If still empty, try other variations
      if (_allModels.isEmpty) {
        _allModels = CarBrandsData.getModelsForBrand(widget.brand.toUpperCase());
      }
      if (_allModels.isEmpty) {
        _allModels = CarBrandsData.getModelsForBrand(widget.brand);
      }
      
      debugPrint('BrandDetailPage: Found ${_allModels.length} models for brand: ${widget.brand} (key: $brandKey)');
      
      // Auto-select first owned car as cover if no cover is selected
      if (_selectedCoverModel == null && brandCars.isNotEmpty) {
        final firstCar = brandCars.first;
        await _saveCoverImageSelection(firstCar.model);
        debugPrint('BrandDetailPage: Auto-selected first owned car as cover: ${firstCar.model}');
      }
      
      if (!mounted) return;
      setState(() {
        _carSpots = brandCars;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('BrandDetailPage: Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  CarSpot? _getCarSpotForModel(String model) {
    return _carSpots.firstWhere(
      (spot) => spot.model.toLowerCase().trim() == model.toLowerCase().trim(),
      orElse: () => CarSpot(
        brand: widget.brand,
        model: model,
        imageUrls: [],
        spottedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  bool _isModelOwned(String model) {
    return _carSpots.any((spot) => 
      spot.model.toLowerCase().trim() == model.toLowerCase().trim()
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
              // Brand Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.purple[900]!.withValues(alpha: 0.8),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/back.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.arrow_back, color: Colors.white, size: 24);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Brand name
                    Expanded(
                      child: Text(
                        widget.brand.replaceAll('_', ' '),
                        style: GoogleFonts.righteous(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Model count and owned count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_allModels.length} modèles',
                          style: GoogleFonts.righteous(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_carSpots.length} Possédée${_carSpots.length > 1 ? 's' : ''}',
                          style: GoogleFonts.righteous(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Models Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _allModels.isEmpty
                        ? Center(
                            child: Text(
                              'No models found',
                              style: GoogleFonts.righteous(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : _buildModelsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _allModels.length,
        itemBuilder: (context, index) {
          final model = _allModels[index];
          final isOwned = _isModelOwned(model);
          final carSpot = isOwned 
              ? _carSpots.firstWhere((spot) => 
                  spot.model.toLowerCase().trim() == model.toLowerCase().trim()
                ) 
              : null;
          return _buildModelCard(model, isOwned, carSpot);
        },
      ),
    );
  }

  Widget _buildModelCard(String model, bool isOwned, CarSpot? carSpot) {
    final isSelected = _selectedCoverModel != null && 
                       _selectedCoverModel!.toLowerCase().trim() == model.toLowerCase().trim();
    
    return Stack(
      children: [
        InkWell(
          onTap: isOwned && carSpot != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarDetailPage(carSpot: carSpot),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? Colors.purple[400]! 
                    : Colors.white.withValues(alpha: 0.3), 
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Car Image or Placeholder
                  Expanded(
                    flex: 5,
                    child: isOwned && carSpot != null && carSpot.imageUrls.isNotEmpty
                        ? Image.network(
                            carSpot.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildNotFoundPlaceholder();
                            },
                          )
                        : _buildNotFoundPlaceholder(),
                  ),
                  // Model name
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text(
                      model,
                      style: GoogleFonts.righteous(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Checkbox for owned models
        if (isOwned)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                if (isSelected) {
                  _saveCoverImageSelection(null);
                } else {
                  _saveCoverImageSelection(model);
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.purple[700]! 
                      : Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotFoundPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple[800]!.withValues(alpha: 0.3),
            Colors.purple[900]!.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Non trouvée',
            style: GoogleFonts.righteous(
              fontSize: 12,
              color: Colors.purple[300]!.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.directions_car,
            size: 50,
            color: Colors.purple[300]!.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
