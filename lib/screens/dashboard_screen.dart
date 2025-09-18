// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import 'LecturesScreen.dart';
import 'ProfileScreen.dart';
import 'face_verification_screen.dart';
import 'auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final Attendance? newAttendance; // ✅ Add parameter to receive attendance

  const DashboardScreen({
    super.key,
    this.newAttendance, // ✅ Optional parameter
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  User? _currentUser;
  List<Attendance> _recentAttendance = [];
  Map<String, dynamic> _attendanceStats = {};
  bool _isLoading = true;
  bool _hasMarkedToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();

    // ✅ Check if attendance data was passed from success screen
    if (widget.newAttendance != null) {
      _handleNewAttendanceFromSuccess();
    } else {
      _loadData();
    }
  }

  // ✅ Handle new attendance passed from success screen
  Future<void> _handleNewAttendanceFromSuccess() async {
    setState(() => _isLoading = true);

    try {
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        _navigateToLogin();
        return;
      }

      _currentUser = await ApiService.getStoredUser();
      if (_currentUser == null) {
        _navigateToLogin();
        return;
      }

      print('🎯 Processing new attendance from success screen...');

      // Load existing data first
      await _loadAttendanceData();

      // Process the new attendance with increment
      await _processNewAttendanceWithIncrement(widget.newAttendance!);

    } catch (e) {
      print('❌ Error handling new attendance: $e');
      _showError('Failed to process attendance: $e');
      await _loadData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Process new attendance and increment values
  Future<void> _processNewAttendanceWithIncrement(Attendance attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> storedAttendance = prefs.getStringList('manual_attendance') ?? [];

      // Check if this attendance already exists to prevent duplicates
      final alreadyExists = _recentAttendance.any((existing) =>
      existing.markedAt.millisecondsSinceEpoch == attendance.markedAt.millisecondsSinceEpoch &&
          existing.lectureName == attendance.lectureName);

      if (!alreadyExists) {
        // Add new attendance to local storage
        storedAttendance.insert(0, ApiService.jsonEncode(attendance.toJson()));

        // Keep only last 20 records
        if (storedAttendance.length > 20) {
          storedAttendance = storedAttendance.take(20).toList();
        }

        await prefs.setStringList('manual_attendance', storedAttendance);
        print('✅ New attendance saved to local storage');

        // ✅ IMMEDIATE UI UPDATE WITH +1 INCREMENT
        setState(() {
          // Add to recent activity at the top
          _recentAttendance.insert(0, attendance);

          // ✅ INCREMENT VALUES BY 1
          _attendanceStats['totalClasses'] = (_attendanceStats['totalClasses'] ?? 0) + 1;
          _attendanceStats['presentClasses'] = (_attendanceStats['presentClasses'] ?? 0) + 1;

          // Recalculate percentage
          int total = _attendanceStats['totalClasses'];
          int present = _attendanceStats['presentClasses'];
          _attendanceStats['attendancePercentage'] = total > 0 ? ((present / total) * 100).round() : 0;

          _hasMarkedToday = true;
        });

        // ✅ SAVE PRESENT VALUE TO SHARED PREFERENCES
        await _savePresentValueLocally(_attendanceStats['presentClasses']);

        // ✅ Show "Attendance Updated" notification
        _showAttendanceUpdatedNotification(attendance);

        print('✅ Dashboard values incremented and saved:');
        print(' Present: +1 → ${_attendanceStats['presentClasses']}');
        print(' Total: +1 → ${_attendanceStats['totalClasses']}');
        print(' Percentage: ${_attendanceStats['attendancePercentage']}%');
      }
    } catch (e) {
      print('❌ Error processing new attendance: $e');
    }
  }

  // ✅ Save Present value to SharedPreferences
  Future<void> _savePresentValueLocally(int presentCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('attendance_present_count', presentCount);
      await prefs.setInt('attendance_total_count', _attendanceStats['totalClasses']);
      await prefs.setInt('attendance_percentage', _attendanceStats['attendancePercentage']);
      print('✅ Present value saved locally: $presentCount');
    } catch (e) {
      print('❌ Error saving present value: $e');
    }
  }

  // ✅ Load Present value from SharedPreferences
  Future<Map<String, int>> _loadSavedAttendanceValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presentCount = prefs.getInt('attendance_present_count') ?? 0;
      final totalCount = prefs.getInt('attendance_total_count') ?? 0;
      final percentage = prefs.getInt('attendance_percentage') ?? 0;

      print('✅ Loaded saved attendance values:');
      print(' Present: $presentCount');
      print(' Total: $totalCount');
      print(' Percentage: $percentage%');

      return {
        'presentClasses': presentCount,
        'totalClasses': totalCount,
        'attendancePercentage': percentage,
      };
    } catch (e) {
      print('❌ Error loading saved values: $e');
      return {
        'presentClasses': 0,
        'totalClasses': 0,
        'attendancePercentage': 0,
      };
    }
  }

  // ✅ Show "Attendance Updated" notification
  void _showAttendanceUpdatedNotification(Attendance attendance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF065F46)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉 Dashboard Updated!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Present +1 • ${attendance.lectureName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+1',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - refreshing dashboard data');
      _loadData();
    }
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        _navigateToLogin();
        return;
      }

      _currentUser = await ApiService.getStoredUser();
      if (_currentUser == null) {
        _navigateToLogin();
        return;
      }

      print('📊 Loading attendance data for: ${_currentUser!.name}');
      await _loadAttendanceData();
    } catch (e) {
      print('❌ Error loading data: $e');
      _showError('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      print('📊 Loading attendance data...');

      // ✅ FIRST LOAD SAVED VALUES FROM LOCAL STORAGE
      final savedValues = await _loadSavedAttendanceValues();

      // Get API data
      final result = await ApiService.getStudentAttendance(limit: 10);
      print('📊 API Result: ${result['success']} - ${result['attendance']?.length ?? 0} records');

      // Get local manual attendance data
      final localData = await _getLocalAttendanceData();

      if (result['success'] == true) {
        setState(() {
          final attendanceData = result['attendance'];
          if (attendanceData is List) {
            _recentAttendance = attendanceData.cast<Attendance>();
          } else {
            _recentAttendance = [];
          }

          // Add local manual attendance
          _recentAttendance.addAll(localData['manualAttendance']);
          _recentAttendance.sort((a, b) => b.markedAt.compareTo(a.markedAt));

          // ✅ USE SAVED VALUES OR API VALUES (WHICHEVER IS HIGHER)
          final statsData = result['statistics'];
          if (statsData is Map) {
            _attendanceStats = Map<String, dynamic>.from(statsData);
          } else {
            _attendanceStats = {
              'totalClasses': 0,
              'presentClasses': 0,
              'attendancePercentage': 0,
              'absentClasses': 0,
            };
          }

          // Add manual attendance count
          final manualCount = localData['count'] as int;
          _attendanceStats['totalClasses'] = (_attendanceStats['totalClasses'] ?? 0) + manualCount;
          _attendanceStats['presentClasses'] = (_attendanceStats['presentClasses'] ?? 0) + manualCount;

          // ✅ USE SAVED VALUES IF THEY'RE HIGHER (MEANS USER MARKED ATTENDANCE OFFLINE)
          if (savedValues['presentClasses']! > _attendanceStats['presentClasses']) {
            _attendanceStats['presentClasses'] = savedValues['presentClasses'];
            _attendanceStats['totalClasses'] = savedValues['totalClasses'];
          }

          // Recalculate percentage
          int total = _attendanceStats['totalClasses'];
          int present = _attendanceStats['presentClasses'];
          _attendanceStats['attendancePercentage'] = total > 0 ? ((present / total) * 100).round() : 0;

          _hasMarkedToday = _checkIfMarkedToday();
        });

        print('✅ Dashboard updated successfully:');
        print(' Total Classes: ${_attendanceStats['totalClasses']}');
        print(' Present: ${_attendanceStats['presentClasses']}');
        print(' Percentage: ${_attendanceStats['attendancePercentage']}%');
        print(' Recent Entries: ${_recentAttendance.length}');
        print(' Marked Today: $_hasMarkedToday');
      } else {
        // ✅ SHOW SAVED VALUES EVEN IF API FAILS
        setState(() {
          _recentAttendance = localData['manualAttendance'];
          _attendanceStats = {
            'totalClasses': savedValues['totalClasses']!,
            'presentClasses': savedValues['presentClasses']!,
            'attendancePercentage': savedValues['attendancePercentage']!,
            'absentClasses': 0,
          };
          _hasMarkedToday = _checkIfMarkedToday();
        });
      }
    } catch (e) {
      print('💥 Error in _loadAttendanceData: $e');

      // ✅ FALLBACK TO SAVED VALUES
      final savedValues = await _loadSavedAttendanceValues();
      final localData = await _getLocalAttendanceData();
      setState(() {
        _recentAttendance = localData['manualAttendance'];
        _attendanceStats = {
          'totalClasses': savedValues['totalClasses']!,
          'presentClasses': savedValues['presentClasses']!,
          'attendancePercentage': savedValues['attendancePercentage']!,
          'absentClasses': 0,
        };
        _hasMarkedToday = false;
      });
    }
  }

  // Enhanced local attendance storage
  Future<Map<String, dynamic>> _getLocalAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> storedAttendance = prefs.getStringList('manual_attendance') ?? [];

      List<Attendance> manualAttendance = [];
      for (String attendanceJson in storedAttendance) {
        try {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
              Map.from(ApiService.jsonDecode(attendanceJson))
          );
          manualAttendance.add(Attendance.fromJson(data));
        } catch (e) {
          print('Error parsing manual attendance: $e');
        }
      }

      return {
        'manualAttendance': manualAttendance,
        'count': manualAttendance.length,
      };
    } catch (e) {
      print('Error getting local attendance data: $e');
      return {
        'manualAttendance': <Attendance>[],
        'count': 0,
      };
    }
  }

  // Enhanced manual attendance with immediate increment
  Future<void> addManualAttendance(Attendance attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> storedAttendance = prefs.getStringList('manual_attendance') ?? [];

      // Add new attendance to beginning
      storedAttendance.insert(0, ApiService.jsonEncode(attendance.toJson()));

      // Keep only last 20 records
      if (storedAttendance.length > 20) {
        storedAttendance = storedAttendance.take(20).toList();
      }

      await prefs.setStringList('manual_attendance', storedAttendance);
      print('✅ Manual attendance saved locally');

      // 🎯 Immediate UI update without API call
      setState(() {
        // Add to recent activity
        _recentAttendance.insert(0, attendance);

        // Update stats immediately
        _attendanceStats['totalClasses'] = (_attendanceStats['totalClasses'] ?? 0) + 1;
        _attendanceStats['presentClasses'] = (_attendanceStats['presentClasses'] ?? 0) + 1;

        // Recalculate percentage
        int total = _attendanceStats['totalClasses'];
        int present = _attendanceStats['presentClasses'];
        _attendanceStats['attendancePercentage'] = total > 0 ? ((present / total) * 100).round() : 0;

        _hasMarkedToday = true;
      });

      // ✅ SAVE UPDATED VALUES LOCALLY
      await _savePresentValueLocally(_attendanceStats['presentClasses']);

      // Show success announcement
      _showAttendanceMarkedAnnouncement(attendance);
    } catch (e) {
      print('❌ Error saving manual attendance: $e');
    }
  }

  void _showAttendanceMarkedAnnouncement(Attendance attendance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉 Attendance Marked Successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${attendance.lectureName} • ${attendance.teacherName}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _checkIfMarkedToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _recentAttendance.any((attendance) =>
    DateFormat('yyyy-MM-dd').format(attendance.markedAt) == today);
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('manual_attendance');
    // ✅ Clear saved attendance values on logout
    await prefs.remove('attendance_present_count');
    await prefs.remove('attendance_total_count');
    await prefs.remove('attendance_percentage');
    _navigateToLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading your dashboard...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF3B82F6),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedHeader(),
                    const SizedBox(height: 24),
                    _buildEnhancedAttendanceCard(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildEnhancedRecentActivity(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    final greeting = _getGreeting();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Enhanced Profile Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                _currentUser?.name.substring(0, 1).toUpperCase() ?? 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser?.name ?? 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_currentUser?.userClass ?? ''}-${_currentUser?.section ?? ''}',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_currentUser?.employeeId ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Enhanced Menu
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF334155).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
            ),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF3B82F6), size: 18),
                    SizedBox(width: 12),
                    Text('Profile', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 12),
                    Text('Refresh', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(user: _currentUser!)),
                  );
                  break;
                case 'refresh':
                  _loadData();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAttendanceCard() {
    final percentage = _attendanceStats['attendancePercentage']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with live indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Real-time tracking',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMM dd').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: EnhancedCircularProgressPainter(progress: percentage / 100),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Present', '${_attendanceStats['presentClasses'] ?? 0}', Icons.check_circle, Colors.green),
              _buildStatColumn('Total', '${_attendanceStats['totalClasses'] ?? 0}', Icons.school, Colors.white),
              _buildStatColumn('Absent', '${_attendanceStats['absentClasses'] ?? 0}', Icons.cancel, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hasMarkedToday ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _hasMarkedToday ? Icons.check_circle : Icons.qr_code_scanner,
                  color: _hasMarkedToday ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasMarkedToday ? 'Attendance Marked Today!' : 'Mark Today\'s Attendance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _hasMarkedToday
                          ? 'Great job! You\'re all set for today.'
                          : 'Scan QR code to mark your presence',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!_hasMarkedToday) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceVerificationScreen(),
                    ),
                  );

                  if (result is Map && result['success'] == true) {
                    final attendance = result['attendance'] as Attendance;
                    await addManualAttendance(attendance);
                  } else {
                    await _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text(
                  'Start Face Verification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'This Week',
            '${_getWeeklyAttendance()}/7',
            Icons.calendar_today,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LecturesScreen()),
              );
            },
            child: _buildStatCard(
              'All Lectures',
              'View Details',
              Icons.school,
              const Color(0xFF8B5CF6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_recentAttendance.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: _recentAttendance
                  .take(4)
                  .map((record) => _buildEnhancedActivityItem(record))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF334155).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.history, size: 40, color: Colors.white30),
          ),
          const SizedBox(height: 16),
          const Text(
            'No attendance records yet',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start marking attendance to see your history',
            style: TextStyle(color: Colors.white30, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActivityItem(Attendance attendance) {
    final isToday = DateFormat('yyyy-MM-dd').format(attendance.markedAt) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: const Color(0xFF3B82F6), width: 1) : null,
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          // Lecture info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attendance.lectureName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      attendance.teacherName,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM dd').format(attendance.markedAt)} • ${DateFormat('hh:mm a').format(attendance.markedAt)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Row(
                  children: [
                    Icon(Icons.class_, size: 12, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      '${attendance.lectureClass}-${attendance.section}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'PRESENT',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getWeeklyAttendance() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _recentAttendance.where((record) {
      return record.markedAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          record.markedAt.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌆';
  }
}

// Enhanced circular progress painter
class EnhancedCircularProgressPainter extends CustomPainter {
  final double progress;

  EnhancedCircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with gradient effect
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top
      2 * 3.14159 * progress, // Progress angle
      false,
      progressPaint,
    );

    // Add a glow effect
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      2 * 3.14159 * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
