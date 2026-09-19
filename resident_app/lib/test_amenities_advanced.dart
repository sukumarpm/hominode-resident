// Test script for advanced amenities booking features
// Run this to verify subscription packages, capacity tracking, and calendar blocking

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  print('🧪 Testing Advanced Amenities Booking Features\n');
  
  final firestore = FirebaseFirestore.instance;
  
  // Test 1: Check amenity with packages
  print('📦 Test 1: Checking amenity with subscription packages...');
  try {
    final amenitiesSnapshot = await firestore
        .collection('amenities')
        .where('hasSubscriptionPackages', isEqualTo: true)
        .limit(1)
        .get();
    
    if (amenitiesSnapshot.docs.isNotEmpty) {
      final amenity = amenitiesSnapshot.docs.first;
      final data = amenity.data();
      
      print('✅ Found amenity with packages:');
      print('   Name: ${data['name']}');
      print('   Has packages: ${data['hasSubscriptionPackages']}');
      print('   Packages: ${data['subscriptionPackages']}');
      print('   Allow multiple: ${data['allowMultipleBookings']}');
      print('   Max capacity: ${data['maxCapacity']}');
    } else {
      print('⚠️  No amenities with packages found');
      print('   Create one in Firestore with:');
      print('   - hasSubscriptionPackages: true');
      print('   - subscriptionPackages: {Weekly: 1000, Monthly: 5000, Yearly: 10000}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n${'─' * 60}\n');
  
  // Test 2: Check amenity with multiple bookings
  print('👥 Test 2: Checking amenity with multiple user capacity...');
  try {
    final amenitiesSnapshot = await firestore
        .collection('amenities')
        .where('allowMultipleBookings', isEqualTo: true)
        .limit(1)
        .get();
    
    if (amenitiesSnapshot.docs.isNotEmpty) {
      final amenity = amenitiesSnapshot.docs.first;
      final data = amenity.data();
      
      print('✅ Found amenity with multiple bookings:');
      print('   Name: ${data['name']}');
      print('   Allow multiple: ${data['allowMultipleBookings']}');
      print('   Max capacity: ${data['maxCapacity']}');
      print('   Time slots: ${data['timeSlots']}');
    } else {
      print('⚠️  No amenities with multiple bookings found');
      print('   Create one in Firestore with:');
      print('   - allowMultipleBookings: true');
      print('   - maxCapacity: 10');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n${'─' * 60}\n');
  
  // Test 3: Check bookings for capacity calculation
  print('📊 Test 3: Checking existing bookings for capacity...');
  try {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    final bookingsSnapshot = await firestore
        .collection('amenityBookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['confirmed', 'pending'])
        .get();
    
    print('✅ Found ${bookingsSnapshot.docs.length} bookings for today');
    
    if (bookingsSnapshot.docs.isNotEmpty) {
      // Group by amenity and time slot
      final Map<String, Map<String, int>> bookingsByAmenity = {};
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final amenityId = data['amenityId'] as String;
        final timeSlot = data['timeSlot'] as String;
        
        if (!bookingsByAmenity.containsKey(amenityId)) {
          bookingsByAmenity[amenityId] = {};
        }
        
        bookingsByAmenity[amenityId]![timeSlot] = 
            (bookingsByAmenity[amenityId]![timeSlot] ?? 0) + 1;
      }
      
      print('\n   Bookings by amenity and time slot:');
      for (var amenityId in bookingsByAmenity.keys) {
        print('   Amenity: $amenityId');
        for (var timeSlot in bookingsByAmenity[amenityId]!.keys) {
          final count = bookingsByAmenity[amenityId]![timeSlot];
          print('     $timeSlot: $count bookings');
        }
      }
    } else {
      print('   No bookings found for today');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n${'─' * 60}\n');
  
  // Test 4: Sample amenity data structure
  print('📝 Test 4: Sample amenity data structure for testing...');
  print('''
Create this amenity in Firestore for complete testing:

Collection: amenities
Document: (auto-generated ID)

{
  "name": "Gym",
  "type": "Sports",
  "buildingId": "YOUR_BUILDING_ID",
  "organizationId": "YOUR_ORG_ID",
  "adminId": "YOUR_ADMIN_ID",
  
  // Pricing
  "isFree": false,
  "pricePerDay": 50,
  "hasSubscriptionPackages": true,
  "subscriptionPackages": {
    "Weekly": 1000,
    "Monthly": 5000,
    "Yearly": 10000
  },
  
  // Capacity
  "allowMultipleBookings": true,
  "maxCapacity": 10,
  
  // Time Management
  "timeSlots": [
    "6:00 AM - 7:00 AM",
    "7:00 AM - 8:00 AM",
    "8:00 AM - 9:00 AM",
    "9:00 AM - 10:00 AM",
    "5:00 PM - 6:00 PM",
    "6:00 PM - 7:00 PM",
    "7:00 PM - 8:00 PM"
  ],
  "bookingDurations": ["1 hour"],
  
  // Availability
  "isAvailable": true,
  "iconName": "gym",
  "imageUrl": null,
  "description": null
}
''');
  
  print('\n${'─' * 60}\n');
  print('✅ Test complete! Check the output above for any issues.\n');
}
