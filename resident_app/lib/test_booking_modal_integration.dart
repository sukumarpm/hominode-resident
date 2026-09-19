// lib/test_booking_modal_integration.dart
// Test: Booking Modal Integration with Flow Function
// Verifies that the booking modal correctly displays capacity and uses flow function results

import 'package:flutter/material.dart';
import 'src/models/amenity.dart';
import 'src/services/booking_firestore_service.dart';
import 'src/services/amenities_booking_flow_function.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 TEST: Booking Modal Integration');
  print('=' * 60);
  
  await testBookingModalCapacityDisplay();
  await testFlowFunctionIntegration();
  await testSlotAvailabilityCalculation();
  
  print('=' * 60);
  print('✅ All tests completed');
}

Future<void> testBookingModalCapacityDisplay() async {
  print('\n📋 TEST 1: Booking Modal Capacity Display');
  print('-' * 60);
  
  try {
    // Create test amenity with capacity 5
    final testAmenity = Amenity(
      id: 'test-amenity-1',
      name: 'Test Gym',
      type: 'Gym',
      price: '₹500',
      openTime: '6:00 AM',
      closeTime: '10:00 PM',
      imageUrl: null,
      isFree: false,
    );
    
    print('✅ Created test amenity:');
    print('   ID: ${testAmenity.id}');
    print('   Name: ${testAmenity.name}');
    print('   Price: ${testAmenity.price}');
    
    // Verify amenity details can be fetched
    final bookingService = BookingFirestoreService();
    final amenityDetails = await bookingService.getAmenityDetails(testAmenity.id);
    
    if (amenityDetails != null) {
      print('✅ Amenity details fetched:');
      print('   Max capacity: ${amenityDetails.maxCapacity}');
      print('   Time slots: ${amenityDetails.timeSlots.length}');
      print('   Allow multiple: ${amenityDetails.allowMultipleBookings}');
      
      // CRITICAL: Verify capacity is 5, not 8
      if (amenityDetails.maxCapacity == 5) {
        print('✅ PASS: Capacity is correct (5)');
      } else {
        print('❌ FAIL: Capacity is ${amenityDetails.maxCapacity}, expected 5');
      }
    } else {
      print('⚠️  Amenity details not found (may not exist in Firestore)');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> testFlowFunctionIntegration() async {
  print('\n📋 TEST 2: Flow Function Integration');
  print('-' * 60);
  
  try {
    final flowFunction = AmenitiesBookingFlowFunction.instance;
    
    // Test with sample data
    final selectedDate = DateTime.now();
    final timeSlots = [
      '6:00 AM - 7:00 AM',
      '7:00 AM - 8:00 AM',
      '8:00 AM - 9:00 AM',
      '9:00 AM - 10:00 AM',
    ];
    
    print('✅ Testing flow function with:');
    print('   Date: ${selectedDate.toString().split(' ')[0]}');
    print('   Time slots: ${timeSlots.length}');
    print('   Capacity: 5');
    print('   Number of people: 1');
    
    // Call flow function
    final result = await flowFunction.getAvailableSlots(
      amenityId: 'test-amenity-1',
      selectedDate: selectedDate,
      allTimeSlots: timeSlots,
      capacity: 5,
      numberOfPeople: 1,
    );
    
    if (result.success) {
      print('✅ Flow function returned successfully');
      print('   Available slots: ${result.availableSlots?.length ?? 0}');
      print('   Slot details keys: ${result.slotDetails?.keys.toList()}');
      
      // Verify slot details contain totalPersonsBooked
      if (result.slotDetails != null) {
        for (var slot in timeSlots) {
          final detail = result.slotDetails![slot];
          if (detail != null) {
            final totalPersonsBooked = detail['totalPersonsBooked'];
            print('   📊 Slot "$slot": totalPersonsBooked=$totalPersonsBooked');
            
            if (totalPersonsBooked != null) {
              print('   ✅ PASS: totalPersonsBooked is present');
            } else {
              print('   ❌ FAIL: totalPersonsBooked is missing');
            }
          }
        }
      }
    } else {
      print('❌ Flow function failed: ${result.message}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> testSlotAvailabilityCalculation() async {
  print('\n📋 TEST 3: Slot Availability Calculation');
  print('-' * 60);
  
  try {
    final bookingService = BookingFirestoreService();
    
    // Test slot availability check
    final selectedDate = DateTime.now();
    final timeSlot = '9:00 AM - 10:00 AM';
    
    print('✅ Testing slot availability check:');
    print('   Date: ${selectedDate.toString().split(' ')[0]}');
    print('   Time slot: $timeSlot');
    print('   Number of people: 1');
    
    final availability = await bookingService.checkSlotAvailability(
      amenityId: 'test-amenity-1',
      date: selectedDate,
      timeSlot: timeSlot,
      numberOfPeople: 1,
    );
    
    print('✅ Availability check result:');
    print('   Available: ${availability['available']}');
    print('   Remaining spots: ${availability['remainingSpots']}');
    print('   Total capacity: ${availability['totalCapacity']}');
    print('   Total people: ${availability['totalPeople']}');
    print('   Booking count: ${availability['bookingCount']}');
    
    // Verify capacity is 5
    if (availability['totalCapacity'] == 5) {
      print('✅ PASS: Total capacity is correct (5)');
    } else {
      print('❌ FAIL: Total capacity is ${availability['totalCapacity']}, expected 5');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

// Expected output:
// ✅ TEST 1: Capacity should be 5, not 8
// ✅ TEST 2: Flow function should return slotDetails with totalPersonsBooked
// ✅ TEST 3: Slot availability should show correct capacity (5)
