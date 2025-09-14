import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DebugUserScreen extends StatefulWidget {
  const DebugUserScreen({super.key});

  @override
  State<DebugUserScreen> createState() => _DebugUserScreenState();
}

class _DebugUserScreenState extends State<DebugUserScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.getUserProfile();
    setState(() {
      profileData = result['data'];
      isLoading = false;
    });
    print('=== USER DEBUG INFO ===');
    print('Full Profile: $profileData');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      appBar: AppBar(
        title: const Text('Debug Info', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2332),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR ACCOUNT DATA',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (profileData != null) ...[
                Text('Name: ${profileData!['user']['name']}', style: const TextStyle(color: Colors.white)),
                Text('Email: ${profileData!['user']['email']}', style: const TextStyle(color: Colors.white)),
                Text('Role: ${profileData!['user']['role']}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PROBLEM AREA:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Class: ${profileData!['user']['class'] ?? 'NULL/MISSING'}',
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text('Section: ${profileData!['user']['section'] ?? 'NULL/MISSING'}',
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
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
}
