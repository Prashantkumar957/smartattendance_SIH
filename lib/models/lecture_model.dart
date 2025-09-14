// lib/models/lecture_model.dart
class Lecture {
  final String id;
  final String lectureNumber;
  final String lectureName;
  final String subject;
  final String lectureClass;
  final String section;
  final String department;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final bool qrSessionActive;
  final DateTime? qrSessionStartTime;
  final DateTime? qrSessionEndTime;
  final int totalStudents;
  final int presentStudents;
  final int absentStudents;

  Lecture({
    required this.id,
    required this.lectureNumber,
    required this.lectureName,
    required this.subject,
    required this.lectureClass,
    required this.section,
    required this.department,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.qrSessionActive,
    this.qrSessionStartTime,
    this.qrSessionEndTime,
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['_id'] ?? json['id'] ?? '',
      lectureNumber: json['lectureNumber'] ?? '',
      lectureName: json['lectureName'] ?? '',
      subject: json['subject'] ?? '',
      lectureClass: json['class'] ?? '',
      section: json['section'] ?? '',
      department: json['department'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? 'scheduled',
      qrSessionActive: json['qrSessionActive'] ?? false,
      qrSessionStartTime: json['qrSessionStartTime'] != null
          ? DateTime.parse(json['qrSessionStartTime'])
          : null,
      qrSessionEndTime: json['qrSessionEndTime'] != null
          ? DateTime.parse(json['qrSessionEndTime'])
          : null,
      totalStudents: json['totalStudents'] ?? 0,
      presentStudents: json['presentStudents'] ?? 0,
      absentStudents: json['absentStudents'] ?? 0,
    );
  }
}
