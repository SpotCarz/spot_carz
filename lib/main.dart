import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'pages/home_page.dart';
import 'pages/dashboard_page.dart';
import 'services/auth_service.dart';
import 'widgets/background_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xjnrmekknmrqfwewcmwt.supabase.co', // Your Supabase API URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqbnJtZWtrbm1ycWZ3ZXdjbXd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwMjkwNTEsImV4cCI6MjA3NjYwNTA1MX0.YLABvrQ5uMGY3cVaPFVG9ojMjq_o0q3ibPMryU3UzPw', // Your Supabase anon key
  );
  
  runApp(const SpotCarzApp());
}

class SpotCarzApp extends StatelessWidget {
  const SpotCarzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spot Carz - Car Spotting App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final AppLinks _appLinks = AppLinks();
  
  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
    _handleInitialDeepLink();
    _listenToDeepLinks();
    // Check session immediately after a short delay to catch OAuth completion
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          setState(() {});
        }
      }
    });
  }
  
  Future<void> _handleInitialDeepLink() async {
    // Check if app was opened via deep link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('Initial deep link received: $initialLink');
      _processDeepLink(initialLink.toString());
    }
  }
  
  void _listenToDeepLinks() {
    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link received: $uri');
      _processDeepLink(uri.toString());
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }
  
  Future<void> _processDeepLink(String link) async {
    try {
      debugPrint('Processing deep link: $link');
      final uri = Uri.parse(link);
      
      // Check if this is our OAuth callback
      if (uri.scheme == 'spotcarz' && uri.host == 'login-callback') {
        debugPrint('OAuth callback detected');
        
        // Check for authorization code in query parameters
        final code = uri.queryParameters['code'];
        if (code != null) {
          debugPrint('Found authorization code, Supabase will exchange it for tokens');
          // Supabase Flutter SDK handles the code exchange automatically
          // Just wait a moment for it to complete, then check session
          await Future.delayed(const Duration(milliseconds: 500));
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null && mounted) {
            debugPrint('Session created from authorization code!');
            setState(() {});
          }
        }
        
        // Also check fragment for tokens (if Supabase sends them directly)
        final fragment = uri.fragment;
        if (fragment.isNotEmpty) {
          debugPrint('Found fragment, checking for tokens...');
          final accessTokenMatch = RegExp(r'access_token=([^&]+)').firstMatch(fragment);
          if (accessTokenMatch != null) {
            final accessToken = Uri.decodeComponent(accessTokenMatch.group(1)!);
            debugPrint('Found access token in fragment, setting session...');
            try {
              await Supabase.instance.client.auth.setSession(accessToken);
              if (mounted) {
                setState(() {});
              }
            } catch (e) {
              debugPrint('Error setting session from fragment: $e');
            }
          }
        }
        
        // Supabase Flutter should have already processed it, just check session
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && mounted) {
          debugPrint('Session found after processing deep link');
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error processing deep link: $e');
    }
  }
  
  void _setupDeepLinkListener() {
    // Listen for auth state changes to detect when OAuth completes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      debugPrint('AuthWrapper: Auth state changed: $event, Session: ${data.session != null}');
      
      if (event == AuthChangeEvent.signedIn || 
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        // Session was created or updated, force rebuild to show dashboard
        // Note: LoginPage will also handle navigation, so this is just for AuthWrapper
        if (mounted) {
          debugPrint('AuthWrapper: Session detected, forcing rebuild');
          setState(() {});
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Check current session first (for hot reload scenarios where stream might not emit immediately)
    final currentSession = Supabase.instance.client.auth.currentSession;
    
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Use session from stream, or fallback to current session for immediate check
        final session = snapshot.hasData 
            ? snapshot.data!.session 
            : currentSession;
        
        // Show loading only if we truly don't know the state yet
        if (!snapshot.hasData && currentSession == null && 
            snapshot.connectionState == ConnectionState.waiting) {
          return BackgroundContainer(
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),
          );
        }
        
        if (session != null) {
          return BackgroundContainer(
            child: const DashboardPage(),
          );
        } else {
          // HomePage has its own background, don't wrap it
          return const HomePage();
        }
      },
    );
  }
}
