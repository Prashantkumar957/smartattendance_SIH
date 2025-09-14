// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import 'DebugUserScreen.dart';
import 'LecturesScreen.dart';
import 'face_verification_screen.dart';
import 'auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

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
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // This automatically refreshes when app comes back from QR screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - refreshing dashboard data');
      _loadData();
    }
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _fadeAnimationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is logged in
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) {
        _navigateToLogin();
        return;
      }

      // Get current user
      _currentUser = await ApiService.getStoredUser();
      if (_currentUser == null) {
        _navigateToLogin();
        return;
      }

      print('📊 Loading attendance data for: ${_currentUser!.name}');

      // Load attendance data
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

      final result = await ApiService.getStudentAttendance(limit: 10);

      print('📊 Attendance result success: ${result['success']}');
      print('📊 Attendance result keys: ${result.keys}');

      if (result['success'] == true) {
        setState(() {
          // Handle attendance list
          final attendanceData = result['attendance'];
          if (attendanceData is List) {
            _recentAttendance = attendanceData.cast<Attendance>();
          } else {
            _recentAttendance = <Attendance>[];
          }

          // Handle statistics
          final statsData = result['statistics'];
          if (statsData is Map<String, dynamic>) {
            _attendanceStats = Map<String, dynamic>.from(statsData);
          } else {
            _attendanceStats = {
              'totalClasses': 0,
              'presentClasses': 0,
              'attendancePercentage': 0,
              'absentClasses': 0,
            };
          }

          _hasMarkedToday = _checkIfMarkedToday();
        });

        print('✅ Dashboard updated successfully:');
        print('   Total Classes: ${_attendanceStats['totalClasses']}');
        print('   Present: ${_attendanceStats['presentClasses']}');
        print('   Percentage: ${_attendanceStats['attendancePercentage']}%');
        print('   Recent Entries: ${_recentAttendance.length}');
        print('   Marked Today: $_hasMarkedToday');
      } else {
        print('❌ API returned success=false: ${result['message']}');

        // Set empty data but don't show error since we're handling it gracefully
        setState(() {
          _recentAttendance = <Attendance>[];
          _attendanceStats = {
            'totalClasses': 0,
            'presentClasses': 0,
            'attendancePercentage': 0,
            'absentClasses': 0,
          };
          _hasMarkedToday = false;
        });
      }
    } catch (e) {
      print('💥 Error in _loadAttendanceData: $e');
      print('💥 Error type: ${e.runtimeType}');

      // Set empty data on any exception
      setState(() {
        _recentAttendance = <Attendance>[];
        _attendanceStats = {
          'totalClasses': 0,
          'presentClasses': 0,
          'attendancePercentage': 0,
          'absentClasses': 0,
        };
        _hasMarkedToday = false;
      });

      // Only show error for actual network issues, not data parsing
      if (e.toString().contains('Network') || e.toString().contains('Socket')) {
        _showError('Unable to load attendance data. Please check your connection.');
      }
    }
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    _navigateToLogin();
  }

  // Method to refresh dashboard when returning from QR scanner
  void _refreshAfterAttendance() {
    print('🔄 Refreshing dashboard after attendance marking');
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1421),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00F5FF)),
              SizedBox(height: 16),
              Text(
                'Loading your attendance data...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildAttendanceOverview(),
                    const SizedBox(height: 30),
                    _buildMarkAttendanceCard(),
                    const SizedBox(height: 30),
                    _buildQuickStats(),
                    const SizedBox(height: 30),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Update just the _buildHeader method in dashboard_screen.dart
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: const Color(0xFF1E2A3A),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh Data', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'debug_api',
                  child: Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Test API', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'debug',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Debug Info', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') _logout();
                if (value == 'debug') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DebugUserScreen()),
                  );
                }
                if (value == 'refresh') _loadData();
                if (value == 'debug_api') {
                  ApiService.debugAttendanceAPI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Check console for API test results'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        // ... rest of header remains the same
        Text(
          'Welcome, ${_currentUser?.name ?? 'Student'}!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_currentUser?.employeeId ?? ''} • ${_currentUser?.userClass ?? ''}-${_currentUser?.section ?? ''}',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }


  Widget _buildAttendanceOverview() {
    final percentage = _attendanceStats['attendancePercentage']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00F5FF), Color(0xFF0099CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Live Data',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: CircularProgressPainter(progress: percentage / 100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Present', '${_attendanceStats['presentClasses'] ?? 0}'),
              _buildStatItem('Total', '${_attendanceStats['totalClasses'] ?? 0}'),
              _buildStatItem('Absent', '${_attendanceStats['absentClasses'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
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

  Widget _buildMarkAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasMarkedToday
              ? const Color(0xFF4CAF50)
              : const Color(0xFF00F5FF),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _hasMarkedToday ? Icons.check_circle : Icons.qr_code_scanner,
            size: 48,
            color: _hasMarkedToday
                ? const Color(0xFF4CAF50)
                : const Color(0xFF00F5FF),
          ),
          const SizedBox(height: 16),
          Text(
            _hasMarkedToday
                ? 'Attendance Marked Today!'
                : 'Mark Today\'s Attendance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _hasMarkedToday
                ? 'You have successfully marked your attendance for today'
                : 'Verify your identity and scan the QR code to mark attendance',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_hasMarkedToday) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceVerificationScreen(),
                    ),
                  );
                  // Auto-refresh when returning from QR scanner
                  if (result == true || result == null) {
                    print('🔄 Returned from face verification - refreshing dashboard');
                    await _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Verification',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'This Week',
                '${_getWeeklyAttendance()}/7',
                Icons.calendar_today,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LecturesScreen(),
                    ),
                  );
                },
                child: _buildQuickStatCard(
                  'All Lectures',
                  'View',
                  Icons.school,
                  const Color(0xFF2196F3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Color(0xFF00F5FF), size: 16),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF00F5FF), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentAttendance.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.white30),
                SizedBox(height: 16),
                Text(
                  'No attendance records yet',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                Text(
                  'Start marking your attendance to see history',
                  style: TextStyle(color: Colors.white30, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...(_recentAttendance.take(5).map((record) => _buildActivityItem(record))),
      ],
    );
  }

  Widget _buildActivityItem(Attendance attendance) {
    final isToday = DateFormat('yyyy-MM-dd').format(attendance.markedAt) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: const Color(0xFF00F5FF)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF4CAF50),
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.lectureName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Marked at ${DateFormat('hh:mm a').format(attendance.markedAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'By ${attendance.teacherName}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              attendance.status.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  int _getWeeklyAttendance() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _recentAttendance.where((record) {
      return record.markedAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          record.markedAt.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }

  int _getMonthlyAttendance() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _recentAttendance.where((record) {
      return record.markedAt.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          record.markedAt.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;

  CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top
      2 * 3.14159 * progress, // Progress angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
