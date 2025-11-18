import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../data/car_brands.dart';

class CarSpot {
  final String? id;
  final String? spotterId;
  final String? locationId;
  final String brand;
  final String model;
  final int? year;
  final String? color;
  final String? licensePlate;
  final String? description;
  final List<String> imageUrls;
  final String visibility;
  final bool isVerified;
  final String? verifiedBy;
  final int likesCount;
  final int commentsCount;
  final int rarityScore;
  final String? weatherConditions;
  final DateTime spottedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarSpot({
    this.id,
    this.spotterId,
    this.locationId,
    required this.brand,
    required this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.description,
    this.imageUrls = const [],
    this.visibility = 'public',
    this.isVerified = false,
    this.verifiedBy,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.rarityScore = 1,
    this.weatherConditions,
    required this.spottedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'spotter_id': spotterId,
      'location_id': locationId,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'description': description,
      'image_urls': imageUrls,
      'visibility': visibility,
      'is_verified': isVerified,
      'verified_by': verifiedBy,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'rarity_score': rarityScore,
      'weather_conditions': weatherConditions,
      'spotted_at': spottedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not null (for updates)
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  factory CarSpot.fromJson(Map<String, dynamic> json) {
    return CarSpot(
      id: json['id'],
      spotterId: json['spotter_id'],
      locationId: json['location_id'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      licensePlate: json['license_plate'],
      description: json['description'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      visibility: json['visibility'] ?? 'public',
      isVerified: json['is_verified'] ?? false,
      verifiedBy: json['verified_by'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      rarityScore: json['rarity_score'] ?? 1,
      weatherConditions: json['weather_conditions'],
      spottedAt: DateTime.parse(json['spotted_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class DatabaseService {
  final SupabaseService _supabase = SupabaseService.instance;
  
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'car-images/${_supabase.currentUser!.id}/$fileName';
      
      await _supabase.client.storage
          .from('car-images')
          .uploadBinary(filePath, await imageFile.readAsBytes());
      
      final publicUrl = _supabase.client.storage
          .from('car-images')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }
  
  /// Cache for valid brand names from car_brands.dart (normalized to database format)
  List<String>? _cachedValidBrands;
  
  /// Gets valid brand names from car_brands.dart and normalizes them to database enum format
  /// Database enum uses lowercase format (e.g., "porsche", "ferrari")
  List<String> _getValidBrandsFromCarBrandsData() {
    // Get all brand names from car_brands.dart
    final brands = CarBrandsData.brands.map((brand) => brand.name).toList();
    
    // Normalize to database enum format (lowercase)
    final normalizedBrands = brands.map((brand) => brand.toLowerCase()).toList();
    
    debugPrint('DatabaseService: Found ${normalizedBrands.length} valid brands from car_brands.dart: ${normalizedBrands.join(", ")}');
    
    return normalizedBrands;
  }
  
  /// Gets all possible brand name variations to try
  /// Maps from car_brands.dart format (uppercase) to database enum format (lowercase)
  List<String> _getBrandVariations(String brand) {
    final trimmed = brand.trim();
    final variations = <String>{};
    
    // Get valid brands from car_brands.dart if not cached
    _cachedValidBrands ??= _getValidBrandsFromCarBrandsData();
    
    // Database enum uses lowercase format (e.g., "porsche", "ferrari")
    // So convert the brand from car_brands.dart format (uppercase) to lowercase
    final lowercaseBrand = trimmed.toLowerCase();
    
    // Check if this brand exists in car_brands.dart (case-insensitive)
    final upperBrand = trimmed.toUpperCase();
    bool foundInCarBrands = false;
    for (String validBrand in _cachedValidBrands!) {
      if (validBrand.toUpperCase() == upperBrand) {
        variations.add(validBrand); // Use the exact lowercase format
        foundInCarBrands = true;
        break;
      }
    }
    
    // If brand not found in car_brands.dart, log a warning
    if (!foundInCarBrands) {
      debugPrint('DatabaseService: Brand "$brand" not found in car_brands.dart. Valid brands: ${_cachedValidBrands!.join(", ")}');
    }
    
    // Primary: lowercase (database enum format)
    variations.add(lowercaseBrand);
    
    // Also try variations in case the enum uses different formats
    final words = trimmed.toLowerCase().split(RegExp(r'[\s_-]+'));
    
    // Lowercase with underscores
    variations.add(lowercaseBrand.replaceAll(RegExp(r'[\s-]+'), '_'));
    
    // Title Case (e.g., "Audi", "Mercedes Benz")
    final titleCase = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
    variations.add(titleCase);
    
    // Title Case with underscores
    variations.add(words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join('_'));
    
    // Uppercase
    variations.add(trimmed.toUpperCase());
    
    // Uppercase with underscores
    variations.add(trimmed.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_'));
    
    // Original
    variations.add(trimmed);
    
    return variations.toList();
  }

  /// Checks if an error is an enum validation error (code 22P02)
  bool _isEnumError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('22p02') || 
           errorString.contains('invalid input value for enum') ||
           errorString.contains('car_brand');
  }

  /// Adds a brand to the database enum if it doesn't exist
  Future<void> _addBrandToEnum(String brandName) async {
    try {
      // Normalize brand name to lowercase (database enum format)
      final normalizedBrand = brandName.toLowerCase();
      
      debugPrint('DatabaseService: Attempting to add brand "$normalizedBrand" to enum');
      
      // Call the database function to add the brand to the enum
      await _supabase.client.rpc('add_brand_to_enum', params: {
        'brand_name': normalizedBrand,
      });
      
      debugPrint('DatabaseService: Successfully added brand "$normalizedBrand" to enum');
    } catch (e) {
      final errorString = e.toString();
      debugPrint('DatabaseService: Error adding brand to enum: $e');
      
      // Check if the function doesn't exist
      if (errorString.contains('PGRST202') || 
          errorString.contains('Could not find the function') ||
          errorString.contains('schema cache')) {
        debugPrint('DatabaseService: ERROR - The add_brand_to_enum function is not found in the database.');
        debugPrint('DatabaseService: Please run the migration: supabase_migrations/add_brand_to_enum.sql');
        debugPrint('DatabaseService: Go to Supabase Dashboard → SQL Editor → Run the migration file');
        debugPrint('DatabaseService: Then wait 1-2 minutes for PostgREST to refresh its schema cache.');
      }
      // Don't throw - we'll try the insert anyway
    }
  }

  Future<CarSpot> createCarSpot({
    required String brand,
    required String model,
    required String year,
    File? imageFile,
  }) async {
    try {
      // Get all possible brand variations to try
      final brandVariations = _getBrandVariations(brand);
      
      // Try each variation until one works
      Exception? lastError;
      bool triedAddingToEnum = false;
      
      for (String brandVariant in brandVariations) {
        try {
          List<String> imageUrls = [];
          if (imageFile != null) {
            final imageUrl = await uploadImage(imageFile);
            if (imageUrl != null) {
              imageUrls.add(imageUrl);
            }
          }
          
          final carSpot = CarSpot(
            id: null, // Let database generate UUID
            spotterId: _supabase.currentUser!.id,
            brand: brandVariant,
            model: model,
            year: int.tryParse(year),
            imageUrls: imageUrls,
            spottedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final response = await _supabase.client
              .from('car_spots')
              .insert(carSpot.toJson())
              .select()
              .single();
          
          final createdSpot = CarSpot.fromJson(response);
          
          // Create related records
          await _createRelatedRecords(createdSpot);
          
          debugPrint('DatabaseService: Successfully used brand: $brandVariant');
          return createdSpot;
        } catch (e) {
          debugPrint('DatabaseService: Brand "$brandVariant" failed: $e');
          
          // If this is an enum error and we haven't tried adding to enum yet, try adding it
          if (_isEnumError(e) && !triedAddingToEnum) {
            triedAddingToEnum = true;
            debugPrint('DatabaseService: Enum error detected, attempting to add brand to enum');
            
            // Check if brand exists in car_brands.dart before adding
            final brandFromCarBrands = _cachedValidBrands?.any((b) => b.toUpperCase() == brand.toUpperCase()) ?? false;
            if (brandFromCarBrands) {
              // Try adding the normalized brand (lowercase) to the enum
              await _addBrandToEnum(brandVariant.toLowerCase());
              
              // Retry the insert with the same brand variant
              try {
                List<String> imageUrls = [];
                if (imageFile != null) {
                  final imageUrl = await uploadImage(imageFile);
                  if (imageUrl != null) {
                    imageUrls.add(imageUrl);
                  }
                }
                
                final carSpot = CarSpot(
                  id: null,
                  spotterId: _supabase.currentUser!.id,
                  brand: brandVariant.toLowerCase(), // Use lowercase after adding to enum
                  model: model,
                  year: int.tryParse(year),
                  imageUrls: imageUrls,
                  spottedAt: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                final response = await _supabase.client
                    .from('car_spots')
                    .insert(carSpot.toJson())
                    .select()
                    .single();
                
                final createdSpot = CarSpot.fromJson(response);
                await _createRelatedRecords(createdSpot);
                
                debugPrint('DatabaseService: Successfully created car spot after adding brand to enum');
                return createdSpot;
              } catch (retryError) {
                debugPrint('DatabaseService: Retry after adding to enum failed: $retryError');
                lastError = retryError is Exception ? retryError : Exception(retryError.toString());
              }
            }
          }
          
          lastError = e is Exception ? e : Exception(e.toString());
          continue;
        }
      }
      
      // If all variations failed, throw the last error with helpful message
      final brandFromCarBrands = _cachedValidBrands?.any((b) => b.toUpperCase() == brand.toUpperCase()) ?? false;
      
      String errorMsg = 'Failed to create car spot: Brand "$brand" ';
      if (brandFromCarBrands) {
        errorMsg += 'exists in car_brands.dart but failed database validation. ';
        if (triedAddingToEnum) {
          errorMsg += 'Attempted to add to enum but insert still failed. ';
        }
        errorMsg += 'Tried variations: ${brandVariations.join(", ")}.';
      } else {
        errorMsg += 'is not found in car_brands.dart. ';
        errorMsg += 'Valid brands: ${_cachedValidBrands?.join(", ") ?? "unknown"}.';
      }
      
      if (lastError != null) {
        errorMsg += ' Last error: ${lastError.toString()}.';
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to create car spot: ${e.toString()}');
    }
  }
  
  Future<List<CarSpot>> getCarSpots() async {
    try {
      debugPrint('DatabaseService: Fetching car spots for user ${_supabase.currentUser!.id}');
      final response = await _supabase.client
          .from('car_spots')
          .select()
          .eq('spotter_id', _supabase.currentUser!.id)
          .order('created_at', ascending: false);
      
      debugPrint('DatabaseService: Received ${(response as List).length} car spots');
      return (response as List)
          .map((json) => CarSpot.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('DatabaseService: Error fetching car spots: $e');
      throw Exception('Failed to fetch car spots: ${e.toString()}');
    }
  }
  
  Future<CarSpot> updateCarSpot({
    required String id,
    String? brand,
    String? model,
    String? year,
    File? imageFile,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (brand != null) updates['brand'] = brand;
      if (model != null) updates['model'] = model;
      if (year != null) updates['year'] = year;
      
      if (imageFile != null) {
        final imageUrl = await uploadImage(imageFile);
        if (imageUrl != null) {
          updates['image_urls'] = [imageUrl];
        }
      }
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase.client
          .from('car_spots')
          .update(updates)
          .eq('id', id)
          .eq('spotter_id', _supabase.currentUser!.id)
          .select()
          .single();
      
      return CarSpot.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update car spot: ${e.toString()}');
    }
  }
  
  Future<void> deleteCarSpot(String id) async {
    try {
      await _supabase.client
          .from('car_spots')
          .delete()
          .eq('id', id)
          .eq('spotter_id', _supabase.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete car spot: ${e.toString()}');
    }
  }
  
  Future<List<String>> getBrands() async {
    try {
      final response = await _supabase.client
          .from('car_spots')
          .select('brand')
          .eq('spotter_id', _supabase.currentUser!.id);
      
      final brands = (response as List)
          .map((json) => json['brand'] as String)
          .toSet()
          .toList();
      
      return brands;
    } catch (e) {
      throw Exception('Failed to fetch brands: ${e.toString()}');
    }
  }
  
  Future<int> getCarSpotCount() async {
    try {
      final response = await _supabase.client
          .from('car_spots')
          .select('id')
          .eq('spotter_id', _supabase.currentUser!.id);
      
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get car spot count: ${e.toString()}');
    }
  }
  
  Future<List<String>> getValidBrands() async {
    try {
      // Try to get the enum values by querying the information_schema
      final response = await _supabase.client
          .rpc('get_enum_values', params: {'enum_name': 'car_brand'});
      
      if (response != null && response is List) {
        return response.cast<String>();
      }
      
      // Fallback: try some common brand names
      return ['BMW', 'AUDI', 'MERCEDES', 'FERRARI', 'PORSCHE'];
    } catch (e) {
      debugPrint('DatabaseService: Error getting valid brands: $e');
      // Return a minimal set of likely valid brands
      return ['BMW', 'AUDI', 'MERCEDES'];
    }
  }

  Future<String?> createLocation({
    required String name,
    required String address,
    required String city,
    required String country,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final locationData = {
        'name': name,
        'address': address,
        'city': city,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'is_popular_spot': false,
        'total_spots': 1,
      };
      
      final response = await _supabase.client
          .from('locations')
          .insert(locationData)
          .select('id')
          .single();
      
      return response['id'];
    } catch (e) {
      debugPrint('DatabaseService: Error creating location: $e');
      return null;
    }
  }

  Future<String?> createUserCollection({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final collectionData = {
        'user_id': _supabase.currentUser!.id,
        'name': name,
        'description': description,
        'is_public': isPublic,
        'spots_count': 0,
      };
      
      final response = await _supabase.client
          .from('user_collections')
          .insert(collectionData)
          .select('id')
          .single();
      
      return response['id'];
    } catch (e) {
      debugPrint('DatabaseService: Error creating user collection: $e');
      return null;
    }
  }

  Future<void> addSpotToCollection({
    required String collectionId,
    required String spotId,
  }) async {
    try {
      final collectionSpotData = {
        'collection_id': collectionId,
        'spot_id': spotId,
      };
      
      await _supabase.client
          .from('collection_spots')
          .insert(collectionSpotData);
      
      // Update collection spots count
      final spotsCount = await _getCollectionSpotsCount(collectionId);
      await _supabase.client
          .from('user_collections')
          .update({'spots_count': spotsCount})
          .eq('id', collectionId);
      
      debugPrint('DatabaseService: Updated collection $collectionId with $spotsCount spots');
    } catch (e) {
      debugPrint('DatabaseService: Error adding spot to collection: $e');
    }
  }

  Future<int> _getCollectionSpotsCount(String collectionId) async {
    try {
      final response = await _supabase.client
          .from('collection_spots')
          .select('id')
          .eq('collection_id', collectionId);
      
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _refreshCollectionCount(String collectionId) async {
    try {
      final spotsCount = await _getCollectionSpotsCount(collectionId);
      await _supabase.client
          .from('user_collections')
          .update({'spots_count': spotsCount})
          .eq('id', collectionId);
      
      debugPrint('DatabaseService: Refreshed collection $collectionId count to $spotsCount');
    } catch (e) {
      debugPrint('DatabaseService: Error refreshing collection count: $e');
    }
  }

  Future<void> createUserAchievement({
    required String achievementId,
    Map<String, dynamic>? progress,
  }) async {
    try {
      final achievementData = {
        'user_id': _supabase.currentUser!.id,
        'achievement_id': achievementId,
        'progress': progress ?? {},
      };
      
      await _supabase.client
          .from('user_achievements')
          .insert(achievementData);
      
      debugPrint('DatabaseService: Created achievement $achievementId for user');
    } catch (e) {
      debugPrint('DatabaseService: Error creating user achievement: $e');
    }
  }

  Future<void> checkAndCreateAchievements(int totalSpots) async {
    try {
      // Check for "First Spot" achievement
      if (totalSpots == 1) {
        await createUserAchievement(achievementId: 'first_spot');
      }
      
      // Check for "10 Spots" achievement
      if (totalSpots == 10) {
        await createUserAchievement(achievementId: 'ten_spots');
      }
      
      // Check for "50 Spots" achievement
      if (totalSpots == 50) {
        await createUserAchievement(achievementId: 'fifty_spots');
      }
      
      // Check for "100 Spots" achievement
      if (totalSpots == 100) {
        await createUserAchievement(achievementId: 'hundred_spots');
      }
      
    } catch (e) {
      debugPrint('DatabaseService: Error checking achievements: $e');
    }
  }

  Future<void> _createRelatedRecords(CarSpot carSpot) async {
    try {
      // 1. Create a default location (you can enhance this with actual GPS data later)
      final locationId = await createLocation(
        name: 'Unknown Location',
        address: 'Address not specified',
        city: 'Unknown City',
        country: 'Unknown Country',
        latitude: 0.0,
        longitude: 0.0,
        description: 'Location created automatically for car spot',
      );
      
      // Update the car spot with the location ID
      if (locationId != null && carSpot.id != null) {
        await _supabase.client
            .from('car_spots')
            .update({'location_id': locationId})
            .eq('id', carSpot.id!);
      }
      
      // 2. Create a default collection for this brand
      final collectionId = await createUserCollection(
        name: '${carSpot.brand.replaceAll('_', ' ')} Collection',
        description: 'My collection of ${carSpot.brand.replaceAll('_', ' ')} cars',
        isPublic: true,
      );
      
      // 3. Add the spot to the collection
      if (collectionId != null) {
        await addSpotToCollection(
          collectionId: collectionId,
          spotId: carSpot.id!,
        );
      }
      
      // 4. Check and create achievements
      final totalSpots = await getCarSpotCount();
      await checkAndCreateAchievements(totalSpots);
      
      // 5. Refresh collection count
      if (collectionId != null) {
        await _refreshCollectionCount(collectionId);
      }
      
      debugPrint('DatabaseService: Created related records for car spot ${carSpot.id}');
    } catch (e) {
      debugPrint('DatabaseService: Error creating related records: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _supabase.client
          .from('user_profiles')
          .select()
          .eq('id', _supabase.currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('DatabaseService: Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> createUserProfile({
    required String email,
    required String fullName,
  }) async {
    try {
      debugPrint('DatabaseService: Creating user profile for $email');
      
      final userProfile = {
        'id': _supabase.currentUser!.id,
        'email': email,
        'username': email.split('@')[0], // Use email prefix as username
        'full_name': fullName,
        'bio': 'Car enthusiast and spotter',
        'role': 'spotter',
        'total_spots': 0,
        'reputation_score': 0,
        'is_verified': false,
        'privacy_settings': {
          'spots_visibility': 'public',
          'profile_visibility': 'public'
        },
      };
      
      await _supabase.client
          .from('user_profiles')
          .insert(userProfile);
      
      debugPrint('DatabaseService: User profile created successfully');
    } catch (e) {
      debugPrint('DatabaseService: Error creating user profile: $e');
      // Don't throw error - profile might already exist
    }
  }

  Future<void> createDefaultData() async {
    try {
      debugPrint('DatabaseService: Creating default data for new user');
      
      // Check if user already has data
      final existingSpots = await getCarSpots();
      if (existingSpots.isNotEmpty) {
        debugPrint('DatabaseService: User already has data, skipping default creation');
        return;
      }
      
      debugPrint('DatabaseService: Skipping default data creation due to enum validation issues');
      // Skip creating default data for now until we know the correct enum values
      
    } catch (e) {
      debugPrint('DatabaseService: Error creating default data: $e');
      // Don't throw the error, just log it so the app doesn't crash
    }
  }

  Future<void> deleteCurrentUserData() async {
    try {
      final String userId = _supabase.currentUser!.id;

      // Delete user achievements
      try {
        await _supabase.client
            .from('user_achievements')
            .delete()
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting user_achievements: $e');
      }

      // Get user collection ids
      List<dynamic> collections = [];
      try {
        collections = await _supabase.client
            .from('user_collections')
            .select('id')
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error fetching user_collections: $e');
      }

      // Delete collection_spots for those collections
      try {
        final List<String> collectionIds = collections
            .map((c) => c['id'] as String)
            .toList();
        for (final cid in collectionIds) {
          await _supabase.client
              .from('collection_spots')
              .delete()
              .eq('collection_id', cid);
        }
      } catch (e) {
        debugPrint('DatabaseService: Error deleting collection_spots: $e');
      }

      // Delete user collections
      try {
        await _supabase.client
            .from('user_collections')
            .delete()
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting user_collections: $e');
      }

      // Delete car spots
      try {
        await _supabase.client
            .from('car_spots')
            .delete()
            .eq('spotter_id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting car_spots: $e');
      }

      // Delete user profile
      try {
        await _supabase.client
            .from('user_profiles')
            .delete()
            .eq('id', userId);
      } catch (e) {
        debugPrint('DatabaseService: Error deleting user_profiles: $e');
      }

      // Delete storage objects under car-images bucket at path {userId}
      try {
        final storage = _supabase.client.storage.from('car-images');
        final listResult = await storage.list(path: userId);
        if (listResult.isNotEmpty) {
          final paths = listResult.map((f) => '$userId/${f.name}').toList();
          await storage.remove(paths);
        }
      } catch (e) {
        debugPrint('DatabaseService: Error deleting storage files: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete user data: ${e.toString()}');
    }
  }

  // ============================================
  // POST METHODS
  // ============================================

  Future<Map<String, dynamic>> createPost({
    String? carSpotId,
    File? imageFile,
    String? description,
    List<String>? hashtags,
  }) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      } else if (carSpotId != null) {
        // Get image from car spot if no file provided
        final carSpot = await _supabase.client
            .from('car_spots')
            .select('image_urls')
            .eq('id', carSpotId)
            .eq('spotter_id', _supabase.currentUser!.id)
            .single();
        
        final imageUrls = carSpot['image_urls'] as List<dynamic>?;
        if (imageUrls != null && imageUrls.isNotEmpty) {
          imageUrl = imageUrls.first as String;
        }
      }

      // Get user's display name (full_name) from profile
      String? username;
      try {
        final userProfile = await _supabase.client
            .from('user_profiles')
            .select('full_name, username')
            .eq('id', _supabase.currentUser!.id)
            .maybeSingle();
        
        if (userProfile != null) {
          final fullName = userProfile['full_name'] as String?;
          final usernameFallback = userProfile['username'] as String?;
          // Use full_name (display name) if available, fallback to username
          username = fullName?.isNotEmpty == true 
              ? fullName 
              : (usernameFallback?.isNotEmpty == true ? usernameFallback : 'User');
        } else {
          username = 'User';
        }
      } catch (e) {
        debugPrint('DatabaseService: Error fetching user profile for post: $e');
        username = 'User'; // Fallback if profile fetch fails
      }

      // Extract hashtags from description if not provided
      List<String> finalHashtags = hashtags ?? [];
      if (description != null && finalHashtags.isEmpty) {
        final words = description.split(' ');
        finalHashtags = words.where((word) => word.startsWith('#')).toList();
      }

      final postData = {
        'user_id': _supabase.currentUser!.id,
        'car_spot_id': carSpotId,
        'image_url': imageUrl,
        'description': description,
        'hashtags': finalHashtags,
        'username': username, // Store username (display name) in post
        'likes_count': 0,
        'comments_count': 0,
      };

      final response = await _supabase.client
          .from('posts')
          .insert(postData)
          .select()
          .single();

      debugPrint('DatabaseService: Post created successfully with username: $username');
      return response;
    } catch (e) {
      debugPrint('DatabaseService: Error creating post: $e');
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getFollowingFeed({int limit = 20}) async {
    try {
      final response = await _supabase.client
          .rpc('get_following_feed', params: {
            'user_uuid': _supabase.currentUser!.id,
            'limit_count': limit,
          });
      
      final posts = List<Map<String, dynamic>>.from(response);
      
      // Enrich posts with full_name (display name) from user profiles
      final userIds = posts
          .map((post) => post['user_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      Map<String, String?> userDisplayNames = {};
      if (userIds.isNotEmpty) {
        final profilesResponse = await _supabase.client
            .from('user_profiles')
            .select('id, full_name, username')
            .inFilter('id', userIds);
        
        debugPrint('DatabaseService: Fetched ${(profilesResponse as List).length} user profiles for enrichment');
        for (var profile in profilesResponse as List) {
          final userId = profile['id'] as String;
          final fullName = profile['full_name'] as String?;
          final username = profile['username'] as String?;
          // Use full_name (display name) if available, fallback to username
          final displayName = fullName?.isNotEmpty == true ? fullName : (username?.isNotEmpty == true ? username : null);
          userDisplayNames[userId] = displayName;
          debugPrint('DatabaseService: User $userId - full_name: "$fullName", username: "$username", displayName: "$displayName"');
        }
      }
      
      // Process posts to use full_name (display name) if available
      final processedPosts = posts.map((post) {
        final postMap = Map<String, dynamic>.from(post);
        // Use username from post if available (stored when post was created)
        // Otherwise, use full_name (display name) from user profile
        final userId = postMap['user_id'] as String?;
        final postUsername = postMap['username'] as String?;
        
        // If post already has username stored, use it (preferred for performance)
        if (postUsername != null && postUsername.isNotEmpty && postUsername != 'User') {
          // Post already has username, no need to enrich
          return postMap;
        }
        
        // Otherwise, enrich from user profile
        if (userId != null && userDisplayNames.containsKey(userId)) {
          final displayName = userDisplayNames[userId];
          postMap['username'] = displayName?.isNotEmpty == true ? displayName : (postUsername?.isNotEmpty == true ? postUsername : 'User');
          debugPrint('DatabaseService: Following post ${postMap['id']} - userId: $userId, postUsername: "$postUsername", enrichedUsername: "${postMap['username']}"');
        } else if (postMap['username'] == null || (postMap['username'] as String).isEmpty) {
          postMap['username'] = 'User';
        }
        return postMap;
      }).toList();
      
      return processedPosts;
    } catch (e) {
      debugPrint('DatabaseService: Error getting following feed: $e');
      // Fallback to regular query if function doesn't exist
      try {
        final follows = await _supabase.client
            .from('user_follows')
            .select('following_id')
            .eq('follower_id', _supabase.currentUser!.id);
        
        final followingIds = (follows as List)
            .map((f) => f['following_id'] as String)
            .toList();
        
        if (followingIds.isEmpty) {
          return [];
        }
        
        // Build query with IN clause for following IDs (more efficient)
        var query = _supabase.client
            .from('posts')
            .select('*');
        
        // Filter by following IDs using OR conditions
        if (followingIds.length == 1) {
          query = query.eq('user_id', followingIds[0]);
        } else {
          // Build OR filter string
          final orFilter = followingIds
              .map((id) => 'user_id.eq.$id')
              .join(',');
          query = query.or(orFilter);
        }
        
        final postsResponse = await query
            .order('created_at', ascending: false)
            .limit(limit);
        
        // Get user profiles for the posts
        final userIds = (postsResponse as List)
            .map((post) => post['user_id'] as String?)
            .where((id) => id != null)
            .toSet()
            .toList();
        
        Map<String, Map<String, dynamic>> userProfilesMap = {};
        if (userIds.isNotEmpty) {
          final profilesResponse = await _supabase.client
              .from('user_profiles')
              .select('id, full_name, username')
              .inFilter('id', userIds);
          
          for (var profile in profilesResponse as List) {
            userProfilesMap[profile['id'] as String] = {
              'full_name': profile['full_name'],
              'username': profile['username'],
            };
          }
        }
        
        // Get all liked post IDs for current user in one query
        final likedPosts = await _supabase.client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', _supabase.currentUser!.id);
        
        final likedPostIds = (likedPosts as List)
            .map((like) => like['post_id'] as String)
            .toSet();
        
        // Add is_liked field and user profile info to each post
        final posts = (postsResponse as List).map((post) {
          final postMap = Map<String, dynamic>.from(post);
          postMap['is_liked'] = likedPostIds.contains(post['id']);
          
          // Use username from post if available (stored when post was created)
          // Otherwise, use full_name (display name) from user profile
          final userId = post['user_id'] as String?;
          final postUsername = postMap['username'] as String?;
          
          // If post already has username stored and it's valid, use it
          if (postUsername != null && postUsername.isNotEmpty && postUsername != 'User') {
            // Post already has username, no need to enrich
          } else if (userId != null && userProfilesMap.containsKey(userId)) {
            // Otherwise, enrich from user profile
            final userProfile = userProfilesMap[userId]!;
            final fullName = userProfile['full_name'] as String?;
            final usernameFallback = userProfile['username'] as String?;
            final displayName = fullName?.isNotEmpty == true 
                ? fullName 
                : (usernameFallback?.isNotEmpty == true ? usernameFallback : 'User');
            postMap['username'] = displayName;
          } else {
            postMap['username'] = postUsername?.isNotEmpty == true ? postUsername : 'User';
          }
          // avatar_url doesn't exist in user_profiles table
          postMap['avatar_url'] = null;
          
          return postMap;
        }).toList();
        
        return posts;
      } catch (e2) {
        throw Exception('Failed to get following feed: ${e2.toString()}');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getDiscoveryFeed({int limit = 20}) async {
    try {
      final response = await _supabase.client
          .rpc('get_discovery_feed', params: {
            'user_uuid': _supabase.currentUser!.id,
            'limit_count': limit,
          });
      
      final posts = List<Map<String, dynamic>>.from(response);
      debugPrint('DatabaseService: RPC get_discovery_feed returned ${posts.length} posts');
      
      // Log first post structure if available
      if (posts.isNotEmpty) {
        debugPrint('DatabaseService: First post keys: ${posts.first.keys.toList()}');
        debugPrint('DatabaseService: First post data: ${posts.first}');
      }
      
      // If RPC returns empty, try fallback to ensure we get all posts
      // (RPC might still have the old WHERE clause excluding user's posts)
      if (posts.isEmpty) {
        debugPrint('DatabaseService: RPC returned empty, using fallback query...');
        return await _getDiscoveryFeedFallback(limit);
      }
      
      // Enrich posts with full_name (display name) from user profiles
      final userIds = posts
          .map((post) => post['user_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      Map<String, String?> userDisplayNames = {};
      if (userIds.isNotEmpty) {
        final profilesResponse = await _supabase.client
            .from('user_profiles')
            .select('id, full_name, username')
            .inFilter('id', userIds);
        
        debugPrint('DatabaseService: Fetched ${(profilesResponse as List).length} user profiles for discovery feed enrichment');
        for (var profile in profilesResponse as List) {
          final userId = profile['id'] as String;
          final fullName = profile['full_name'] as String?;
          final username = profile['username'] as String?;
          // Use full_name (display name) if available, fallback to username
          final displayName = fullName?.isNotEmpty == true ? fullName : (username?.isNotEmpty == true ? username : null);
          userDisplayNames[userId] = displayName;
          debugPrint('DatabaseService: User $userId - full_name: "$fullName", username: "$username", displayName: "$displayName"');
        }
      }
      
      // Process posts to ensure they have the right structure
      final processedPosts = posts.map((post) {
        final postMap = Map<String, dynamic>.from(post);
        // Use username from post if available (stored when post was created)
        // Otherwise, use full_name (display name) from user profile
        final userId = postMap['user_id'] as String?;
        final postUsername = postMap['username'] as String?;
        
        // If post already has username stored, use it (preferred for performance)
        if (postUsername != null && postUsername.isNotEmpty && postUsername != 'User') {
          // Post already has username, no need to enrich
          return postMap;
        }
        
        // Otherwise, enrich from user profile
        if (userId != null && userDisplayNames.containsKey(userId)) {
          final displayName = userDisplayNames[userId];
          postMap['username'] = displayName?.isNotEmpty == true ? displayName : (postUsername?.isNotEmpty == true ? postUsername : 'User');
          debugPrint('DatabaseService: Discovery post ${postMap['id']} - userId: $userId, postUsername: "$postUsername", enrichedUsername: "${postMap['username']}"');
        } else if (postMap['username'] == null || (postMap['username'] as String).isEmpty) {
          postMap['username'] = 'User';
        }
        return postMap;
      }).toList();
      
      return processedPosts;
    } catch (e) {
      debugPrint('DatabaseService: Error getting discovery feed via RPC: $e');
      // Fallback to regular query if function doesn't exist or fails
      return await _getDiscoveryFeedFallback(limit);
    }
  }

  Future<List<Map<String, dynamic>>> _getDiscoveryFeedFallback(int limit) async {
    try {
      // First, check if there are any posts at all
      final allPostsCheck = await _supabase.client
          .from('posts')
          .select('id')
          .limit(1);
      debugPrint('DatabaseService: Total posts in database: ${(allPostsCheck as List).length}');
      
      // Get all posts and check likes in a single query (including user's own posts)
      // First get posts
      final postsResponse = await _supabase.client
          .from('posts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      
      // Get user IDs from posts
      final userIds = (postsResponse as List)
          .map((post) => post['user_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      // Get user profiles for those users
      Map<String, Map<String, dynamic>> userProfilesMap = {};
      if (userIds.isNotEmpty) {
        final profilesResponse = await _supabase.client
            .from('user_profiles')
            .select('id, full_name, username')
            .inFilter('id', userIds);
        
        for (var profile in profilesResponse as List) {
          userProfilesMap[profile['id'] as String] = {
            'full_name': profile['full_name'],
            'username': profile['username'],
          };
        }
      }
      
      debugPrint('DatabaseService: Raw posts query returned ${(postsResponse as List).length} posts');
      debugPrint('DatabaseService: Found ${userProfilesMap.length} user profiles');
      
      // Get all liked post IDs for current user in one query
      final likedPosts = await _supabase.client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', _supabase.currentUser!.id);
      
      final likedPostIds = (likedPosts as List)
          .map((like) => like['post_id'] as String)
          .toSet();
      
      // Add is_liked field and user profile info to each post
      final posts = (postsResponse as List).map((post) {
        final postMap = Map<String, dynamic>.from(post);
        postMap['is_liked'] = likedPostIds.contains(post['id']);
        
        // Use username from post if available (stored when post was created)
        // Otherwise, use full_name (display name) from user profile
        final userId = post['user_id'] as String?;
        final postUsername = postMap['username'] as String?;
        
        // If post already has username stored and it's valid, use it
        if (postUsername != null && postUsername.isNotEmpty && postUsername != 'User') {
          // Post already has username, no need to enrich
        } else if (userId != null && userProfilesMap.containsKey(userId)) {
          // Otherwise, enrich from user profile
          final userProfile = userProfilesMap[userId]!;
          final fullName = userProfile['full_name'] as String?;
          final usernameFallback = userProfile['username'] as String?;
          final displayName = fullName?.isNotEmpty == true 
              ? fullName 
              : (usernameFallback?.isNotEmpty == true ? usernameFallback : 'User');
          postMap['username'] = displayName;
        } else {
          postMap['username'] = postUsername?.isNotEmpty == true ? postUsername : 'User';
        }
        // avatar_url doesn't exist in user_profiles table
        postMap['avatar_url'] = null;
        
        // Log processed post structure
        debugPrint('DatabaseService: Processed post - id: ${postMap['id']}, username: ${postMap['username']}, image_url: ${postMap['image_url']}');
        
        return postMap;
      }).toList();
      
      debugPrint('DatabaseService: Fallback query returned ${posts.length} posts');
      if (posts.isNotEmpty) {
        debugPrint('DatabaseService: Sample post keys: ${posts.first.keys.toList()}');
      }
      return posts;
    } catch (e2) {
      debugPrint('DatabaseService: Fallback query also failed: $e2');
      throw Exception('Failed to get discovery feed: ${e2.toString()}');
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _supabase.client
          .from('post_likes')
          .insert({
            'post_id': postId,
            'user_id': _supabase.currentUser!.id,
          });
      debugPrint('DatabaseService: Post liked successfully');
    } catch (e) {
      // If already liked, ignore error
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        debugPrint('DatabaseService: Post already liked');
        return;
      }
      debugPrint('DatabaseService: Error liking post: $e');
      throw Exception('Failed to like post: ${e.toString()}');
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      await _supabase.client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _supabase.currentUser!.id);
      debugPrint('DatabaseService: Post unliked successfully');
    } catch (e) {
      debugPrint('DatabaseService: Error unliking post: $e');
      throw Exception('Failed to unlike post: ${e.toString()}');
    }
  }

  Future<bool> isPostLiked(String postId) async {
    try {
      final response = await _supabase.client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', _supabase.currentUser!.id)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('DatabaseService: Error checking if post is liked: $e');
      return false;
    }
  }

  Future<void> followUser(String userId) async {
    try {
      await _supabase.client
          .from('user_follows')
          .insert({
            'follower_id': _supabase.currentUser!.id,
            'following_id': userId,
          });
      debugPrint('DatabaseService: User followed successfully');
    } catch (e) {
      // If already following, ignore error
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        debugPrint('DatabaseService: Already following this user');
        return;
      }
      debugPrint('DatabaseService: Error following user: $e');
      throw Exception('Failed to follow user: ${e.toString()}');
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await _supabase.client
          .from('user_follows')
          .delete()
          .eq('follower_id', _supabase.currentUser!.id)
          .eq('following_id', userId);
      debugPrint('DatabaseService: User unfollowed successfully');
    } catch (e) {
      debugPrint('DatabaseService: Error unfollowing user: $e');
      throw Exception('Failed to unfollow user: ${e.toString()}');
    }
  }

  Future<bool> isFollowingUser(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_follows')
          .select('id')
          .eq('follower_id', _supabase.currentUser!.id)
          .eq('following_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('DatabaseService: Error checking if following user: $e');
      return false;
    }
  }
}
