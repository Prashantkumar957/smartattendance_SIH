// lib/screens/lectures_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/lecture_model.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Lecture> _allLectures = [];
  List<Lecture> _todayLectures = [];
  List<Lecture> _upcomingLectures = [];
  List<Lecture> _pastLectures = [];

  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, today, upcoming, past

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLectures();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2332),
        elevation: 0,
        title: const Text(
          'My Lectures',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadLectures,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F5FF),
          labelColor: const Color(0xFF00F5FF),
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'All (${_allLectures.length})',
            ),
            Tab(
              text: 'Today (${_todayLectures.length})',
            ),
            Tab(
              text: 'Upcoming (${_upcomingLectures.length})',
            ),
            Tab(
              text: 'Past (${_pastLectures.length})',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1421), Color(0xFF1A2332)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5FF)),
          ),
        )
            : TabBarView(
          controller: _tabController,
          children: [
            _buildLecturesList(_allLectures),
            _buildLecturesList(_todayLectures),
            _buildLecturesList(_upcomingLectures),
            _buildLecturesList(_pastLectures),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturesList(List<Lecture> lectures) {
    if (lectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No lectures found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new lectures',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLectures,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lectures.length,
        itemBuilder: (context, index) {
          return _buildLectureCard(lectures[index]);
        },
      ),
    );
  }

  Widget _buildLectureCard(Lecture lecture) {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(lecture.date) ==
        DateFormat('yyyy-MM-dd').format(now);
    final isPast = lecture.date.isBefore(now);
    final isActive = lecture.qrSessionActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4CAF50)
              : isToday
              ? const Color(0xFF00F5FF)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showLectureDetails(lecture),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecture.lectureName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lecture.subject,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF00F5FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(lecture),
                ],
              ),

              const SizedBox(height: 16),

              // Lecture Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person_outline,
                      'Teacher',
                      lecture.teacherName,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.schedule_outlined,
                      'Time',
                      '${lecture.startTime} - ${lecture.endTime}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today_outlined,
                      'Date',
                      DateFormat('MMM dd, yyyy').format(lecture.date),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.location_on_outlined,
                      'Class',
                      '${lecture.lectureClass}-${lecture.section}',
                    ),
                  ),
                ],
              ),

              // Attendance Info (if available)
              if (lecture.totalStudents > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1421),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttendanceItem(
                        'Present',
                        '${lecture.presentStudents}',
                        const Color(0xFF4CAF50),
                      ),
                      _buildAttendanceItem(
                        'Total',
                        '${lecture.totalStudents}',
                        Colors.white70,
                      ),
                      _buildAttendanceItem(
                        'Percentage',
                        '${lecture.totalStudents > 0 ? ((lecture.presentStudents / lecture.totalStudents) * 100).round() : 0}%',
                        const Color(0xFF00F5FF),
                      ),
                    ],
                  ),
                ),
              ],

              // Active Session Indicator
              if (isActive) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'QR Session Active - You can mark attendance now!',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Lecture lecture) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (lecture.status) {
      case 'active':
        badgeColor = const Color(0xFF4CAF50);
        statusText = 'ACTIVE';
        statusIcon = Icons.play_circle_filled;
        break;
      case 'completed':
        badgeColor = const Color(0xFF757575);
        statusText = 'COMPLETED';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        badgeColor = const Color(0xFFF44336);
        statusText = 'CANCELLED';
        statusIcon = Icons.cancel;
        break;
      default:
        badgeColor = const Color(0xFF00F5FF);
        statusText = 'SCHEDULED';
        statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00F5FF)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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

  void _showLectureDetails(Lecture lecture) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LectureDetailsBottomSheet(lecture: lecture),
    );
  }
}
// Add this to the same file or create a separate widget file
class LectureDetailsBottomSheet extends StatelessWidget {
  final Lecture lecture;

  const LectureDetailsBottomSheet({
    super.key,
    required this.lecture,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2332),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lecture.lectureName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            lecture.subject,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF00F5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Lecture Information', [
                        _buildDetailItem('Lecture Number', lecture.lectureNumber),
                        _buildDetailItem('Subject', lecture.subject),
                        _buildDetailItem('Department', lecture.department),
                      ]),

                      const SizedBox(height: 24),

                      _buildDetailSection('Schedule', [
                        _buildDetailItem(
                          'Date',
                          DateFormat('EEEE, MMMM dd, yyyy').format(lecture.date),
                        ),
                        _buildDetailItem('Start Time', lecture.startTime),
                        _buildDetailItem('End Time', lecture.endTime),
                        _buildDetailItem('Status', lecture.status.toUpperCase()),
                      ]),

                      const SizedBox(height: 24),

                      _buildDetailSection('Class Information', [
                        _buildDetailItem('Teacher', lecture.teacherName),
                        _buildDetailItem('Class', lecture.lectureClass),
                        _buildDetailItem('Section', lecture.section),
                      ]),

                      if (lecture.totalStudents > 0) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection('Attendance Summary', [
                          _buildDetailItem('Total Students', '${lecture.totalStudents}'),
                          _buildDetailItem('Present', '${lecture.presentStudents}'),
                          _buildDetailItem('Absent', '${lecture.absentStudents}'),
                          _buildDetailItem(
                            'Attendance Rate',
                            '${lecture.totalStudents > 0 ? ((lecture.presentStudents / lecture.totalStudents) * 100).round() : 0}%',
                          ),
                        ]),
                      ],

                      if (lecture.qrSessionActive) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: const Color(0xFF4CAF50),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'QR Session Active',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'The teacher has started the QR session for this lecture. You can now scan the QR code to mark your attendance.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
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

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1421),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
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
