// lib/main.dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0D1421),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Show loading messages
    _updateLoadingMessage('Checking authentication...');
    await Future.delayed(const Duration(seconds: 1));

    final isLoggedIn = await ApiService.isLoggedIn();

    if (isLoggedIn) {
      _updateLoadingMessage('Loading saved attendance...');
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ Preload saved attendance values
      await _preloadSavedData();

      _updateLoadingMessage('Welcome back!');
    } else {
      _updateLoadingMessage('Redirecting to login...');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isLoggedIn
              ? const DashboardScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  // ✅ Preload saved data for faster dashboard loading
  Future<void> _preloadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presentCount = prefs.getInt('attendance_present_count') ?? 0;
      final totalCount = prefs.getInt('attendance_total_count') ?? 0;

      print('✅ Preloaded attendance: Present=$presentCount, Total=$totalCount');
    } catch (e) {
      print('❌ Error preloading data: $e');
    }
  }

  void _updateLoadingMessage(String message) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1421), Color(0xFF1A2332)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5FF), Color(0xFF0080FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Smart Attendance',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Face Recognition & QR Code System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 48),

              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5FF)),
                strokeWidth: 3,
              ),

              const SizedBox(height: 16),

              // ✅ Show loading progress
              Text(
                _loadingMessage,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
