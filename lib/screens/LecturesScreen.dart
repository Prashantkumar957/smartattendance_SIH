// lib/screens/LecturesScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/lecture_model.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

// ✅ Fixed: Use TickerProviderStateMixin instead of SingleTickerProviderStateMixin
class _LecturesScreenState extends State<LecturesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Lecture> _allLectures = [];
  List<Lecture> _todayLectures = [];
  List<Lecture> _upcomingLectures = [];
  List<Lecture> _pastLectures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadLectures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLectures() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getStudentLectures(limit: 50);
      if (result['success']) {
        final lectures = result['lectures'] as List<Lecture>;
        setState(() {
          _allLectures = lectures;
          _categorizeLectures();
        });
        _animationController.forward();
      } else {
        _showError(result['message']);
      }
    } catch (e) {
      _showError('Failed to load lectures: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _categorizeLectures() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _todayLectures = _allLectures.where((lecture) {
      final lectureDate = DateTime(
        lecture.date.year,
        lecture.date.month,
        lecture.date.day,
      );
      return lectureDate.isAtSameMomentAs(today);
    }).toList();

    _upcomingLectures = _allLectures.where((lecture) {
      final lectureDate = DateTime(
        lecture.date.year,
        lecture.date.month,
        lecture.date.day,
      );
      return lectureDate.isAfter(today);
    }).toList();

    _pastLectures = _allLectures.where((lecture) {
      final lectureDate = DateTime(
        lecture.date.year,
        lecture.date.month,
        lecture.date.day,
      );
      return lectureDate.isBefore(today);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Lectures',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Academic Schedule',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadLectures,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, color: Color(0xFF3B82F6), size: 20),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
          tabs: [
            Tab(text: 'All (${_allLectures.length})'),
            Tab(text: 'Today (${_todayLectures.length})'),
            Tab(text: 'Upcoming (${_upcomingLectures.length})'),
            Tab(text: 'Past (${_pastLectures.length})'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : FadeTransition(
          opacity: _fadeAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLecturesList(_allLectures, 'all'),
              _buildLecturesList(_todayLectures, 'today'),
              _buildLecturesList(_upcomingLectures, 'upcoming'),
              _buildLecturesList(_pastLectures, 'past'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading your lectures...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturesList(List<Lecture> lectures, String category) {
    if (lectures.isEmpty) {
      return _buildEmptyState(category);
    }

    return RefreshIndicator(
      onRefresh: _loadLectures,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lectures.length,
        itemBuilder: (context, index) {
          return _buildEnhancedLectureCard(lectures[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    String message;
    IconData icon;

    switch (category) {
      case 'today':
        message = 'No lectures scheduled for today';
        icon = Icons.today;
        break;
      case 'upcoming':
        message = 'No upcoming lectures scheduled';
        icon = Icons.schedule;
        break;
      case 'past':
        message = 'No past lectures found';
        icon = Icons.history;
        break;
      default:
        message = 'No lectures found';
        icon = Icons.school_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for updates',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLectureCard(Lecture lecture) {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(lecture.date) ==
        DateFormat('yyyy-MM-dd').format(now);
    final isPast = lecture.date.isBefore(now);
    final isActive = lecture.qrSessionActive;

    // Calculate attendance percentage
    double attendancePercentage = 0.0;
    if (lecture.totalStudents > 0) {
      attendancePercentage = (lecture.presentStudents / lecture.totalStudents) * 100;
    }

    Color borderColor = Colors.transparent;
    Color accentColor = const Color(0xFF3B82F6);

    if (isActive) {
      borderColor = const Color(0xFF10B981);
      accentColor = const Color(0xFF10B981);
    } else if (isToday) {
      borderColor = const Color(0xFF3B82F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLectureDetails(lecture),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.school,
                                  color: accentColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lecture.lectureName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lecture.subject,
                            style: TextStyle(
                              fontSize: 14,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildEnhancedStatusBadge(lecture, isActive, isToday),
                  ],
                ),

                const SizedBox(height: 16),

                // Enhanced info grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoColumn(
                              Icons.person,
                              'Faculty',
                              lecture.teacherName,
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFF334155),
                          ),
                          Expanded(
                            child: _buildInfoColumn(
                              Icons.schedule,
                              'Time',
                              '${lecture.startTime} - ${lecture.endTime}',
                              const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: const Color(0xFF334155),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoColumn(
                              Icons.calendar_today,
                              'Date',
                              DateFormat('MMM dd, yyyy').format(lecture.date),
                              const Color(0xFF10B981),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFF334155),
                          ),
                          Expanded(
                            child: _buildInfoColumn(
                              Icons.location_on,
                              'Class',
                              '${lecture.lectureClass}-${lecture.section}',
                              const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Attendance stats (if available)
                if (lecture.totalStudents > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.1),
                          accentColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics,
                              color: accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Attendance Statistics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAttendanceItem(
                                'Present',
                                '${lecture.presentStudents}',
                                const Color(0xFF10B981),
                              ),
                            ),
                            Expanded(
                              child: _buildAttendanceItem(
                                'Total',
                                '${lecture.totalStudents}',
                                Colors.white70,
                              ),
                            ),
                            Expanded(
                              child: _buildAttendanceItem(
                                'Rate',
                                '${attendancePercentage.toStringAsFixed(1)}%',
                                accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: attendancePercentage / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                ],

                // Active session indicator
                if (isActive) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.1),
                          const Color(0xFF10B981).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QR Session Active',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'You can mark attendance now!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusBadge(Lecture lecture, bool isActive, bool isToday) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      badgeColor = const Color(0xFF10B981);
      statusText = 'LIVE';
      statusIcon = Icons.radio_button_checked;
    } else {
      switch (lecture.status.toLowerCase()) {
        case 'active':
          badgeColor = const Color(0xFF3B82F6);
          statusText = 'ACTIVE';
          statusIcon = Icons.play_circle_filled;
          break;
        case 'completed':
          badgeColor = const Color(0xFF6B7280);
          statusText = 'COMPLETED';
          statusIcon = Icons.check_circle;
          break;
        case 'cancelled':
          badgeColor = const Color(0xFFEF4444);
          statusText = 'CANCELLED';
          statusIcon = Icons.cancel;
          break;
        default:
          badgeColor = const Color(0xFF8B5CF6);
          statusText = 'SCHEDULED';
          statusIcon = Icons.schedule;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  void _showLectureDetails(Lecture lecture) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EnhancedLectureDetailsBottomSheet(lecture: lecture),
    );
  }
}

// Enhanced bottom sheet for lecture details
class EnhancedLectureDetailsBottomSheet extends StatelessWidget {
  final Lecture lecture;

  const EnhancedLectureDetailsBottomSheet({
    super.key,
    required this.lecture,
  });

  @override
  Widget build(BuildContext context) {
    final attendancePercentage = lecture.totalStudents > 0
        ? (lecture.presentStudents / lecture.totalStudents) * 100
        : 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lecture.lectureName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lecture.subject,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick stats
                      if (lecture.totalStudents > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                const Color(0xFF3B82F6).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.analytics, color: Color(0xFF3B82F6), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Attendance Overview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    '${attendancePercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: attendancePercentage / 100,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Present', '${lecture.presentStudents}', const Color(0xFF10B981)),
                                  _buildStatItem('Total', '${lecture.totalStudents}', Colors.white70),
                                  _buildStatItem('Absent', '${lecture.absentStudents}', const Color(0xFFEF4444)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Detailed information sections
                      _buildDetailSection('Lecture Information', [
                        _buildDetailItem('Lecture Number', lecture.lectureNumber, Icons.numbers),
                        _buildDetailItem('Subject', lecture.subject, Icons.book),
                        _buildDetailItem('Department', lecture.department, Icons.business),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Schedule Details', [
                        _buildDetailItem(
                          'Date',
                          DateFormat('EEEE, MMMM dd, yyyy').format(lecture.date),
                          Icons.calendar_today,
                        ),
                        _buildDetailItem('Start Time', lecture.startTime, Icons.schedule),
                        _buildDetailItem('End Time', lecture.endTime, Icons.schedule_outlined),
                        _buildDetailItem('Status', lecture.status.toUpperCase(), Icons.info_outline),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('Class Information', [
                        _buildDetailItem('Faculty', lecture.teacherName, Icons.person),
                        _buildDetailItem('Class', lecture.lectureClass, Icons.class_),
                        _buildDetailItem('Section', lecture.section, Icons.group),
                      ]),

                      // Active session notification
                      if (lecture.qrSessionActive) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withValues(alpha: 0.1),
                                const Color(0xFF10B981).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'QR Session Active',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'The faculty has started the QR session for this lecture. Students can now scan the QR code to mark their attendance.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF334155).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
