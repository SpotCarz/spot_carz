import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../widgets/background_container.dart';

class CreatePostPage extends StatefulWidget {
  final CarSpot? initialCarSpot;
  
  const CreatePostPage({super.key, this.initialCarSpot});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  File? _selectedImage;
  CarSpot? _selectedCarSpot;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If a car is passed, pre-select it
    if (widget.initialCarSpot != null) {
      _selectedCarSpot = widget.initialCarSpot;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedCarSpot = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _selectFromGarage() async {
    try {
      final carSpots = await _databaseService.getCarSpots();
      if (carSpots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Votre garage est vide',
              style: GoogleFonts.righteous(),
            ),
            backgroundColor: Colors.purple[700],
          ),
        );
        return;
      }

      // Show modal with owned cars
      final selectedCar = await showDialog<CarSpot>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple[900]!.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.purple[900]!.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sélectionner une voiture',
                          style: GoogleFonts.righteous(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Cars List
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: carSpots.length,
                      itemBuilder: (context, index) {
                        final car = carSpots[index];
                        return InkWell(
                          onTap: () => Navigator.pop(context, car),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Car Image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[800],
                                  ),
                                  child: car.imageUrls.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            car.imageUrls.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.directions_car,
                                                color: Colors.grey[400],
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.directions_car,
                                          color: Colors.grey[400],
                                        ),
                                ),
                                const SizedBox(width: 16),
                                // Car Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${car.brand.replaceAll('_', ' ')} ${car.model}',
                                        style: GoogleFonts.righteous(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (car.year != null)
                                        Text(
                                          '${car.year}',
                                          style: GoogleFonts.righteous(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedCar != null) {
        setState(() {
          _selectedCarSpot = selectedCar;
          _selectedImage = null;
        });
      }
    } catch (e) {
      debugPrint('Error selecting from garage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du chargement du garage',
            style: GoogleFonts.righteous(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _publishPost() async {
    if (_selectedImage == null && _selectedCarSpot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner une image',
            style: GoogleFonts.righteous(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract hashtags from hashtags field
      List<String> hashtags = [];
      if (_hashtagsController.text.isNotEmpty) {
        hashtags = _hashtagsController.text
            .split(' ')
            .where((word) => word.trim().isNotEmpty)
            .map((word) => word.startsWith('#') ? word : '#$word')
            .toList();
      }

      // Create post in database
      await _databaseService.createPost(
        carSpotId: _selectedCarSpot?.id,
        imageFile: _selectedImage,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        hashtags: hashtags.isEmpty ? null : hashtags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Post publié avec succès!',
              style: GoogleFonts.righteous(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la publication: ${e.toString()}',
              style: GoogleFonts.righteous(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Car Meet',
                                style: GoogleFonts.righteous(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Créer une publication',
                            style: GoogleFonts.righteous(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Media Selection Options
                      GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Choisir à partir de la gallerie',
                                style: GoogleFonts.righteous(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: _selectFromGarage,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.garage,
                                size: 60,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Choisir à partir du garage',
                                style: GoogleFonts.righteous(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Selected Image Preview
                      if (_selectedImage != null || _selectedCarSpot != null)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : _selectedCarSpot != null && _selectedCarSpot!.imageUrls.isNotEmpty
                                    ? Image.network(
                                        _selectedCarSpot!.imageUrls.first,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                        ),
                      
                      // Description Field
                      TextField(
                        controller: _descriptionController,
                        style: GoogleFonts.righteous(color: Colors.white),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Ecrire une description',
                          hintStyle: GoogleFonts.righteous(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[700]!,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[700]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[400]!,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Hashtags Field
                      TextField(
                        controller: _hashtagsController,
                        style: GoogleFonts.righteous(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Choisir des #',
                          hintStyle: GoogleFonts.righteous(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[700]!,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[700]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[400]!,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Publish Button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _publishPost,
                        icon: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Publier',
                          style: GoogleFonts.righteous(
                            fontSize: 18,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

