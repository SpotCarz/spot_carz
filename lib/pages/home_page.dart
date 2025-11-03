import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Contenu principal (pas de watermark logo - on utilise le fond BackgroundContainer)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Logo SpotCarz en haut (plus grand, sans fond noir)
                  Image.asset(
                    'assets/images/logos/spotcarz_logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  
                  // Pas de subtitle car déjà dans le logo
                  const SizedBox(height: 60),
                  
                  // Card 1: Spot Cars (hauteur réduite)
                  _buildFeatureCard(
                    context,
                    backgroundImage: 'assets/images/cards/card_bg_1.jpg',
                    icon: 'assets/images/logos/camera_icon.png',
                    title: 'Spot Cars',
                    description: 'Capture and collect your dreams cars',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Card 2: Your collection
                  _buildFeatureCard(
                    context,
                    backgroundImage: 'assets/images/cards/card_bg_2.jpg',
                    icon: 'assets/images/logos/book_icon.png',
                    title: 'Your collection',
                    description: 'Collect in your own catalog',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Card 3: Share your collection
                  _buildFeatureCard(
                    context,
                    backgroundImage: 'assets/images/cards/card_bg_3.jpg',
                    icon: 'assets/images/logos/eye_icon.png',
                    title: 'Share your collection',
                    description: 'Show off the best of your collection',
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Get Started Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple[700]!,
                          Colors.purple[900]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'GET STARTED',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Login Link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: Text(
                      'Already have an account ? Sign In',
                      style: GoogleFonts.roboto(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String backgroundImage,
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      height: 100, // Réduit de 120 à 100
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
            
            // Overlay gradient sombre pour la lisibilité
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 45,
                    height: 45,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      icon,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Texte (tout en Roboto)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
