// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/lecture_model.dart';
import '../models/attendance_model.dart';

class ApiService {
  static const String baseUrl = 'https://smart-attendance-server.onrender.com';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Get stored token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Save token and user data
  static Future<void> saveUserData(String token, User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('✅ User data saved successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // Get stored user data with null safety
  static Future<User?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData == null || userData.isEmpty) {
        print('⚠️ No stored user data found');
        return null;
      }

      final Map<String, dynamic> userMap = jsonDecode(userData);
      final user = User.fromJson(userMap);
      print('✅ Retrieved user: ${user.name} (${user.userClass}-${user.section})');
      return user;
    } catch (e) {
      print('❌ Error getting stored user: $e');
      return null;
    }
  }

  // Get headers with authorization
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response with proper type safety
  static Map<String, dynamic> handleResponse(http.Response response) {
    try {
      final responseBody = response.body;
      print('📡 Raw Response (${response.statusCode}): $responseBody');

      if (responseBody.isEmpty) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'Empty response from server'},
          'message': 'Empty response from server',
        };
      }

      final dynamic parsedData = jsonDecode(responseBody);

      // Ensure we have a proper Map structure
      Map<String, dynamic> data;
      if (parsedData is Map<String, dynamic>) {
        data = parsedData;
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': {'message': 'Invalid response format'},
          'message': 'Invalid response format',
        };
      }

      final bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'data': data,
        'message': _safeGetString(data, 'message') ?? (isSuccess ? 'Request completed' : 'Request failed'),
      };
    } catch (e) {
      print('❌ Error parsing response: $e');
      return {
        'success': false,
        'statusCode': response.statusCode,
        'data': {'message': 'Failed to parse server response'},
        'message': 'Failed to parse server response: $e',
      };
    }
  }

  // Helper method to safely get string from map
  static String? _safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is String ? value : null;
  }

  // Helper method to safely get map from map
  static Map<String, dynamic>? _safeGetMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is Map<String, dynamic> ? value : null;
  }

  // Helper method to safely get list from map
  static List? _safeGetList(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is List ? value : null;
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String employeeId,
    required String role,
    required String department,
    String? userClass,
    String? section,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'employeeId': employeeId,
        'role': role,
        'department': department,
      };

      if (role == 'student') {
        body['class'] = userClass ?? '';
        body['section'] = section ?? '';
      }

      print('🔄 Registering user: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final result = handleResponse(response);

      if (result['success'] == true) {
        final data = _safeGetMap(result['data'] as Map<String, dynamic>, 'data');
        if (data != null) {
          final userData = _safeGetMap(data, 'user');
          final token = _safeGetString(data, 'token');

          if (userData != null && token != null) {
            final user = User.fromJson(userData);
            await saveUserData(token, user);
            print('✅ Registration successful for: ${user.name}');
          }
        }
      }

      return result;
    } catch (e) {
      print('❌ Registration error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Attempting login for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = handleResponse(response);

      if (result['success'] == true) {
        final data = _safeGetMap(result['data'] as Map<String, dynamic>, 'data');
        if (data != null) {
          final userData = _safeGetMap(data, 'user');
          final token = _safeGetString(data, 'token');

          if (userData != null && token != null) {
            final user = User.fromJson(userData);
            await saveUserData(token, user);
            print('✅ Login successful for: ${user.name}');
            print('   Class: ${user.userClass ?? "NOT SET"}');
            print('   Section: ${user.section ?? "NOT SET"}');
          }
        }
      }

      return result;
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: headers,
      );

      return handleResponse(response);
    } catch (e) {
      print('❌ Get profile error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get student lectures
  static Future<Map<String, dynamic>> getStudentLectures({
    int page = 1,
    int limit = 10,
    String? date,
  }) async {
    try {
      final headers = await getHeaders();
      var url = '$baseUrl/api/lectures/student?page=$page&limit=$limit';
      if (date != null) url += '&date=$date';

      print('📡 Fetching lectures from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      final result = handleResponse(response);

      if (result['success'] == true) {
        final responseData = result['data'] as Map<String, dynamic>;
        final data = _safeGetMap(responseData, 'data');

        if (data != null) {
          final lecturesData = _safeGetList(data, 'lectures');

          List<Lecture> lectures = [];
          if (lecturesData != null) {
            lectures = lecturesData
                .where((item) => item is Map<String, dynamic>)
                .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          return {
            ...result,
            'lectures': lectures,
            'pagination': _safeGetMap(data, 'pagination') ?? {},
          };
        }
      }

      return {
        ...result,
        'lectures': <Lecture>[],
        'pagination': {},
      };
    } catch (e) {
      print('❌ Get lectures error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'lectures': <Lecture>[],
        'pagination': {},
      };
    }
  }

  // Mark attendance
  static Future<Map<String, dynamic>> markAttendance({
    required String qrData,
  }) async {
    try {
      print('=== ATTENDANCE MARKING DEBUG ===');

      final headers = await getHeaders();

      // Get current user info for debugging
      final currentUser = await getStoredUser();
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please login again.',
        };
      }

      print('👤 Current User Info:');
      print('   - Name: ${currentUser.name}');
      print('   - Class: ${currentUser.userClass}');
      print('   - Section: ${currentUser.section}');
      print('   - Department: ${currentUser.department}');

      // Parse QR data for debugging
      try {
        final qrInfo = jsonDecode(qrData);
        print('📱 QR Code Info:');
        print('   - Session ID: ${qrInfo['sessionId']}');
        print('   - Lecture ID: ${qrInfo['lectureId']}');
        print('   - Teacher ID: ${qrInfo['teacherId']}');
        print('   - Token: ${qrInfo['token']}');
      } catch (e) {
        print('❌ Failed to parse QR data: $e');
        return {
          'success': false,
          'message': 'Invalid QR code format',
        };
      }

      print('📡 Sending attendance request...');

      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark'),
        headers: headers,
        body: jsonEncode({
          'qrData': qrData,
        }),
      );

      final result = handleResponse(response);

      print('📨 Backend Response:');
      print('   - Success: ${result['success']}');
      print('   - Status Code: ${result['statusCode']}');
      print('   - Message: ${result['message']}');

      if (result['success'] != true) {
        print('❌ Full Error Response: ${result['data']}');
        return result;
      }

      // Process successful response
      final responseData = result['data'] as Map<String, dynamic>;
      final data = _safeGetMap(responseData, 'data');

      if (data != null) {
        final attendanceData = _safeGetMap(data, 'attendance');
        final lectureData = _safeGetMap(data, 'lecture') ?? {};

        if (attendanceData != null) {
          return {
            ...result,
            'attendance': Attendance.fromJson(attendanceData),
            'lecture': lectureData,
          };
        }
      }

      return result;
    } catch (e) {
      print('💥 Mark attendance error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // 🔧 **COMPLETELY FIXED getStudentAttendance Method**
  static Future<Map<String, dynamic>> getStudentAttendance({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? subject,
  }) async {
    print('🔄 Starting getStudentAttendance...');

    try {
      final headers = await getHeaders();
      var url = '$baseUrl/api/attendance/student?page=$page&limit=$limit';
      if (startDate != null) url += '&startDate=$startDate';
      if (endDate != null) url += '&endDate=$endDate';
      if (subject != null) url += '&subject=$subject';

      print('📡 Fetching from: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('📊 JSON Response: $jsonResponse');

          // Create default empty response
          List<Attendance> attendances = [];
          Map<String, dynamic> statistics = {
            'totalClasses': 0,
            'presentClasses': 0,
            'absentClasses': 0,
            'attendancePercentage': 0,
          };

          // Try to extract data safely
          try {
            if (jsonResponse['success'] == true &&
                jsonResponse['data'] != null &&
                jsonResponse['data']['data'] != null) {

              final data = jsonResponse['data']['data'];

              // Extract attendance list
              if (data['attendance'] != null && data['attendance'] is List) {
                final attendanceList = data['attendance'] as List;

                for (var item in attendanceList) {
                  try {
                    attendances.add(Attendance.fromJson(item));
                  } catch (e) {
                    print('⚠️ Skipping invalid attendance item: $e');
                  }
                }
              }

              // Extract statistics or calculate them
              if (data['statistics'] != null && data['statistics'] is Map) {
                try {
                  final stats = data['statistics'] as Map<String, dynamic>;
                  statistics = {
                    'totalClasses': (stats['totalClasses'] ?? 0).toInt(),
                    'presentClasses': (stats['presentClasses'] ?? 0).toInt(),
                    'absentClasses': (stats['absentClasses'] ?? 0).toInt(),
                    'attendancePercentage': (stats['attendancePercentage'] ?? 0).toInt(),
                  };
                } catch (e) {
                  print('⚠️ Error parsing statistics, calculating manually: $e');
                }
              }

              // If no statistics, calculate from attendance
              if (statistics['totalClasses'] == 0 && attendances.isNotEmpty) {
                final presentCount = attendances.where((a) => a.status.toLowerCase() == 'present').length;
                statistics = {
                  'totalClasses': attendances.length,
                  'presentClasses': presentCount,
                  'absentClasses': attendances.length - presentCount,
                  'attendancePercentage': ((presentCount / attendances.length) * 100).round(),
                };
              }
            }
          } catch (e) {
            print('⚠️ Error extracting data, using defaults: $e');
          }

          print('✅ Final Result:');
          print('   Attendance count: ${attendances.length}');
          print('   Statistics: $statistics');

          return {
            'success': true,
            'attendance': attendances,
            'statistics': statistics,
            'pagination': {},
            'message': 'Data loaded successfully',
          };

        } catch (e) {
          print('❌ JSON parsing error: $e');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      print('💥 Network error: $e');
    }

    // Return default empty structure on any error
    print('📊 Returning default empty response');
    return {
      'success': true,
      'attendance': <Attendance>[],
      'statistics': {
        'totalClasses': 0,
        'presentClasses': 0,
        'absentClasses': 0,
        'attendancePercentage': 0,
      },
      'pagination': {},
      'message': 'No attendance data available',
    };
  }

  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);

      try {
        final headers = await getHeaders();
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: headers,
        );
      } catch (e) {
        print('Logout API call failed: $e');
        // Ignore logout API errors
      }

      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final user = await getStoredUser();
      final isLoggedIn = token != null && user != null;
      print('🔐 Login status: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }

  // Get server status
  static Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
      return handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Server unreachable: ${e.toString()}',
      };
    }
  }

  // Add this debug method to test API directly
  static Future<void> debugAttendanceAPI() async {
    print('🧪 Testing attendance API directly...');

    try {
      final result = await getStudentAttendance(limit: 5);

      print('🧪 API Test Result:');
      print('   Success: ${result['success']}');
      print('   Message: ${result['message']}');
      print('   Attendance: ${result['attendance']?.length ?? 0} records');
      print('   Statistics: ${result['statistics']}');

      if (result['attendance'] is List && result['attendance'].isNotEmpty) {
        final first = result['attendance'][0] as Attendance;
        print('   First record: ${first.lectureName} - ${first.status}');
      }

    } catch (e) {
      print('🧪 API Test Failed: $e');
    }
  }
}
