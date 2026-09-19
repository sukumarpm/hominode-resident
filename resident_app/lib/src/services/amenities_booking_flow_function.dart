// lib/src/services/amenities_booking_flow_function.dart
// Complete Amenities Booking Flow Function with proper Firestore integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import 'booking_firestore_service.dart';
import 'user_data_service.dart';

class AmenitiesBookingFlowFunction {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BookingFirestoreService _bookingService = BookingFirestoreService();
  final UserDataService _userDataService = UserDataService();

  /// STEP 1: Validate Authentication
  /// Check if user is authenticated and get their UID
  Future<String?> _validateAuthentication() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ AmenitiesFlow: User not authenticated');
        return null;
      }
      debugPrint(
        '✅ AmenitiesFlow STEP 1: Authentication validated - UID: ${user.uid}',
      );
      return user.uid;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow STEP 1 Error: $e');
      return null;
    }
  }

  /// STEP 2: Get User's Building ID
  /// Fetch user document to get their buildingId
  Future<String?> _getUserBuildingId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('❌ AmenitiesFlow STEP 2: User document not found');
        return null;
      }

      final buildingId = userDoc.data()?['buildingId'] as String?;
      if (buildingId == null || buildingId.isEmpty) {
        debugPrint('❌ AmenitiesFlow STEP 2: No buildingId found for user');
        return null;
      }

      debugPrint('✅ AmenitiesFlow STEP 2: BuildingId retrieved - $buildingId');
      return buildingId;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow STEP 2 Error: $e');
      return null;
    }
  }

  /// STEP 3: Fetch Available Amenities
  /// Query amenities collection filtered by buildingId and isAvailable = true
  Future<List<AmenityModel>> _fetchAvailableAmenities(String buildingId) async {
    try {
      debugPrint(
        '📋 AmenitiesFlow STEP 3: Fetching amenities for buildingId: $buildingId',
      );

      final snapshot = await _firestore
          .collection('amenities')
          .where('buildingId', isEqualTo: buildingId)
          .where('isAvailable', isEqualTo: true)
          .get();

      debugPrint(
        '✅ AmenitiesFlow STEP 3: Found ${snapshot.docs.length} amenities',
      );

      final amenities = snapshot.docs
          .map((doc) {
            try {
              return AmenityModel.fromFirestore(doc);
            } catch (e) {
              debugPrint(
                '⚠️ AmenitiesFlow: Error parsing amenity ${doc.id}: $e',
              );
              return null;
            }
          })
          .whereType<AmenityModel>()
          .toList();

      return amenities;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow STEP 3 Error: $e');
      return [];
    }
  }

  /// STEP 4: Fetch User's Bookings
  /// Query bookings collection filtered by userId
  Future<List<BookingModel>> _fetchUserBookings(String userId) async {
    try {
      debugPrint(
        '📋 AmenitiesFlow STEP 4: Fetching bookings for userId: $userId',
      );

      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint(
        '✅ AmenitiesFlow STEP 4: Found ${snapshot.docs.length} bookings',
      );

      final bookings = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return _bookingFromFirestore(doc);
            } catch (e) {
              debugPrint(
                '⚠️ AmenitiesFlow: Error parsing booking ${doc.id}: $e',
              );
              return null;
            }
          })
          .whereType<BookingModel>()
          .toList();

      return bookings;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow STEP 4 Error: $e');
      return [];
    }
  }

  /// STEP 5: Process and Sort Data
  /// Sort amenities and bookings for display
  Map<String, dynamic> _processData({
    required List<AmenityModel> amenities,
    required List<BookingModel> bookings,
  }) {
    try {
      debugPrint('🔄 AmenitiesFlow STEP 5: Processing data');

      // Sort bookings by date (newest first)
      bookings.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('✅ AmenitiesFlow STEP 5: Sorted ${bookings.length} bookings');

      // Separate active and past bookings
      final now = DateTime.now();
      final activeBookings = bookings.where((b) {
        return b.status == 'confirmed' && b.date.isAfter(now);
      }).toList();

      final pastBookings = bookings.where((b) {
        return b.status == 'confirmed' && b.date.isBefore(now);
      }).toList();

      debugPrint(
        '✅ AmenitiesFlow STEP 5: ${activeBookings.length} active, ${pastBookings.length} past bookings',
      );

      return {
        'amenities': amenities,
        'allBookings': bookings,
        'activeBookings': activeBookings,
        'pastBookings': pastBookings,
        'totalAmenities': amenities.length,
        'totalBookings': bookings.length,
      };
    } catch (e) {
      debugPrint('❌ AmenitiesFlow STEP 5 Error: $e');
      return {
        'amenities': amenities,
        'allBookings': bookings,
        'activeBookings': [],
        'pastBookings': bookings,
        'totalAmenities': amenities.length,
        'totalBookings': bookings.length,
      };
    }
  }

  /// STEP 6: Return Processed Data
  /// Complete flow function - returns amenities and bookings ready for display
  Future<Map<String, dynamic>> getAmenitiesAndBookings() async {
    try {
      debugPrint('🚀 AmenitiesFlow: Starting complete flow function');

      // STEP 1: Validate Authentication
      final userId = await _validateAuthentication();
      if (userId == null) {
        return {
          'amenities': [],
          'allBookings': [],
          'activeBookings': [],
          'pastBookings': [],
          'totalAmenities': 0,
          'totalBookings': 0,
          'error': 'User not authenticated',
        };
      }

      // STEP 2: Get User's Building ID
      final buildingId = await _getUserBuildingId(userId);
      if (buildingId == null) {
        return {
          'amenities': [],
          'allBookings': [],
          'activeBookings': [],
          'pastBookings': [],
          'totalAmenities': 0,
          'totalBookings': 0,
          'error': 'No building assigned to user',
        };
      }

      // STEP 3: Fetch Available Amenities
      final amenities = await _fetchAvailableAmenities(buildingId);

      // STEP 4: Fetch User's Bookings
      final bookings = await _fetchUserBookings(userId);

      // STEP 5: Process and Sort Data
      final processedData = _processData(
        amenities: amenities,
        bookings: bookings,
      );

      debugPrint(
        '✅ AmenitiesFlow: Complete - Returning ${amenities.length} amenities and ${bookings.length} bookings',
      );
      return processedData;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow: Fatal error - $e');
      return {
        'amenities': [],
        'allBookings': [],
        'activeBookings': [],
        'pastBookings': [],
        'totalAmenities': 0,
        'totalBookings': 0,
        'error': e.toString(),
      };
    }
  }

  /// Stream Amenities in Real-time
  /// Returns a stream of amenities that updates automatically
  Stream<List<AmenityModel>> streamAmenities() async* {
    try {
      debugPrint('📡 AmenitiesFlow: Starting amenities stream');

      // Validate authentication
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ AmenitiesFlow Stream: User not authenticated');
        yield [];
        return;
      }

      // Get user's building ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final buildingId = userDoc.data()?['buildingId'] as String?;

      if (buildingId == null) {
        debugPrint('❌ AmenitiesFlow Stream: No buildingId found');
        yield [];
        return;
      }

      // Stream amenities
      yield* _firestore
          .collection('amenities')
          .where('buildingId', isEqualTo: buildingId)
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final amenities = snapshot.docs
                .map((doc) {
                  try {
                    return AmenityModel.fromFirestore(doc);
                  } catch (e) {
                    debugPrint(
                      '⚠️ AmenitiesFlow: Error parsing amenity ${doc.id}: $e',
                    );
                    return null;
                  }
                })
                .whereType<AmenityModel>()
                .toList();

            debugPrint(
              '📡 AmenitiesFlow: Streamed ${amenities.length} amenities',
            );
            return amenities;
          });
    } catch (e) {
      debugPrint('❌ AmenitiesFlow Stream Error: $e');
      yield [];
    }
  }

  /// Stream User's Bookings in Real-time
  /// Returns a stream of bookings that updates automatically
  Stream<List<BookingModel>> streamUserBookings() async* {
    try {
      debugPrint('📡 AmenitiesFlow: Starting bookings stream');

      // Validate authentication
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ AmenitiesFlow Stream: User not authenticated');
        yield [];
        return;
      }

      // Get user ID from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userId = userDoc.id;

      // Stream bookings
      yield* _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final bookings = snapshot.docs
                .map((doc) {
                  try {
                    return _bookingFromFirestore(doc);
                  } catch (e) {
                    debugPrint(
                      '⚠️ AmenitiesFlow: Error parsing booking ${doc.id}: $e',
                    );
                    return null;
                  }
                })
                .whereType<BookingModel>()
                .toList();

            // Sort by date (newest first)
            bookings.sort((a, b) => b.date.compareTo(a.date));

            debugPrint(
              '📡 AmenitiesFlow: Streamed ${bookings.length} bookings',
            );
            return bookings;
          });
    } catch (e) {
      debugPrint('❌ AmenitiesFlow Stream Error: $e');
      yield [];
    }
  }

  /// Get Active Bookings Count
  /// Returns the number of active (future) bookings
  Future<int> getActiveBookingsCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userId = userDoc.id;

      final bookings = await _fetchUserBookings(userId);
      final now = DateTime.now();

      final activeBookings = bookings.where((b) {
        return b.status == 'confirmed' && b.date.isAfter(now);
      }).length;

      debugPrint('📊 AmenitiesFlow: Active bookings count: $activeBookings');
      return activeBookings;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow: Error getting active bookings count - $e');
      return 0;
    }
  }

  /// Get Amenities Count
  /// Returns the total number of available amenities
  Future<int> getAmenitiesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final buildingId = userDoc.data()?['buildingId'] as String?;

      if (buildingId == null) return 0;

      final amenities = await _fetchAvailableAmenities(buildingId);
      debugPrint(
        '📊 AmenitiesFlow: Total amenities count: ${amenities.length}',
      );
      return amenities.length;
    } catch (e) {
      debugPrint('❌ AmenitiesFlow: Error getting amenities count - $e');
      return 0;
    }
  }

  /// Helper: Convert Firestore document to BookingModel
  BookingModel _bookingFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse date timestamp
    DateTime date;
    try {
      final dateField = data['date'];
      if (dateField is Timestamp) {
        date = dateField.toDate();
      } else if (dateField is DateTime) {
        date = dateField;
      } else {
        date = DateTime.now();
      }
    } catch (e) {
      date = DateTime.now();
    }

    // Parse subscription dates if available
    DateTime? subscriptionStartDate;
    DateTime? subscriptionEndDate;
    try {
      if (data['subscriptionStartDate'] is Timestamp) {
        subscriptionStartDate = (data['subscriptionStartDate'] as Timestamp)
            .toDate();
      }
      if (data['subscriptionEndDate'] is Timestamp) {
        subscriptionEndDate = (data['subscriptionEndDate'] as Timestamp)
            .toDate();
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amenityId: data['amenityId'] ?? '',
      amenityName: data['amenityName'] ?? 'Unknown Amenity',
      date: date,
      timeSlot: data['timeSlot'] ?? '',
      status: data['status'] ?? 'pending',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      bookingType: data['bookingType'] ?? 'daily',
      numberOfPeople: data['numberOfPeople'] as int? ?? 1,
      packageType: data['packageType'],
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      validityDays: data['validityDays'] as int? ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FlowAmenityImage {
  final String url;
  final String? storagePath;
  final String? name;

  const FlowAmenityImage({required this.url, this.storagePath, this.name});
}

/// Amenity Model for flow function
class AmenityModel {
  final String id;
  final String name;
  final String type;
  final bool isFree;
  final double? pricePerDay;
  final List<String> timeSlots;
  final bool isAvailable;
  final String? buildingId;
  final String? organizationId;
  final String? iconName;
  final String? imageUrl;
  final List<FlowAmenityImage> images;
  final String? description;
  final bool hasSubscriptionPackages;
  final Map<String, double>? subscriptionPackages;
  final bool allowMultipleBookings;
  final int maxCapacity;
  final List<String> bookingDurations;

  AmenityModel({
    required this.id,
    required this.name,
    required this.type,
    required this.isFree,
    this.pricePerDay,
    required this.timeSlots,
    required this.isAvailable,
    this.buildingId,
    this.organizationId,
    this.iconName,
    this.imageUrl,
    this.images = const <FlowAmenityImage>[],
    this.description,
    this.hasSubscriptionPackages = false,
    this.subscriptionPackages,
    this.allowMultipleBookings = false,
    this.maxCapacity = 1,
    this.bookingDurations = const ['1 hour'],
  });

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static String? _safeImageUrl(Object? value) {
    final text = _text(value);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    return uri != null &&
            {'http', 'https'}.contains(uri.scheme) &&
            uri.host.isNotEmpty &&
            !RegExp(r'\s').hasMatch(text)
        ? text
        : null;
  }

  static List<FlowAmenityImage> _facilityImages(
    Object? value, {
    Object? legacyImageUrl,
  }) {
    final images = <FlowAmenityImage>[];

    if (value is List) {
      for (final item in value) {
        if (item is! Map) continue;

        final map = Map<Object?, Object?>.from(item);
        final url = _safeImageUrl(map['url']);
        if (url == null) continue;

        images.add(
          FlowAmenityImage(
            url: url,
            storagePath: _text(map['storagePath']),
            name: _text(map['name']),
          ),
        );
        if (images.length == 6) break;
      }
    }

    if (images.isNotEmpty) return images;

    final legacy = _safeImageUrl(legacyImageUrl);
    return legacy == null
        ? const <FlowAmenityImage>[]
        : [FlowAmenityImage(url: legacy)];
  }

  factory AmenityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Amenity document data is null');
    }

    // Parse timeSlots safely
    List<String> timeSlots = [];
    try {
      final rawTimeSlots = data['timeSlots'];
      if (rawTimeSlots != null && rawTimeSlots is List) {
        timeSlots = List<String>.from(rawTimeSlots.cast<String>());
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing timeSlots: $e');
      timeSlots = [];
    }

    // Parse subscription packages
    Map<String, double>? packages;
    if (data['subscriptionPackages'] != null) {
      try {
        final packagesData =
            data['subscriptionPackages'] as Map<String, dynamic>?;
        if (packagesData != null) {
          packages = packagesData.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing subscriptionPackages: $e');
        packages = null;
      }
    }

    // Parse bookingDurations safely
    List<String> bookingDurations = ['1 hour'];
    try {
      final rawDurations = data['bookingDurations'];
      if (rawDurations != null && rawDurations is List) {
        bookingDurations = List<String>.from(rawDurations.cast<String>());
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing bookingDurations: $e');
      bookingDurations = ['1 hour'];
    }

    final imageUrl = _safeImageUrl(data['imageUrl']);
    final images = _facilityImages(data['images'], legacyImageUrl: imageUrl);

    return AmenityModel(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Unknown Amenity',
      type: data['type'] ?? 'General',
      isFree: data['isFree'] ?? false,
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble(),
      timeSlots: timeSlots,
      isAvailable: data['isAvailable'] ?? true,
      buildingId: data['buildingId']?.toString(),
      organizationId: data['organizationId']?.toString(),
      iconName: data['iconName']?.toString(),
      imageUrl: imageUrl,
      images: images,
      description: data['description']?.toString(),
      hasSubscriptionPackages: data['hasSubscriptionPackages'] ?? false,
      subscriptionPackages: packages,
      allowMultipleBookings: data['allowMultipleBookings'] ?? false,
      maxCapacity: (data['maxCapacity'] as num?)?.toInt() ?? 1,
      bookingDurations: bookingDurations,
    );
  }

  String? get primaryImageUrl =>
      images.isNotEmpty ? images.first.url : _safeImageUrl(imageUrl);

  bool get hasMultipleImages => images.length > 1;

  String get priceDisplay {
    if (isFree) return 'Free';
    if (pricePerDay != null) return '₹${pricePerDay!.toStringAsFixed(0)}/day';
    return 'Free';
  }

  String get timeSlotsDisplay {
    if (timeSlots.isEmpty) return 'No time slots available';
    if (timeSlots.length == 1) return timeSlots.first;
    return '${timeSlots.length} slots available';
  }

  String get capacityDisplay {
    if (!allowMultipleBookings) return 'Single booking';
    return 'Up to $maxCapacity users';
  }

  bool get hasPackages =>
      hasSubscriptionPackages &&
      subscriptionPackages != null &&
      subscriptionPackages!.isNotEmpty;
}
