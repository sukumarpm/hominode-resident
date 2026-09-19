// Test Marketplace Authentication Fix
// Run: flutter run -t lib/test_marketplace_auth.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/services/listing_firestore_service.dart';
import 'src/services/firestore_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MarketplaceAuthTestApp());
}

class MarketplaceAuthTestApp extends StatelessWidget {
  const MarketplaceAuthTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Auth Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MarketplaceAuthTestScreen(),
    );
  }
}

class MarketplaceAuthTestScreen extends StatefulWidget {
  const MarketplaceAuthTestScreen({super.key});

  @override
  State<MarketplaceAuthTestScreen> createState() => _MarketplaceAuthTestScreenState();
}

class _MarketplaceAuthTestScreenState extends State<MarketplaceAuthTestScreen> {
  final _listingService = ListingFirestoreService();
  final _authService = FirestoreAuthService();
  final _firebaseAuth = FirebaseAuth.instance;
  
  String _status = 'Ready to test';
  bool _isLoading = false;
  final List<String> _logs = [];

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
      print(log);
    });
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _status = 'Testing authentication...';
    });

    try {
      _addLog('🔍 Starting authentication test...');
      _addLog('');

      // Check Firebase Auth
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        _addLog('✅ Firebase Auth User Found:');
        _addLog('   UID: ${firebaseUser.uid}');
        _addLog('   Email: ${firebaseUser.email ?? "N/A"}');
        _addLog('   Phone: ${firebaseUser.phoneNumber ?? "N/A"}');
      } else {
        _addLog('❌ No Firebase Auth user');
      }
      _addLog('');

      // Check Firestore Auth
      final firestoreUserId = await _authService.getCurrentUserId();
      if (firestoreUserId != null) {
        _addLog('✅ Firestore Auth User Found:');
        _addLog('   User ID: $firestoreUserId');
      } else {
        _addLog('❌ No Firestore Auth user');
      }
      _addLog('');

      // Test listing service authentication
      _addLog('🔍 Testing ListingFirestoreService...');
      final listings = await _listingService.getAllListings();
      
      _addLog('');
      _addLog('✅ Authentication successful!');
      _addLog('   Fetched ${listings.length} listings');
      
      if (listings.isEmpty) {
        _addLog('');
        _addLog('ℹ️  No listings found (this is normal if none exist)');
      } else {
        _addLog('');
        _addLog('📋 Listings:');
        for (var listing in listings) {
          _addLog('   - ${listing.title} (₹${listing.price})');
        }
      }

      setState(() {
        _status = 'Test completed successfully! ✅';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('');
      _addLog('❌ Error: $e');
      setState(() {
        _status = 'Test failed ❌';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateListing() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _status = 'Testing listing creation...';
    });

    try {
      _addLog('🔍 Testing listing creation...');
      _addLog('');

      final result = await _listingService.createListing(
        title: 'Test Item ${DateTime.now().millisecondsSinceEpoch}',
        price: 1000,
        category: 'Other',
        condition: 'Good',
        description: 'This is a test listing created by the auth test',
        images: [],
      );

      _addLog('');
      if (result.success) {
        _addLog('✅ Listing created successfully!');
        _addLog('   Listing ID: ${result.data}');
        _addLog('   Message: ${result.message}');
      } else {
        _addLog('❌ Failed to create listing');
        _addLog('   Error: ${result.message}');
      }

      setState(() {
        _status = result.success ? 'Listing created! ✅' : 'Creation failed ❌';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('');
      _addLog('❌ Error: $e');
      setState(() {
        _status = 'Test failed ❌';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Auth Test'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF7F7F7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testAuthentication,
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Test Authentication'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCreateListing,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Test Create Listing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1F2937),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Run a test to see results.',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Running test...',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
