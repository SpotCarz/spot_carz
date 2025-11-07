import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/spotCarz_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Top Section: Logo Image and Tagline
                Image.asset(
                  'assets/images/logos/main_logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 60),
                
                // Middle Section: Card with Carousel
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildCard(
                        backgroundImage: 'assets/images/cards/spot_img_card_welcome.png',
                        icon: 'assets/images/logos/camera.png',
                        title: 'Spot cars',
                        description: 'Capture your dreams cars',
                        highlightWord: 'Capture',
                      ),
                      _buildCard(
                        backgroundImage: 'assets/images/cards/collect_img_card_welcome.png',
                        icon: 'assets/images/logos/livre.png',
                        title: 'Collection',
                        description: 'Collect in your catalog',
                        highlightWord: 'Collect',
                      ),
                      _buildCard(
                        backgroundImage: 'assets/images/cards/share_img_card_welcome.png',
                        icon: 'assets/images/logos/camera.png',
                        title: 'Show off',
                        description: 'Share with the community',
                        highlightWord: 'Share',
                      ),
                    ],
                  ),
                ),
                
                // Pagination Dots
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? const Color.fromARGB(255, 189, 34, 209) // Purple
                            : Colors.white,
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 40),
                
                // Bottom Section: Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 145, 1, 202), // Deep purple
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
                
                // Sign In Link
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
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String backgroundImage,
    required String icon,
    required String title,
    required String description,
    required String highlightWord,
  }) {
    // Split description to highlight a word
    final highlightIndex = description.indexOf(highlightWord);
    final hasHighlight = highlightIndex >= 0;
    final beforeHighlight = hasHighlight 
        ? description.substring(0, highlightIndex) 
        : '';
    final afterHighlight = hasHighlight && highlightIndex + highlightWord.length < description.length
        ? description.substring(highlightIndex + highlightWord.length)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image - Centered
            Positioned.fill(
              child: Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[900]);
                },
              ),
            ),
            
            // Dark Overlay - Reduced opacity
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),
            
            // Content - Centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with Neon Glow at Top Center
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Outer glow - large, soft
                          BoxShadow(
                            color: Color.fromARGB(255, 253, 200, 255).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        icon,
                        width: 70,
                        height: 70,
                        color: const Color.fromARGB(255, 253, 200, 255), // Purple color
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.camera_alt,
                            size: 70,
                            color: Color.fromARGB(255, 253, 200, 255),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  Center(
                    child: Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description with highlighted word
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        children: [
                          if (beforeHighlight.isNotEmpty) TextSpan(text: beforeHighlight),
                          if (hasHighlight)
                            TextSpan(
                              text: highlightWord,
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(209, 197, 0, 223), // Purple highlight
                              ),
                            ),
                          if (afterHighlight.isNotEmpty) TextSpan(text: afterHighlight),
                          if (!hasHighlight) TextSpan(text: description),
                        ],
                      ),
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
