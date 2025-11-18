// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../data/car_brands.dart';
import 'login_page.dart';
import 'brand_detail_page.dart';
import 'car_detail_page.dart';
import 'settings_page.dart';
import 'create_post_page.dart';
import '../examples/verification_example.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  final List<CarSpot> _carSpots = [];
  final List<String> _brands = [];
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBrand; // Track which brand is currently expanded
  CarSpot? _selectedCar; // Track which car is currently selected
  
  // Feed data
  List<Map<String, dynamic>> _feedPosts = [];
  bool _isLoadingFeed = false;
  int _selectedFeedTab = 0; // 0 = Découvertes, 1 = Suivis
  bool _feedLoaded = false; // Track if feed has been loaded
  bool _feedLoadScheduled = false; // Prevent multiple load attempts
  Map<String, bool> _postLikedCache = {}; // Cache for like status

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      debugPrint('Dashboard: Loading car spots and brands...');
      
      // Create default data for new users
      await _databaseService.createDefaultData();
      
      final carSpots = await _databaseService.getCarSpots();
      final brands = await _databaseService.getBrands();
      
      debugPrint('Dashboard: Loaded ${carSpots.length} car spots and ${brands.length} brands');
      
      if (mounted) {
        setState(() {
          _carSpots.clear();
          _carSpots.addAll(carSpots);
          _brands.clear();
          _brands.addAll(brands);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard: Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              _buildCollectionTab(),
              _buildSpotTab(),
              _buildFeedTab(),
              _buildProfileTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // Reset feed loaded flag when switching away from feed tab
            if (_selectedIndex == 3 && index != 3) {
              _feedLoaded = false;
              _feedLoadScheduled = false;
            }
            setState(() => _selectedIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 0 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/menu_icons/garage.png',
                  width: 24,
                  height: 24,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 1 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/menu_icons/catalog.png',
                  width: 24,
                  height: 24,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 2 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/menu_icons/add.png',
                  width: 24,
                  height: 24,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 3 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/menu_icons/feed.png',
                  width: 24,
                  height: 24,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 4 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/menu_icons/user_profile.png',
                  width: 24,
                  height: 24,
                ),
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final filteredBrands = _searchQuery.isEmpty
        ? _brands
        : _brands.where((brand) => brand.toLowerCase().contains(_searchQuery)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
      child: Column(
        children: [
          // Header with Logo
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logos/Avatar_logo.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.purple[700]!, Colors.purple[900]!],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Spot\nCarz',
                            style: GoogleFonts.righteous(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Title Section with Vehicle count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Stack(
                  children: [
                    // Ghosted "Mon garage" text in background
                    Positioned(
                      left: -110,
                      right: 0,
                      bottom: 0,
                      child: Text(
                        'Mon garage',
                        style: GoogleFonts.righteous(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Main title with icon and vehicle count on same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/menu_icons/garage.png',
                              width: 28,
                              height: 28,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mon garage',
                              style: GoogleFonts.righteous(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Vehicle count - number above text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_carSpots.length}',
                              style: GoogleFonts.righteous(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                
                              ),
                            ),
                            Text(
                              'Véhicules',
                              style: GoogleFonts.righteous(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300]!.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.righteous(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un modèle',
                      hintStyle: GoogleFonts.righteous(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content: Empty state, Brand Grid, Car List, or Car Details
          Expanded(
            child: _brands.isEmpty
                ? _buildGarageEmptyState()
                : _selectedCar != null
                    ? _buildCarDetailsView(_selectedCar!)
                    : _selectedBrand != null
                        ? _buildBrandCarsView(_selectedBrand!)
                        : filteredBrands.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucun résultat trouvé',
                                  style: GoogleFonts.righteous(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              )
                            : _buildGarageGrid(filteredBrands),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large car outline icon
          Icon(
            Icons.directions_car_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          // Message
          Text(
            'Ton garage est vide, ajoute ton premier',
            style: GoogleFonts.righteous(
              fontSize: 16,
              color: Colors.grey[300],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SPOT',
                style: GoogleFonts.righteous(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                ' dès maintenant !',
                style: GoogleFonts.righteous(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Add button
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 2),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageGrid(List<String> brands) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return _buildGarageVehicleCard(brand);
      },
    );
  }

  Widget _buildGarageVehicleCard(String brand) {
    return FutureBuilder<CarSpot?>(
      future: _getFirstCarSpotForBrand(brand),
      builder: (context, snapshot) {
        final firstSpot = snapshot.data;
        final hasImage = firstSpot?.imageUrls.isNotEmpty ?? false;
        final imageUrl = hasImage ? firstSpot!.imageUrls.first : null;

        return InkWell(
          onTap: () {
            // Expand to show cars for this brand
            setState(() {
              _selectedBrand = brand;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand name header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      brand.replaceAll('_', ' ').split(' ').map((word) => 
                      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
                      ).join(' '),
                      style: GoogleFonts.righteous(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Image or placeholder
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      gradient: hasImage
                          ? null
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.purple[800]!.withValues(alpha: 0.3),
                                Colors.purple[900]!.withValues(alpha: 0.5),
                              ],
                            ),
                    ),
                    child: hasImage && imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderIcon();
                              },
                            ),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.directions_car,
        size: 40,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildBrandCarsView(String brand) {
    // Normalize brand name for matching (handle case differences)
    final normalizedBrand = brand.toUpperCase().replaceAll(' ', '_');
    
    // Find cars matching this brand (case-insensitive)
    final brandCars = _carSpots.where((spot) {
      final spotBrand = spot.brand.toUpperCase().replaceAll(' ', '_');
      return spotBrand == normalizedBrand;
    }).toList();
    
    debugPrint('Dashboard: Building cars view for brand: $brand');
    debugPrint('Dashboard: Normalized brand: $normalizedBrand');
    debugPrint('Dashboard: Found ${brandCars.length} cars for this brand');
    if (brandCars.isNotEmpty) {
      debugPrint('Dashboard: Car spots: ${brandCars.map((c) => '${c.brand} - ${c.model}').join(', ')}');
    }
    debugPrint('Dashboard: All car spots brands: ${_carSpots.map((c) => c.brand).toSet().join(', ')}');
    
    // Try to get models - handle different brand name formats
    // car_brands.dart uses uppercase brand names like "FERRARI", "ASTON_MARTIN"
    String brandKey = brand.toUpperCase().replaceAll(' ', '_');
    List<String> allModels = CarBrandsData.getModelsForBrand(brandKey);
    
    // If still empty, try other variations
    if (allModels.isEmpty) {
      allModels = CarBrandsData.getModelsForBrand(brand.toUpperCase());
    }
    if (allModels.isEmpty) {
      allModels = CarBrandsData.getModelsForBrand(brand);
    }
    
    debugPrint('Dashboard: Found ${allModels.length} models for brand: $brand (key: $brandKey)');
    if (allModels.isEmpty) {
      debugPrint('Dashboard: WARNING - No models found for brand: $brand');
      debugPrint('Dashboard: Available brands in car_brands.dart: ${CarBrandsData.getAllBrandNames().take(10).join(', ')}...');
    }
    
    return Column(
      children: [
        // Brand Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBrand = null;
                  });
                },
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
                  brand.replaceAll('_', ' '),
                  style: GoogleFonts.righteous(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Owned count
              Text(
                '${brandCars.length} possédée${brandCars.length > 1 ? 's' : ''}',
                style: GoogleFonts.righteous(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Cars Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: allModels.isEmpty && brandCars.isNotEmpty
                ? GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: brandCars.length,
                    itemBuilder: (context, index) {
                      final carSpot = brandCars[index];
                      return _buildBrandCarCard(carSpot, true);
                    },
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: allModels.length,
                    itemBuilder: (context, index) {
                      final model = allModels[index];
                      // Case-insensitive model matching
                      final isOwned = brandCars.any((spot) => 
                        spot.model.toLowerCase().trim() == model.toLowerCase().trim()
                      );
                      final carSpot = isOwned
                          ? brandCars.firstWhere((spot) => 
                              spot.model.toLowerCase().trim() == model.toLowerCase().trim()
                            )
                          : CarSpot(
                              brand: brand,
                              model: model,
                              imageUrls: [],
                              spottedAt: DateTime.now(),
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                      return _buildBrandCarCard(carSpot, isOwned);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandCarCard(CarSpot carSpot, bool isOwned) {
    return InkWell(
      onTap: isOwned
          ? () {
              setState(() {
                _selectedCar = carSpot;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Car Image or Placeholder
              Expanded(
                flex: 5,
                child: isOwned && carSpot.imageUrls.isNotEmpty
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
                  carSpot.model,
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

  Future<CarSpot?> _getFirstCarSpotForBrand(String brand) async {
    try {
      final carSpots = await _databaseService.getCarSpots();
      final brandSpots = carSpots.where((spot) => spot.brand == brand).toList();
      return brandSpots.isNotEmpty ? brandSpots.first : null;
    } catch (e) {
      debugPrint('Dashboard: Error getting first car spot for brand: $e');
      return null;
    }
  }

  Widget _buildCarDetailsView(CarSpot carSpot) {
    return Column(
      children: [
        // Back button header with car model name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCar = null;
                  });
                },
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
              const Spacer(),
              // Car model name on the right
              Flexible(
                child: Text(
                  carSpot.model,
                  style: GoogleFonts.righteous(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Car Image with margins (matching the design)
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 0.0),
            child: carSpot.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      carSpot.imageUrls.first,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildCarImagePlaceholder();
                      },
                    ),
                  )
                : _buildCarImagePlaceholder(),
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            children: [
              // Créer un post button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostPage(initialCarSpot: carSpot),
                      ),
                    );
                  },
                  icon: Icon(Icons.thumb_up, color: Colors.white),
                  label: Text(
                    'Créer un post',
                    style: GoogleFonts.righteous(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Editer button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showReplaceModelModal(context, carSpot);
                  },
                  icon: Icon(Icons.edit, color: Colors.white),
                  label: Text(
                    'Editer',
                    style: GoogleFonts.righteous(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Supprimer button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteModelModal(context, carSpot);
                  },
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    'Supprimer',
                    style: GoogleFonts.righteous(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCarImagePlaceholder() {
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car,
          size: 100,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  void _showReplaceModelModal(BuildContext context, CarSpot carSpot) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple[900]!.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Remplacer le modèle',
                  style: GoogleFonts.righteous(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Gallerie button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      // TODO: Implement gallery picker
                    },
                    icon: Icon(Icons.image, color: Colors.white),
                    label: Text(
                      'Gallerie',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Annuler button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[900]!.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteModelModal(BuildContext context, CarSpot carSpot) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.purple[900]!.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Supprimer le modèle',
                  style: GoogleFonts.righteous(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Annuler button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Je confirme button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _databaseService.deleteCarSpot(carSpot.id!);
                        Navigator.pop(context);
                        setState(() {
                          _selectedCar = null;
                          _loadData();
                        });
                      } catch (e) {
                        debugPrint('Dashboard: Error deleting car spot: $e');
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[900]!.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Je confirme',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCollectionTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Get all brands from car_brands.dart
    final allBrands = CarBrandsData.getAllBrandNames();
    final totalModels = allBrands.fold<int>(0, (sum, brand) {
      final models = CarBrandsData.getModelsForBrand(brand);
      return sum + models.length;
    });

    final filteredBrands = _searchQuery.isEmpty
        ? allBrands
        : allBrands.where((brand) => brand.toLowerCase().contains(_searchQuery)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          // Header with Logo
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logos/Avatar_logo.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.purple[700]!, Colors.purple[900]!],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Spot\nCarz',
                            style: GoogleFonts.righteous(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Title Section with Models count
          Stack(
            children: [
              // Ghosted "Catalogue" text in background
              Positioned(
                left: -110,
                right: 0,
                bottom: 0,
                child: Text(
                  'Catalogue',
                  style: GoogleFonts.righteous(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Main title with icon and models count on same row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/menu_icons/catalog.png',
                        width: 28,
                        height: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Catalogue',
                        style: GoogleFonts.righteous(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Models count - number above text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalModels',
                        style: GoogleFonts.righteous(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Modèles',
                        style: GoogleFonts.righteous(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.righteous(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un modèle',
                hintStyle: GoogleFonts.righteous(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content: Brand Grid
          Expanded(
            child: filteredBrands.isEmpty
                ? Center(
                    child: Text(
                      'Aucun résultat trouvé',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : _buildCatalogGrid(filteredBrands),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogGrid(List<String> brands) {
    return GridView.builder(
      padding: const EdgeInsets.all(0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return _buildCatalogBrandCard(brand);
      },
    );
  }

  Widget _buildCatalogBrandCard(String brand) {
    final models = CarBrandsData.getModelsForBrand(brand);
    final modelCount = models.length;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getBrandCoverImage(brand),
      builder: (context, snapshot) {
        final coverImageUrl = snapshot.data?['imageUrl'] as String?;
        final hasCoverImage = coverImageUrl != null && coverImageUrl.isNotEmpty;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BrandDetailPage(brand: brand),
              ),
            ).then((_) {
              // Refresh the catalog when returning from brand detail
              setState(() {});
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple[900]!.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Stack(
              children: [
                // Cover image or checkered flag pattern background
                if (hasCoverImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coverImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildCatalogCardBackground(brand);
                      },
                    ),
                  )
                else
                  _buildCatalogCardBackground(brand),
                // Gradient overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Brand name
                      Text(
                        brand.replaceAll('_', ' '),
                        style: GoogleFonts.righteous(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Model count
                      Text(
                        '$modelCount',
                        style: GoogleFonts.righteous(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Modèles',
                        style: GoogleFonts.righteous(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogCardBackground(String brand) {
    return Stack(
      children: [
        Container(
          color: Colors.purple[900]!.withValues(alpha: 0.6),
        ),
        // Checkered flag pattern background
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(60, 60),
            painter: CheckeredFlagPainter(),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getBrandCoverImage(String brand) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedBrand = brand.toUpperCase().replaceAll(' ', '_');
      final coverModel = prefs.getString('brand_cover_$normalizedBrand');
      
      if (coverModel == null || coverModel.isEmpty) {
        return {};
      }

      // Find the car spot for this brand and model
      final normalizedBrandForMatch = brand.toUpperCase().replaceAll(' ', '_');
      final brandCars = _carSpots.where((spot) {
        final spotBrand = spot.brand.toUpperCase().replaceAll(' ', '_');
        return spotBrand == normalizedBrandForMatch;
      }).toList();

      final carSpot = brandCars.firstWhere(
        (spot) => spot.model.toLowerCase().trim() == coverModel.toLowerCase().trim(),
        orElse: () => CarSpot(
          brand: brand,
          model: coverModel,
          imageUrls: [],
          spottedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (carSpot.imageUrls.isNotEmpty) {
        return {'imageUrl': carSpot.imageUrls.first};
      }
    } catch (e) {
      debugPrint('Dashboard: Error getting brand cover image: $e');
    }
    return {};
  }

  Widget _buildSpotTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Spot Car Section
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Spot a Car',
                  style: GoogleFonts.righteous(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Take a photo or upload from gallery to add to your collection',
                  style: GoogleFonts.righteous(
                    fontSize: 16,
                    color: Colors.grey[300],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Quick Add Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'Quick Add',
                  style: GoogleFonts.righteous(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add car details manually',
                  style: GoogleFonts.righteous(
                    fontSize: 14,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showAddCarDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Add Manually'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _databaseService.getUserProfile(),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final authUser = _authService.currentUser;
        
        final userEmail = userProfile?['email'] ?? authUser?.email ?? 'No email';
        final userName = userProfile?['full_name'] ?? authUser?.userMetadata?['full_name'] ?? 'Car Spotter';
        final initials = userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.red[400],
                      child: Text(
                        initials.isNotEmpty ? initials : 'CS',
                        style: GoogleFonts.righteous(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: GoogleFonts.righteous(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: GoogleFonts.righteous(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Member since ${authUser?.createdAt != null ? DateTime.parse(authUser!.createdAt).year : DateTime.now().year}',
                      style: GoogleFonts.righteous(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // User Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Spots', _carSpots.length.toString(), Icons.camera_alt, Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Brands', _brands.length.toString(), Icons.category, Colors.green),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Profile Options
              Expanded(
                child: ListView(
                  children: [
                    _buildProfileOption(Icons.settings, 'Settings', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    }),
                    _buildProfileOption(Icons.verified_user, 'Verify Images', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VerificationExamplePage()),
                      );
                    }),
                    _buildProfileOption(Icons.notifications, 'Notifications', () {}),
                    _buildProfileOption(Icons.help, 'Help & Support', () {}),
                    _buildProfileOption(Icons.info, 'About', () {}),
                    _buildProfileOption(Icons.logout, 'Logout', () async {
                      try {
                        await _authService.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logout failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.righteous(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.righteous(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    // Load feed only once when tab is first opened or when tab changes
    if (!_feedLoaded && !_isLoadingFeed && !_feedLoadScheduled && _selectedIndex == 3) {
      _feedLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLoadingFeed) {
          _loadFeed(_selectedFeedTab);
        }
        _feedLoadScheduled = false;
      });
    }
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Logo and Title Row
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logos/App_logo.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [Colors.purple[700]!, Colors.purple[900]!],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Spot\nCarz',
                                    style: GoogleFonts.righteous(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title with icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ghosted text
                          Text(
                            'Car Meet',
                            style: GoogleFonts.righteous(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          // Main text
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Car Meet',
                                style: GoogleFonts.righteous(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Create Post Button
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatePostPage(),
                            ),
                          );
                          // Refresh feed if post was created
                          if (result == true) {
                            debugPrint('Dashboard: Post created, refreshing feed...');
                            setState(() {
                              _feedLoaded = false;
                              _feedLoadScheduled = false;
                            });
                            // Force reload the feed
                            await _loadFeed(_selectedFeedTab);
                            debugPrint('Dashboard: Feed refreshed, posts count: ${_feedPosts.length}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Créer un post',
                          style: GoogleFonts.righteous(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300]!.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      style: GoogleFonts.righteous(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Faites une recherche sur le meeting',
                        hintStyle: GoogleFonts.righteous(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedFeedTab != 0) {
                              setState(() {
                                _selectedFeedTab = 0;
                                _feedLoaded = false; // Mark as not loaded to reload
                                _feedLoadScheduled = false;
                              });
                              _loadFeed(0);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedFeedTab == 0 
                                      ? Colors.purple[400]! 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Découvertes',
                              style: GoogleFonts.righteous(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedFeedTab == 0 
                                    ? Colors.purple[400]! 
                                    : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedFeedTab != 1) {
                              setState(() {
                                _selectedFeedTab = 1;
                                _feedLoaded = false; // Mark as not loaded to reload
                                _feedLoadScheduled = false;
                              });
                              _loadFeed(1);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedFeedTab == 1 
                                      ? Colors.purple[400]! 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Suivis',
                              style: GoogleFonts.righteous(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedFeedTab == 1 
                                    ? Colors.purple[400]! 
                                    : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Feed Content
            Expanded(
              child: _isLoadingFeed
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _feedPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Aucun post pour le moment',
                                style: GoogleFonts.righteous(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() {
                                    _feedLoaded = false;
                                    _feedLoadScheduled = false;
                                  });
                                  await _loadFeed(_selectedFeedTab);
                                },
                                icon: Icon(Icons.refresh, color: Colors.white),
                                label: Text(
                                  'Actualiser',
                                  style: GoogleFonts.righteous(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _feedLoaded = false;
                            _feedLoadScheduled = false;
                            await _loadFeed(_selectedFeedTab);
                          },
                          color: Colors.purple[700],
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            itemCount: _feedPosts.length,
                            itemBuilder: (context, index) {
                              final post = _feedPosts[index];
                              return _buildFeedPostCard(post);
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadFeed(int tabIndex) async {
    if (_isLoadingFeed) return; // Prevent concurrent loads
    
    setState(() {
      _isLoadingFeed = true;
    });

    try {
      List<Map<String, dynamic>> posts;
      if (tabIndex == 0) {
        // Découvertes (Discovery)
        posts = await _databaseService.getDiscoveryFeed();
      } else {
        // Suivis (Following)
        posts = await _databaseService.getFollowingFeed();
      }

      // Cache like statuses from posts
      _postLikedCache.clear();
      for (var post in posts) {
        final postId = post['id'] as String?;
        if (postId != null) {
          _postLikedCache[postId] = post['is_liked'] as bool? ?? false;
        }
      }

      if (mounted) {
        debugPrint('Dashboard: Loaded ${posts.length} posts for tab $_selectedFeedTab');
        if (posts.isNotEmpty) {
          debugPrint('Dashboard: First post in feed - id: ${posts.first['id']}, username: ${posts.first['username']}, image_url: ${posts.first['image_url']}');
        }
        setState(() {
          _feedPosts = posts;
          _isLoadingFeed = false;
          _feedLoaded = true; // Mark as loaded even if empty to prevent infinite retries
        });
      }
    } catch (e) {
      debugPrint('Dashboard: Error loading feed: $e');
      if (mounted) {
        setState(() {
          _feedPosts = [];
          _isLoadingFeed = false;
          _feedLoaded = true; // Mark as loaded even on error to prevent infinite retries
        });
      }
    }
  }

  Widget _buildFeedPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple[700],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logos/Avatar_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Username
                Expanded(
                  child: Text(
                    post['username'] as String? ?? 'User',
                    style: GoogleFonts.righteous(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Car Image
          if (post['image_url'] != null && (post['image_url'] as String).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post['image_url'] as String,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[800],
                    child: Center(
                      child: Icon(
                        Icons.directions_car,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Likes and Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    final postId = post['id'] as String? ?? '';
                    final isLiked = _postLikedCache[postId] ?? (post['is_liked'] as bool? ?? false);
                    final likesCount = post['likes_count'] as int? ?? 0;
                    
                    // Only show likes section if there are likes or user can like
                    if (likesCount == 0 && !isLiked) {
                      return const SizedBox.shrink();
                    }
                    
                    return GestureDetector(
                      onTap: () async {
                        try {
                          final newLikedState = !isLiked;
                          
                          // Optimistically update UI
                          setState(() {
                            _postLikedCache[postId] = newLikedState;
                            post['is_liked'] = newLikedState;
                            post['likes_count'] = newLikedState 
                                ? (likesCount + 1) 
                                : (likesCount > 0 ? likesCount - 1 : 0);
                          });
                          
                          // Update database in background
                          if (newLikedState) {
                            await _databaseService.likePost(postId);
                          } else {
                            await _databaseService.unlikePost(postId);
                          }
                        } catch (e) {
                          debugPrint('Error toggling like: $e');
                          // Revert on error
                          setState(() {
                            _postLikedCache[postId] = isLiked;
                            post['is_liked'] = isLiked;
                            post['likes_count'] = likesCount;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: isLiked ? Colors.red : Colors.purple[400],
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatLikes(post['likes_count'] as int? ?? 0),
                            style: GoogleFonts.righteous(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  _getTimeAgo(DateTime.parse(post['created_at'] as String)),
                  style: GoogleFonts.righteous(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          if (post['description'] != null && (post['description'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['description'] as String,
                    style: GoogleFonts.righteous(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((post['description'] as String).length > 100)
                    Text(
                      'voir plus',
                      style: GoogleFonts.righteous(
                        fontSize: 14,
                        color: Colors.purple[400],
                      ),
                    ),
                ],
              ),
            ),
          
          // Hashtags
          if (post['hashtags'] != null && (post['hashtags'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Wrap(
                spacing: 8,
                children: (post['hashtags'] as List)
                    .map((hashtag) => Text(
                          hashtag.toString(),
                          style: GoogleFonts.righteous(
                            fontSize: 14,
                            color: Colors.purple[300],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatLikes(int likes) {
    if (likes >= 1000) {
      final k = (likes / 1000).toStringAsFixed(1);
      return '$k K';
    }
    return likes.toString();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  Widget _buildCarSpotCard(CarSpot spot) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailPage(carSpot: spot),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: spot.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(spot.imageUrls.first, fit: BoxFit.cover),
                    )
                  : Icon(Icons.directions_car, color: Colors.grey[400]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.brand.replaceAll('_', ' '),
                    style: GoogleFonts.righteous(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.model,
                    style: GoogleFonts.righteous(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.spottedAt.toString().split(' ')[0],
                    style: GoogleFonts.righteous(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCard(String brand) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrandDetailPage(brand: brand),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 40,
              color: Colors.red[400],
            ),
            const SizedBox(height: 12),
            Text(
              brand.replaceAll('_', ' '),
              style: GoogleFonts.righteous(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FutureBuilder<int>(
              future: _getBrandCarCount(brand),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text(
                  '$count cars',
                  style: GoogleFonts.righteous(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400]),
        title: Text(
          title,
          style: GoogleFonts.righteous(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _showAddCarDialog(image: File(image.path));
    }
  }

  Future<int> _getBrandCarCount(String brand) async {
    try {
      final carSpots = await _databaseService.getCarSpots();
      return carSpots.where((spot) => spot.brand == brand).length;
    } catch (e) {
      debugPrint('Dashboard: Error getting brand car count: $e');
      return 0;
    }
  }

  void _showAddCarDialog({File? image}) {
    String? selectedBrand;
    String? selectedModel;
    final yearController = TextEditingController();
    List<String> availableModels = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Add Car Spot',
            style: GoogleFonts.righteous(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image != null)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 16),
              
              // Brand Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedBrand,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  labelStyle: GoogleFonts.righteous(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.grey[800],
                style: GoogleFonts.righteous(color: Colors.white),
                items: CarBrandsData.getAllBrandNames().map((String brand) {
                  return DropdownMenuItem<String>(
                    value: brand,
                    child: Text(brand.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedBrand = newValue;
                    selectedModel = null;
                    availableModels = CarBrandsData.getModelsForBrand(newValue ?? '');
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              // Model Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedModel,
                decoration: InputDecoration(
                  labelText: 'Model',
                  labelStyle: GoogleFonts.righteous(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.grey[800],
                style: GoogleFonts.righteous(color: Colors.white),
                items: availableModels.map((String model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(model),
                  );
                }).toList(),
                onChanged: selectedBrand != null ? (String? newValue) {
                  setState(() {
                    selectedModel = newValue;
                  });
                } : null,
              ),
              
              const SizedBox(height: 12),
              
              // Year TextField
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.righteous(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Year',
                  labelStyle: GoogleFonts.righteous(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.righteous(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedBrand != null && selectedModel != null && yearController.text.isNotEmpty) {
                try {
                  final newCarSpot = await _databaseService.createCarSpot(
                    brand: selectedBrand!,
                    model: selectedModel!,
                    year: yearController.text,
                    imageFile: image,
                  );
                  
                  if (mounted) {
                    setState(() {
                      _carSpots.insert(0, newCarSpot);
                      if (!_brands.contains(selectedBrand)) {
                        _brands.add(selectedBrand!);
                      }
                    });
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Car spot added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add car spot: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select brand, model, and enter year'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
            child: Text('Add', style: GoogleFonts.righteous(color: Colors.white)),
          ),
        ],
      ),
      ),
    );
  }
}

// CarSpot class is now defined in database_service.dart

// Custom painter for checkered flag pattern
class CheckeredFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple[700]!.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final squareSize = 8.0;
    final rows = (size.height / squareSize).ceil();
    final cols = (size.width / squareSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if ((row + col) % 2 == 0) {
          final rect = Rect.fromLTWH(
            col * squareSize,
            row * squareSize,
            squareSize,
            squareSize,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
