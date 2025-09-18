// lib/models/attendance_model.dart
class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmployeeId;
  final String lectureId;
  final String lectureName;
  final String lectureClass;
  final String section;
  final String teacherId;
  final String teacherName;
  final String status;
  final DateTime markedAt;
  final String markedBy;
  final String? ipAddress;
  final String? userAgent;
  final String qrSessionId;

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmployeeId,
    required this.lectureId,
    required this.lectureName,
    required this.lectureClass,
    required this.section,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    required this.markedAt,
    required this.markedBy,
    this.ipAddress,
    this.userAgent,
    required this.qrSessionId,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmployeeId: json['studentEmployeeId'] ?? '',
      lectureId: json['lectureId'] ?? '',
      lectureName: json['lectureName'] ?? '',
      lectureClass: json['class'] ?? '',
      section: json['section'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      status: json['status'] ?? 'present',
      markedAt: DateTime.parse(json['markedAt'] ?? DateTime.now().toIso8601String()),
      markedBy: json['markedBy'] ?? 'QR_SCAN',
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      qrSessionId: json['qrSessionId'] ?? '',
    );
  }

  // 🆕 Add the missing toJson method
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmployeeId': studentEmployeeId,
      'lectureId': lectureId,
      'lectureName': lectureName,
      'class': lectureClass,
      'section': section,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'status': status,
      'markedAt': markedAt.toIso8601String(),
      'markedBy': markedBy,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'qrSessionId': qrSessionId,
    };
  }
}
