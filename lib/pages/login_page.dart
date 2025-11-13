import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    
    // Poll for session changes (for OAuth callback detection)
    _pollForSession();
    
    // Listen for auth state changes to handle OAuth callback
    _authStateSubscription = _authService.authStateChanges.listen((authState) {
      debugPrint('LoginPage: Auth state changed, session: ${authState.session != null}');
      if (mounted && authState.session != null && !_isNavigating) {
        debugPrint('LoginPage: Session detected in stream, navigating...');
        _navigateToDashboard();
      }
    });
  }
  
  void _pollForSession() {
    // Check for session periodically, especially after OAuth
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _checkSessionAndNavigate();
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _checkSessionAndNavigate();
    });
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _checkSessionAndNavigate();
    });
  }
  
  void _checkSessionAndNavigate() {
    if (!mounted) return;
    
    // Check session directly from Supabase
    final session = _authService.client.auth.currentSession;
    
    if (session != null) {
      debugPrint('LoginPage: Session found in poll, navigating...');
      _navigateToDashboard();
    }
  }
  
  void _navigateToDashboard() {
    if (!mounted) return;
    
    // Prevent multiple navigations
    if (_isNavigating) return;
    _isNavigating = true;
    
    setState(() {
      _isLoading = false;
    });
    
    // Small delay to ensure state is updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      // Navigate to dashboard, replacing the entire navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
        (route) => false,
      );
    });
  }
  
  bool _isNavigating = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
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
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithGoogle();
      // Note: OAuth flow will handle navigation automatically via deep link
      // The auth state listener in main.dart will detect the session
      // Also listening in initState to reset loading when session is created
      
      // Set a timeout to reset loading if OAuth doesn't complete
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo and Tagline
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logos/main_logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0033),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.righteous(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your email',
                            hintStyle: GoogleFonts.righteous(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0033),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: GoogleFonts.righteous(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your password',
                            hintStyle: GoogleFonts.righteous(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Connection Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 145, 1, 202), // Deep purple from home_page
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'CONNECTION',
                                  style: GoogleFonts.righteous(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sign Up Link
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.righteous(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account ? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: GoogleFonts.righteous(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: GoogleFonts.righteous(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sign in with Google Text
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.righteous(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                            children: [
                              const TextSpan(text: 'Sign in with '),
                              TextSpan(
                                text: 'Google',
                                style: GoogleFonts.righteous(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 197, 0, 223), // Purple highlight from home_page
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 145, 1, 202), // Deep purple from home_page
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logos/google_logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SIGN IN WITH GOOGLE',
                                style: GoogleFonts.righteous(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
