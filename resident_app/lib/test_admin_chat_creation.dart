// Test admin chat creation
// Run: flutter run -d ZA222LQT6V lib/test_admin_chat_creation.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'src/services/admin_chat_service.dart';
import 'src/models/admin_chat_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TestAdminChatApp());
}

class TestAdminChatApp extends StatelessWidget {
  const TestAdminChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Admin Chat',
      home: const TestAdminChatScreen(),
    );
  }
}

class TestAdminChatScreen extends StatefulWidget {
  const TestAdminChatScreen({super.key});

  @override
  State<TestAdminChatScreen> createState() => _TestAdminChatScreenState();
}

class _TestAdminChatScreenState extends State<TestAdminChatScreen> {
  final AdminChatService _adminChatService = AdminChatService.instance;
  final List<String> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addLog('🚀 Test Admin Chat Creation Started');
    _addLog('Current User: ${FirebaseAuth.instance.currentUser?.uid ?? "Not logged in"}');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  Future<void> _testCreateAdminChat() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('\n═══════════════════════════════════════════════════');
    _addLog('TEST: Create Admin Chat');
    _addLog('═══════════════════════════════════════════════════\n');

    try {
      _addLog('📋 Step 1: Check if user is logged in');
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        _addLog('❌ No user logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _addLog('✅ User logged in: ${currentUser.uid}');
      _addLog('   Email: ${currentUser.email}');

      _addLog('\n📋 Step 2: Call getOrCreateAdminChat()');
      final chat = await _adminChatService.getOrCreateAdminChat(
        category: QueryCategory.other,
        initialMessage: 'Test message from diagnostic',
      );

      if (chat == null) {
        _addLog('\n❌ FAILED: getOrCreateAdminChat returned null');
        _addLog('   This means an error occurred in the service');
        _addLog('   Check the console logs above for details');
      } else {
        _addLog('\n✅ SUCCESS: Admin chat created/retrieved');
        _addLog('   Chat ID: ${chat.id}');
        _addLog('   Building ID: ${chat.buildingId}');
        _addLog('   Admin ID: ${chat.adminId}');
        _addLog('   Admin Name: ${chat.adminName}');
        _addLog('   Resident ID: ${chat.residentId}');
        _addLog('   Resident Name: ${chat.residentName}');
        _addLog('   Category: ${chat.category.displayName}');
        _addLog('   Status: ${chat.status}');
      }

      _addLog('\n═══════════════════════════════════════════════════\n');
    } catch (e, stackTrace) {
      _addLog('\n❌ EXCEPTION: $e');
      _addLog('Stack trace: $stackTrace');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Admin Chat Creation'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testCreateAdminChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Test Create Admin Chat',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.white;
                  
                  if (log.contains('✅') || log.contains('SUCCESS')) {
                    textColor = Colors.green;
                  } else if (log.contains('❌') || log.contains('FAILED') || log.contains('ERROR')) {
                    textColor = Colors.red;
                  } else if (log.contains('⚠️') || log.contains('WARNING')) {
                    textColor = Colors.orange;
                  } else if (log.contains('📋') || log.contains('Step')) {
                    textColor = Colors.cyan;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
