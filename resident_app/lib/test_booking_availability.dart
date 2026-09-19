// Test script to diagnose booking availability issues
// Run this to check if availability checking is working properly

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  print('🧪 Testing Booking Availability System\n');
  print('=' * 60);
  
  final firestore = FirebaseFirestore.instance;
  
  // Test 1: Check amenities exist
  print('\n📦 Test 1: Checking amenities...');
  try {
    final amenitiesSnapshot = await firestore
        .collection('amenities')
        .where('isAvailable', isEqualTo: true)
        .limit(3)
        .get();
    
    print('✅ Found ${amenitiesSnapshot.docs.length} available amenities');
    
    for (var doc in amenitiesSnapshot.docs) {
      final data = doc.data();
      print('\n   Amenity: ${data['name']}');
      print('   ID: ${doc.id}');
      print('   Allow multiple: ${data['allowMultipleBookings']}');
      print('   Max capacity: ${data['maxCapacity']}');
      print('   Time slots: ${data['timeSlots']}');
    }
    
    if (amenitiesSnapshot.docs.isEmpty) {
      print('⚠️  No amenities found! Create one first.');
      return;
    }
  } catch (e) {
    print('❌ Error: $e');
    return;
  }
  
  print('\n${'─' * 60}');
  
  // Test 2: Check existing bookings
  print('\n📊 Test 2: Checking existing bookings...');
  try {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final bookingsSnapshot = await firestore
        .collection('amenityBookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
    
    print('✅ Found ${bookingsSnapshot.docs.length} bookings for today');
    
    if (bookingsSnapshot.docs.isNotEmpty) {
      print('\n   Bookings:');
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        print('   - Amenity: ${data['amenityName']}');
        print('     Time slot: ${data['timeSlot']}');
        print('     Status: ${data['status']}');
        print('     User: ${data['userName']}');
      }
    } else {
      print('   No bookings for today - all slots should be available');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n${'─' * 60}');
  
  // Test 3: Simulate availability check
  print('\n🔍 Test 3: Simulating availability check...');
  try {
    final amenitiesSnapshot = await firestore
        .collection('amenities')
        .where('isAvailable', isEqualTo: true)
        .limit(1)
        .get();
    
    if (amenitiesSnapshot.docs.isEmpty) {
      print('⚠️  No amenities to test');
      return;
    }
    
    final amenityDoc = amenitiesSnapshot.docs.first;
    final amenityData = amenityDoc.data();
    final amenityId = amenityDoc.id;
    final amenityName = amenityData['name'];
    final timeSlots = List<String>.from(amenityData['timeSlots'] ?? []);
    final allowMultiple = amenityData['allowMultipleBookings'] ?? false;
    final maxCapacity = amenityData['maxCapacity'] ?? 1;
    
    print('Testing amenity: $amenityName');
    print('Amenity ID: $amenityId');
    print('Allow multiple: $allowMultiple');
    print('Max capacity: $maxCapacity');
    
    if (timeSlots.isEmpty) {
      print('⚠️  No time slots defined');
      return;
    }
    
    final testDate = DateTime.now();
    final startOfDay = DateTime(testDate.year, testDate.month, testDate.day);
    final endOfDay = DateTime(testDate.year, testDate.month, testDate.day, 23, 59, 59);
    
    print('\nChecking availability for ${testDate.toString().split(' ')[0]}:');
    
    // Query bookings for this amenity and date
    final bookingsSnapshot = await firestore
        .collection('amenityBookings')
        .where('amenityId', isEqualTo: amenityId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
    
    print('Found ${bookingsSnapshot.docs.length} total bookings for this date');
    
    // Check each time slot
    for (var timeSlot in timeSlots.take(5)) {  // Check first 5 slots
      // Filter bookings for this time slot
      final slotBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        final docTimeSlot = data['timeSlot'] as String?;
        final docStatus = data['status'] as String?;
        return docTimeSlot == timeSlot && 
               (docStatus == 'confirmed' || docStatus == 'pending');
      }).toList();
      
      final bookingCount = slotBookings.length;
      
      if (allowMultiple) {
        final remainingSpots = maxCapacity - bookingCount;
        final available = remainingSpots > 0;
        print('   $timeSlot: ${available ? "✅ Available" : "❌ Full"} ($remainingSpots/$maxCapacity spots)');
      } else {
        final available = bookingCount == 0;
        print('   $timeSlot: ${available ? "✅ Available" : "❌ Booked"}');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('\n${'─' * 60}');
  
  // Test 4: Check Firestore indexes
  print('\n📋 Test 4: Checking if Firestore indexes are needed...');
  print('''
If you see index errors, you need to create these indexes in Firestore:

Collection: bookings
Fields to index:
  1. amenityId (Ascending) + date (Ascending)
  2. userId (Ascending) + date (Descending)

To create indexes:
1. Go to Firebase Console → Firestore → Indexes
2. Click "Create Index"
3. Add the fields above
4. Wait for index to build (can take a few minutes)

Or click the link in the error message to auto-create the index.
''');
  
  print('\n${'=' * 60}');
  print('✅ Test complete!\n');
  print('Summary:');
  print('- If time slots show as "Full" but no bookings exist, check:');
  print('  1. Firestore indexes are created');
  print('  2. amenityId matches exactly');
  print('  3. Date range query is working');
  print('  4. Console logs show correct booking counts');
  print('\n- If availability is not loading:');
  print('  1. Check console for error messages');
  print('  2. Verify Firestore rules allow read access');
  print('  3. Ensure amenity has timeSlots array');
}
