// Test script to verify capacity calculation
// Run: flutter run -t lib/test_capacity_calculation.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'src/services/booking_firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CapacityTestApp());
}

class CapacityTestApp extends StatelessWidget {
  const CapacityTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capacity Test',
      home: const CapacityTestScreen(),
    );
  }
}

class CapacityTestScreen extends StatefulWidget {
  const CapacityTestScreen({super.key});

  @override
  State<CapacityTestScreen> createState() => _CapacityTestScreenState();
}

class _CapacityTestScreenState extends State<CapacityTestScreen> {
  final _bookingService = BookingFirestoreService();
  bool _isLoading = false;
  String _result = '';

  Future<void> _testCapacityCalculation() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing capacity calculation...\n\n';
    });

    try {
      // Test with swimming pool amenity
      const amenityId = 'your_amenity_id'; // Replace with actual amenity ID
      final testDate = DateTime(2026, 2, 26);
      const testTimeSlot = '6:00 AM - 7:00 AM';

      _addResult('🔍 Testing amenity: $amenityId');
      _addResult('📅 Date: ${testDate.toString().split(' ')[0]}');
      _addResult('⏰ Time slot: $testTimeSlot');
      _addResult('');

      // Get amenity details
      _addResult('📥 Fetching amenity details...');
      final amenity = await _bookingService.getAmenityDetails(amenityId);
      
      if (amenity == null) {
        _addResult('❌ Amenity not found!');
        return;
      }

      _addResult('✅ Amenity: ${amenity.name}');
      _addResult('   Max capacity: ${amenity.maxCapacity}');
      _addResult('   Allow multiple: ${amenity.allowMultipleBookings}');
      _addResult('');

      // Check availability for 1 person
      _addResult('🔍 Checking availability for 1 person...');
      var availability = await _bookingService.checkSlotAvailability(
        amenityId: amenityId,
        date: testDate,
        timeSlot: testTimeSlot,
        numberOfPeople: 1,
      );
      
      _addResult('Result:');
      _addResult('  Available: ${availability['available']}');
      _addResult('  Remaining spots: ${availability['remainingSpots']}');
      _addResult('  Total capacity: ${availability['totalCapacity']}');
      _addResult('  Total people booked: ${availability['totalPeople']}');
      _addResult('  Booking count: ${availability['bookingCount']}');
      _addResult('');

      // Check availability for 2 people
      _addResult('🔍 Checking availability for 2 people...');
      availability = await _bookingService.checkSlotAvailability(
        amenityId: amenityId,
        date: testDate,
        timeSlot: testTimeSlot,
        numberOfPeople: 2,
      );
      
      _addResult('Result:');
      _addResult('  Available: ${availability['available']}');
      _addResult('  Remaining spots: ${availability['remainingSpots']}');
      _addResult('  Total capacity: ${availability['totalCapacity']}');
      _addResult('  Total people booked: ${availability['totalPeople']}');
      _addResult('');

      // Query all bookings for this slot
      _addResult('📊 Querying all bookings for this slot...');
      final startOfDay = DateTime(testDate.year, testDate.month, testDate.day);
      final endOfDay = DateTime(testDate.year, testDate.month, testDate.day, 23, 59, 59);
      
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('amenityBookings')
          .where('amenityId', isEqualTo: amenityId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      _addResult('Total bookings for date: ${bookingsSnapshot.docs.length}');
      
      // Filter for specific time slot
      final matchingBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['timeSlot'] == testTimeSlot && 
               (data['status'] == 'confirmed' || data['status'] == 'pending');
      }).toList();

      _addResult('Bookings for time slot: ${matchingBookings.length}');
      _addResult('');

      // Show each booking
      int totalPeople = 0;
      for (var doc in matchingBookings) {
        final data = doc.data();
        final people = data['numberOfPeople'] as int? ?? 1;
        totalPeople += people;
        
        _addResult('Booking ${doc.id}:');
        _addResult('  User: ${data['userName']}');
        _addResult('  People: $people');
        _addResult('  Status: ${data['status']}');
        _addResult('  Booking type: ${data['bookingType'] ?? 'daily'}');
        _addResult('');
      }

      _addResult('📊 SUMMARY:');
      _addResult('  Total people booked: $totalPeople');
      _addResult('  Max capacity: ${amenity.maxCapacity}');
      _addResult('  Remaining spots: ${amenity.maxCapacity - totalPeople}');
      _addResult('');
      _addResult('✅ Test complete!');

    } catch (e, stackTrace) {
      _addResult('❌ Error: $e');
      _addResult('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addResult(String text) {
    setState(() {
      _result += '$text\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capacity Calculation Test'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testCapacityCalculation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Run Capacity Test'),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _result.isEmpty ? 'Press button to run test' : _result,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
