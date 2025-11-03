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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                const SizedBox(height: 40),
                
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: 40,
                          color: Colors.red[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue spotting cars',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey[300],
                        ),
                      ),
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
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.roboto(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
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
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: GoogleFonts.roboto(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.roboto(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
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
                      
                      const SizedBox(height: 16),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.roboto(
                              color: Colors.red[400],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
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
                                  'SIGN IN',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
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
                              color: Colors.grey[600],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.roboto(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Social Login Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Google',
                              onPressed: _isLoading ? null : _signInWithGoogle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSocialButton(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      
                const SizedBox(height: 30),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.roboto(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.roboto(
                          color: Colors.red[400],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40), // Add extra bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Reset Password',
          style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a password reset link.',
              style: GoogleFonts.roboto(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.roboto(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.roboto(color: Colors.grey[400]),
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
            child: Text('Cancel', style: GoogleFonts.roboto(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture the dialog's BuildContext to avoid using the surrounding
              // State's `context` across an async gap without proper checks.
              final dialogContext = context;

              if (emailController.text.isNotEmpty) {
                try {
                  await _authService.resetPassword(emailController.text.trim());

                  // Guard State and BuildContext usage after async work.
                  if (!mounted) return;
                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text('Send', style: GoogleFonts.roboto(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
