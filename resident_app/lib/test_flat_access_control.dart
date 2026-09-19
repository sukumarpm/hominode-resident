// lib/test_flat_access_control.dart
// Test script for flat access control implementation

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/flat_access_control_service.dart';
import 'src/services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const FlatAccessControlTestApp());
}

class FlatAccessControlTestApp extends StatelessWidget {
  const FlatAccessControlTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flat Access Control Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FlatAccessControlTestScreen(),
    );
  }
}

class FlatAccessControlTestScreen extends StatefulWidget {
  const FlatAccessControlTestScreen({super.key});

  @override
  State<FlatAccessControlTestScreen> createState() => _FlatAccessControlTestScreenState();
}

class _FlatAccessControlTestScreenState extends State<FlatAccessControlTestScreen> {
  final FlatAccessControlService _accessService = FlatAccessControlService.instance;
  final UserDataService _userDataService = UserDataService.instance;
  
  bool _isLoading = false;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _log(String message) {
    setState(() {
      _output += '$message\n';
    });
    print(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    _log('🧪 FLAT ACCESS CONTROL TEST');
    _log('=' * 50);
    _log('');

    // Test 1: Get current user data
    _log('📋 Test 1: Get Current User Data');
    _log('-' * 50);
    try {
      final userData = await _userDataService.getCurrentUserData();
      
      if (userData == null) {
        _log('❌ No user logged in');
        _log('   Please log in first');
      } else {
        _log('✅ User data fetched');
        _log('   Name: ${userData['name']}');
        _log('   Email: ${userData['email']}');
        _log('   Phone: ${userData['phone']}');
        _log('   Flat ID: ${userData['flatId'] ?? 'NOT ASSIGNED'}');
        _log('   Building ID: ${userData['buildingId'] ?? 'NOT ASSIGNED'}');
        _log('   Role: ${userData['role']}');
      }
    } catch (e) {
      _log('❌ Error: $e');
    }
    _log('');

    // Test 2: Check flat access (one-time)
    _log('📋 Test 2: Check Flat Access (One-Time)');
    _log('-' * 50);
    try {
      final accessResult = await _accessService.checkFlatAccess();
      
      if (accessResult.hasAccess) {
        _log('✅ ACCESS GRANTED');
        _log('   Flat ID: ${accessResult.flatId}');
        _log('   Building ID: ${accessResult.buildingId}');
        _log('   User can access app features');
      } else {
        _log('❌ ACCESS DENIED');
        _log('   Message: ${accessResult.message}');
        _log('   User cannot access app features');
      }
    } catch (e) {
      _log('❌ Error: $e');
    }
    _log('');

    // Test 3: Check cached access
    _log('📋 Test 3: Check Cached Access');
    _log('-' * 50);
    try {
      final hasAccess = _accessService.hasAccessCached();
      final flatId = _accessService.getCachedFlatId();
      final buildingId = _accessService.getCachedBuildingId();
      
      _log('   Has Access (Cached): $hasAccess');
      _log('   Flat ID (Cached): ${flatId ?? 'null'}');
      _log('   Building ID (Cached): ${buildingId ?? 'null'}');
    } catch (e) {
      _log('❌ Error: $e');
    }
    _log('');

    // Test 4: Stream flat access (real-time)
    _log('📋 Test 4: Stream Flat Access (Real-Time)');
    _log('-' * 50);
    _log('   Listening for real-time updates...');
    _log('   (Check console for stream updates)');
    _log('');

    // Test 5: Summary
    _log('📋 Test Summary');
    _log('=' * 50);
    _log('✅ All tests completed');
    _log('');
    _log('📝 Notes:');
    _log('   - If flatId is null/empty, access is denied');
    _log('   - If flatId is present, access is granted');
    _log('   - Real-time stream monitors user document changes');
    _log('   - Cache improves performance');
    _log('');
    _log('🔄 To test real-time updates:');
    _log('   1. Keep this screen open');
    _log('   2. Update user flatId in Firestore');
    _log('   3. Watch the stream section below');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat Access Control Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
            tooltip: 'Rerun Tests',
          ),
        ],
      ),
      body: Column(
        children: [
          // Test output
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ),
          
          // Real-time stream section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stream, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Real-Time Access Stream',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<AccessControlResult>(
                  stream: _accessService.streamFlatAccess(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Connecting to stream...'),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      );
                    }

                    final accessResult = snapshot.data;

                    if (accessResult == null) {
                      return const Text('No data');
                    }

                    if (accessResult.hasAccess) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'ACCESS GRANTED',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Flat ID: ${accessResult.flatId}'),
                          Text('Building ID: ${accessResult.buildingId}'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'User can access all app features',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.block, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'ACCESS DENIED',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Message: ${accessResult.message}'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_outlined, size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'User cannot access app features',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
