import 'dart:async';

// lib/src/services/booking_firestore_service.dart
// Booking Firestore Service - Real-time amenities and bookings management

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';
import 'user_data_service.dart';

class AmenityImage {
  final String url;
  final String? storagePath;
  final String? name;

  const AmenityImage({
    required this.url,
    this.storagePath,
    this.name,
  });
}

/// Amenity model for real-time streaming
class AmenityModel {
  final String id;
  final String communityId;
  final String? buildingName;
  final String name;
  final String type;
  final bool isFree;
  final double? pricePerDay;
  final String pricingMode;
  final bool hasExplicitPricingMode;
  final double? ownerPricePerDay;
  final double? tenantPricePerDay;
  final String? residentType;
  final List<String> timeSlots;
  final bool isAvailable;
  final String? buildingId;
  final String? organizationId;
  final String? iconName;
  final String? imageUrl;
  final List<AmenityImage> images;
  final String? description;

  // Subscription packages
  final bool hasSubscriptionPackages;
  final Map<String, double>? subscriptionPackages;

  // Capacity management
  final bool allowMultipleBookings;
  final int maxCapacity;
  final bool hasConfiguredCapacity;

  // Booking durations
  final List<String> bookingDurations;

  AmenityModel({
    required this.id,
    this.communityId = '',
    this.buildingName,
    required this.name,
    required this.type,
    required this.isFree,
    this.pricePerDay,
    String? pricingMode,
    this.hasExplicitPricingMode = false,
    this.ownerPricePerDay,
    this.tenantPricePerDay,
    this.residentType,
    required this.timeSlots,
    required this.isAvailable,
    this.buildingId,
    this.organizationId,
    this.iconName,
    this.imageUrl,
    this.images = const <AmenityImage>[],
    this.description,
    this.hasSubscriptionPackages = false,
    this.subscriptionPackages,
    this.allowMultipleBookings = false,
    this.maxCapacity = 1,
    this.hasConfiguredCapacity = true,
    this.bookingDurations = const ['1 hour'],
  }) : pricingMode = pricingMode ?? (isFree ? 'free' : 'flat');

  factory AmenityModel.fromFirestore(
    DocumentSnapshot doc, {
    String? residentType,
  }) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw StateError('Facility no longer exists.');
    return AmenityModel.fromMap(doc.id, data, residentType: residentType);
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static List<String> _strings(Object? value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
      : [];

  static double? _price(Object? value) =>
      value is num && value.isFinite && value >= 0 ? value.toDouble() : null;

  static int? _capacity(Object? value) =>
      value is num &&
          value.isFinite &&
          value > 0 &&
          value <= 2147483647 &&
          value == value.truncateToDouble()
      ? value.toInt()
      : null;

  static String? _canonicalResidentType(Object? value) {
    final text = _text(value)?.toLowerCase();
    return text == 'owner' || text == 'tenant' ? text : null;
  }

  static String? safeImageUrl(Object? value) {
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

  static List<AmenityImage> _facilityImages(
    Object? value, {
    Object? legacyImageUrl,
  }) {
    final images = <AmenityImage>[];

    if (value is List) {
      for (final item in value) {
        if (item is! Map) continue;

        final map = Map<Object?, Object?>.from(item);
        final url = safeImageUrl(map['url']);
        if (url == null) continue;

        images.add(
          AmenityImage(
            url: url,
            storagePath: _text(map['storagePath']),
            name: _text(map['name']),
          ),
        );

        if (images.length == 6) break;
      }
    }

    if (images.isNotEmpty) return images;

    final legacy = safeImageUrl(legacyImageUrl);
    return legacy == null ? const <AmenityImage>[] : [AmenityImage(url: legacy)];
  }

  factory AmenityModel.fromMap(
    String id,
    Map<String, dynamic> data, {
    String? residentType,
  }) {
    final packages = <String, double>{};
    final rawPackages = data['subscriptionPackages'];
    if (rawPackages is Map) {
      for (final entry in rawPackages.entries) {
        final name = _text(entry.key);
        final price = _price(entry.value);
        if (name != null && price != null) packages[name] = price;
      }
    }
    final isFree = data['isFree'] == true;
    final rawPricingMode = _text(data['pricingMode']);
    final imageUrl = safeImageUrl(data['imageUrl']);
    final images = _facilityImages(
      data['images'],
      legacyImageUrl: imageUrl,
    );

    return AmenityModel(
      id: id,
      communityId: _text(data['communityId']) ?? '',
      buildingId: _text(data['buildingId']),
      buildingName: _text(data['buildingName']),
      name: _text(data['name']) ?? 'Unknown Amenity',
      type: _text(data['type']) ?? 'General',
      description: _text(data['description']),
      imageUrl: imageUrl,
      images: images,
      iconName: _text(data['iconName']),
      organizationId: _text(data['organizationId']),
      isAvailable: data['isAvailable'] == true,
      isFree: isFree,
      pricePerDay: _price(data['pricePerDay']),
      pricingMode: rawPricingMode ?? (isFree ? 'free' : 'flat'),
      hasExplicitPricingMode: rawPricingMode != null,
      ownerPricePerDay: _price(data['ownerPricePerDay']),
      tenantPricePerDay: _price(data['tenantPricePerDay']),
      residentType: _canonicalResidentType(residentType),
      timeSlots: _strings(data['timeSlots']),
      bookingDurations: _strings(data['bookingDurations']),
      maxCapacity: _capacity(data['maxCapacity']) ?? 1,
      hasConfiguredCapacity: _capacity(data['maxCapacity']) != null,
      allowMultipleBookings: data['allowMultipleBookings'] == true,
      hasSubscriptionPackages: data['hasSubscriptionPackages'] == true,
      subscriptionPackages: packages,
    );
  }

  // Presentation only: retain cents and never describe missing paid prices as free.
  static String formatPrice(
    num? value, {
    bool isFree = false,
    String suffix = '',
  }) {
    if (isFree) return 'Free';
    if (_price(value) == null) return 'Price unavailable';
    return '₹${value!.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '')}$suffix';
  }

  double? get effectivePricePerDay {
    if (!hasExplicitPricingMode) {
      return isFree ? 0.0 : pricePerDay;
    }

    switch (pricingMode) {
      case 'free':
        return isFree && pricePerDay == 0 ? 0.0 : null;
      case 'flat':
        return !isFree ? pricePerDay : null;
      case 'resident_type':
        if (isFree || pricePerDay != 0) return null;
        return residentType == 'owner'
            ? ownerPricePerDay
            : residentType == 'tenant'
            ? tenantPricePerDay
            : null;
      default:
        return null;
    }
  }

  String get priceDisplay {
    if (!hasExplicitPricingMode) {
      return formatPrice(pricePerDay, isFree: isFree, suffix: '/day');
    }

    switch (pricingMode) {
      case 'free':
        return isFree && pricePerDay == 0 ? 'Free' : 'Price unavailable';
      case 'flat':
        return !isFree
            ? formatPrice(pricePerDay, suffix: '/day')
            : 'Price unavailable';
      case 'resident_type':
        if (isFree || pricePerDay != 0) return 'Price unavailable';
        final value = residentType == 'owner'
            ? ownerPricePerDay
            : residentType == 'tenant'
            ? tenantPricePerDay
            : null;
        return formatPrice(value, suffix: '/day');
      default:
        return 'Price unavailable';
    }
  }

  String? get primaryImageUrl =>
      images.isNotEmpty ? images.first.url : safeImageUrl(imageUrl);

  bool get hasMultipleImages => images.length > 1;

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

/// Result class for booking operations
class BookingResult {
  final bool success;
  final String? message;
  final String? bookingId;
  final String? errorCode;

  BookingResult({
    required this.success,
    this.message,
    this.bookingId,
    this.errorCode,
  });

  factory BookingResult.success({String? message, String? bookingId}) {
    return BookingResult(
      success: true,
      message: message ?? 'Operation successful',
      bookingId: bookingId,
    );
  }

  factory BookingResult.failure({required String message, String? errorCode}) {
    return BookingResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Booking Firestore Service
class BookingFirestoreService {
  // Singleton pattern
  static final BookingFirestoreService instance =
      BookingFirestoreService._internal();
  factory BookingFirestoreService() => instance;
  BookingFirestoreService._internal()
    : _firestore = FirebaseFirestore.instance,
      _auth = FirebaseAuth.instance,
      _functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  BookingFirestoreService.withDependencies({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    FirebaseFunctions? functions,
  }) : _firestore = firestore,
       _auth = auth,
       _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions? _functions;
  late final UserDataService _userDataService = UserDataService();

  // Collection names
  static const String bookingsCollection = 'bookings';
  static const String amenitiesCollection = 'amenities';

  /// Get current user ID (Firebase Auth or SharedPreferences fallback)
  /// Following the flow function pattern from UserDataService
  Future<String?> _getUserId() async {
    try {
      // First try Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('🆔 BookingService: Firebase Auth User: ${firebaseUser.uid}');

        // Try to find user document by Firebase Auth UID
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          print('✅ BookingService: Found user document by Firebase Auth UID');
          return doc.id;
        } else {
          // Try to find by authUid field
          print('🔍 BookingService: Searching by authUid field...');
          final querySnapshot = await _firestore
              .collection('users')
              .where('authUid', isEqualTo: firebaseUser.uid)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            print('✅ BookingService: Found user document by authUid field');
            return querySnapshot.docs.first.id;
          }
        }
      }

      // Fallback to SharedPreferences
      print(
        '⚠️  BookingService: No Firebase Auth user, checking SharedPreferences...',
      );
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        print('🆔 BookingService: Using stored User ID: $userId');
      } else {
        print('❌ BookingService: No user ID found');
      }

      return userId;
    } catch (e) {
      print('❌ BookingService: Error getting user ID: $e');
      return null;
    }
  }

  /// Get current user data from Firestore
  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('❌ No user logged in');
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ User document not found');
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // CRITICAL: Use Firebase Auth UID for userId, not Firestore document ID
      // This is required for Firestore rules to work
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userData['userId'] = firebaseUser.uid;
        print('✅ Using Firebase Auth UID as userId: ${firebaseUser.uid}');
      } else {
        userData['userId'] = userId;
        print('⚠️  Using Firestore document ID as userId: $userId');
      }

      return userData;
    } catch (e) {
      print('❌ Error fetching user data: $e');
      return null;
    }
  }

  // ============================================================================
  // REAL-TIME AMENITIES STREAMING
  // ============================================================================

  // Rules remain authoritative for active-community and identity eligibility.
  // Facility reads use only the canonical authenticated profile, never cached IDs.
  String? _facilityCommunity(Map<String, dynamic>? profile) {
    if (profile == null ||
        profile['role'] != 'resident' ||
        profile['approvalStatus'] != 'approved' ||
        profile['isActive'] != true ||
        (profile.containsKey('status') && profile['status'] != 'active')) {
      return null;
    }
    final communityId = profile['communityId'];
    return communityId is String && communityId.trim().isNotEmpty
        ? communityId
        : null;
  }

  String? _facilityResidentType(Map<String, dynamic>? profile) {
    if (profile == null) return null;

    String? canonical(Object? value) {
      if (value is! String) return null;
      final text = value.trim().toLowerCase();
      return text == 'owner' || text == 'tenant' ? text : null;
    }

    final rawResidentType = profile['residentType'];
    final rawOwnershipType = profile['ownershipType'];
    final residentType = canonical(rawResidentType);
    final ownershipType = canonical(rawOwnershipType);

    if (rawResidentType != null && residentType == null) return null;
    if (rawOwnershipType != null && ownershipType == null) return null;
    if (residentType != null &&
        ownershipType != null &&
        residentType != ownershipType) {
      return null;
    }

    return residentType ?? ownershipType;
  }

  /// Community-wide reads; explicit availability is filtered after the scoped
  /// query, using the existing single-field communityId index.
  Stream<List<AmenityModel>> streamAmenitiesRealtime() {
    late StreamController<List<AmenityModel>> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    profileSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    facilitySubscription;
    var generation = 0;
    var cancelled = false;
    void empty() {
      if (!cancelled) controller.add([]);
    }

    controller = StreamController<List<AmenityModel>>(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen(
          (user) async {
            final authGeneration = ++generation;
            await profileSubscription?.cancel();
            await facilitySubscription?.cancel();
            if (cancelled || authGeneration != generation) return;
            empty();
            if (user == null) return;
            profileSubscription = _firestore
                .collection('users')
                .doc(user.uid)
                .snapshots()
                .listen(
                  (profile) async {
                    final queryGeneration = ++generation;
                    await facilitySubscription?.cancel();
                    if (cancelled || queryGeneration != generation) return;
                    empty();
                    final profileData = profile.data();
                    final communityId = _facilityCommunity(profileData);
                    final residentType = _facilityResidentType(profileData);
                    if (communityId == null ||
                        _auth.currentUser?.uid != user.uid) {
                      return;
                    }
                    facilitySubscription = _firestore
                        .collection(amenitiesCollection)
                        .where('communityId', isEqualTo: communityId)
                        .snapshots()
                        .listen(
                          (snapshot) {
                            if (cancelled ||
                                queryGeneration != generation ||
                                _auth.currentUser?.uid != user.uid) {
                              return;
                            }
                            controller.add(
                              snapshot.docs
                                  .where(
                                    (doc) =>
                                        doc.data()['communityId'] ==
                                            communityId &&
                                        doc.data()['isAvailable'] == true,
                                  )
                                  .map(
                                    (doc) => AmenityModel.fromFirestore(
                                      doc,
                                      residentType: residentType,
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                          onError: (Object error, StackTrace stack) {
                            if (!cancelled && queryGeneration == generation) {
                              controller.addError(error, stack);
                            }
                          },
                        );
                  },
                  onError: (Object error, StackTrace stack) {
                    generation++;
                    facilitySubscription?.cancel();
                    if (!cancelled) controller.addError(error, stack);
                  },
                );
          },
          onError: (Object error, StackTrace stack) {
            generation++;
            profileSubscription?.cancel();
            facilitySubscription?.cancel();
            if (!cancelled) controller.addError(error, stack);
          },
        );
      },
      onCancel: () async {
        cancelled = true;
        generation++;
        await authSubscription?.cancel();
        await profileSubscription?.cancel();
        await facilitySubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Live detail shares the same scope and explicit availability policy.
  Stream<AmenityModel?> streamAmenityDetails(String amenityId) =>
      streamAmenitiesRealtime().map((items) {
        for (final item in items) {
          if (item.id == amenityId) return item;
        }
        return null;
      });

  // ============================================================================
  // REAL-TIME BOOKINGS STREAMING
  // ============================================================================

  /// Stream user's bookings in real-time
  Stream<List<BookingModel>> streamMyBookingsRealtime() async* {
    try {
      print('🔄 Starting real-time bookings stream...');

      final userId = await _getUserId();
      if (userId == null) {
        print('❌ No user logged in');
        yield [];
        return;
      }

      print('✅ Streaming bookings for user: $userId');

      // Stream bookings filtered by userId (no orderBy to avoid index requirement)
      yield* _firestore
          .collection(bookingsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            print('📊 Received ${snapshot.docs.length} bookings from stream');

            final bookings = snapshot.docs
                .map((doc) {
                  try {
                    return _bookingFromFirestore(doc);
                  } catch (e) {
                    print('⚠️  Error parsing booking ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<BookingModel>()
                .toList();

            // Sort in memory by date (newest first)
            bookings.sort((a, b) => b.date.compareTo(a.date));

            if (bookings.isNotEmpty) {
              print('✅ Streaming ${bookings.length} bookings');
            } else {
              print('⚠️  No bookings found');
            }

            return bookings;
          });
    } catch (e, stackTrace) {
      print('❌ Error in bookings stream: $e');
      print('Stack trace: $stackTrace');
      yield [];
    }
  }

  /// Direct details are queried inside the authenticated community, so a
  /// supplied cross-community ID never causes a direct cross-tenant read.
  Future<AmenityModel?> getAmenityDetails(String amenityId) async {
    try {
      final user = _auth.currentUser;
      if (user == null || amenityId.isEmpty || amenityId.contains('/')) {
        return null;
      }
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final profileData = profile.data();
      final communityId = _facilityCommunity(profileData);
      final residentType = _facilityResidentType(profileData);
      if (communityId == null || _auth.currentUser?.uid != user.uid) {
        return null;
      }
      final snapshot = await _firestore
          .collection(amenitiesCollection)
          .where('communityId', isEqualTo: communityId)
          .where(FieldPath.documentId, isEqualTo: amenityId)
          .limit(1)
          .get();
      if (_auth.currentUser?.uid != user.uid || snapshot.docs.isEmpty) {
        return null;
      }
      final data = snapshot.docs.first.data();
      if (data['communityId'] != communityId || data['isAvailable'] != true) {
        return null;
      }
      return AmenityModel.fromFirestore(
        snapshot.docs.first,
        residentType: residentType,
      );
    } catch (_) {
      return null;
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  Map<String, dynamic> _stringMap(Object? value) {
    if (value is! Map) return const <String, dynamic>{};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  Future<Map<String, dynamic>> _availabilityRangeFromFunction({
    required String amenityId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfPeople,
  }) async {
    final functions = _functions;
    if (functions == null) {
      throw StateError('Callable Functions are not configured.');
    }

    final result = await functions.httpsCallable('getAmenityAvailability').call({
      'amenityId': amenityId,
      'startDateMs': _dateOnly(startDate).millisecondsSinceEpoch,
      'endDateMs': _dateOnly(endDate).millisecondsSinceEpoch,
      'numberOfPeople': numberOfPeople,
      'timezoneOffsetMinutes': startDate.timeZoneOffset.inMinutes,
    });

    final data = _stringMap(result.data);
    if (data['dates'] is! Map) {
      throw StateError('Facility availability response is invalid.');
    }
    return data;
  }

  Future<Map<String, Map<String, dynamic>>> getSlotAvailabilityForDate({
    required String amenityId,
    required DateTime date,
    int numberOfPeople = 1,
  }) async {
    if (_functions == null) {
      final amenity = await getAmenityDetails(amenityId);
      if (amenity == null) return const {};
      final result = <String, Map<String, dynamic>>{};
      for (final slot in amenity.timeSlots) {
        result[slot] = await _checkSlotAvailabilityDirect(
          amenityId: amenityId,
          date: date,
          timeSlot: slot,
          numberOfPeople: numberOfPeople,
        );
      }
      return result;
    }

    try {
      final response = await _availabilityRangeFromFunction(
        amenityId: amenityId,
        startDate: date,
        endDate: date,
        numberOfPeople: numberOfPeople,
      );
      final dates = _stringMap(response['dates']);
      final day = _stringMap(dates[_dateKey(date)]);
      final slots = _stringMap(day['slots']);

      return slots.map(
        (slot, value) => MapEntry(slot, _stringMap(value)),
      );
    } on FirebaseFunctionsException catch (e) {
      print('❌ Callable availability error: ${e.code} ${e.message}');
      final amenity = await getAmenityDetails(amenityId);
      if (amenity == null) return const {};
      return {
        for (final slot in amenity.timeSlots)
          slot: {
            'available': false,
            'reason': e.message ?? 'Unable to check availability',
            'remainingSpots': 0,
            'totalCapacity': amenity.allowMultipleBookings
                ? amenity.maxCapacity
                : 1,
            'bookingCount': 0,
            'totalPersonsBooked': 0,
          },
      };
    } catch (e) {
      print('❌ Callable availability error: $e');
      final amenity = await getAmenityDetails(amenityId);
      if (amenity == null) return const {};
      return {
        for (final slot in amenity.timeSlots)
          slot: {
            'available': false,
            'reason': 'Unable to check availability',
            'remainingSpots': 0,
            'totalCapacity': amenity.allowMultipleBookings
                ? amenity.maxCapacity
                : 1,
            'bookingCount': 0,
            'totalPersonsBooked': 0,
          },
      };
    }
  }

  Future<Set<DateTime>> getFullyBookedDates({
    required String amenityId,
    required DateTime startDate,
    required DateTime endDate,
    int numberOfPeople = 1,
  }) async {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    if (_functions == null) {
      final blocked = <DateTime>{};
      for (
        var date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))
      ) {
        if (await _isDateFullyBookedDirect(
          amenityId: amenityId,
          date: date,
          numberOfPeople: numberOfPeople,
        )) {
          blocked.add(date);
        }
      }
      return blocked;
    }

    try {
      final response = await _availabilityRangeFromFunction(
        amenityId: amenityId,
        startDate: start,
        endDate: end,
        numberOfPeople: numberOfPeople,
      );
      final dates = _stringMap(response['dates']);
      final blocked = <DateTime>{};

      for (
        var date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))
      ) {
        final day = _stringMap(dates[_dateKey(date)]);
        if (day['fullyBooked'] == true) blocked.add(date);
      }
      return blocked;
    } catch (e) {
      print('❌ Unable to load blocked facility dates: $e');
      // Fail closed: if server-side capacity cannot be verified, do not make
      // dates appear bookable.
      final blocked = <DateTime>{};
      for (
        var date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))
      ) {
        blocked.add(date);
      }
      return blocked;
    }
  }

  /// Check one slot. Production uses the trusted callable; injected tests keep
  /// the legacy direct path so existing fake Firestore tests remain isolated.
  Future<Map<String, dynamic>> checkSlotAvailability({
    required String amenityId,
    required DateTime date,
    required String timeSlot,
    int numberOfPeople = 1,
  }) async {
    if (_functions == null) {
      return _checkSlotAvailabilityDirect(
        amenityId: amenityId,
        date: date,
        timeSlot: timeSlot,
        numberOfPeople: numberOfPeople,
      );
    }

    final slots = await getSlotAvailabilityForDate(
      amenityId: amenityId,
      date: date,
      numberOfPeople: numberOfPeople,
    );
    return slots[timeSlot] ??
        {
          'available': false,
          'reason': 'This time slot is unavailable',
          'remainingSpots': 0,
          'totalCapacity': 0,
          'bookingCount': 0,
          'totalPersonsBooked': 0,
        };
  }

  /// Direct Firestore implementation retained only for injected unit tests.
  Future<Map<String, dynamic>> _checkSlotAvailabilityDirect({
    required String amenityId,
    required DateTime date,
    required String timeSlot,
    int numberOfPeople = 1, // NEW: Number of people to book for
  }) async {
    try {
      print(
        '🔍 Checking availability for $amenityId on ${date.toString().split(' ')[0]} at $timeSlot for $numberOfPeople people',
      );

      // Get amenity details
      final amenity = await getAmenityDetails(amenityId);
      if (amenity == null) {
        print('❌ Amenity not found');
        return {
          'available': false,
          'reason': 'Amenity not found',
          'remainingSpots': 0,
          'totalCapacity': 0,
        };
      }

      // Query existing bookings for this date and time slot
      // Use simpler query to avoid index requirements
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print(
        '📅 Querying bookings from ${startOfDay.toString()} to ${endOfDay.toString()}',
      );

      final bookingsSnapshot = await _firestore
          .collection(bookingsCollection)
          .where('amenityId', isEqualTo: amenityId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      print('📊 Total bookings for this date: ${bookingsSnapshot.docs.length}');

      // Filter in memory for time slot and status
      final matchingBookings = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        final docTimeSlot = data['timeSlot'] as String?;
        final docStatus = data['status'] as String?;

        return docTimeSlot == timeSlot &&
            (docStatus == 'confirmed' || docStatus == 'pending');
      }).toList();

      print(
        '📊 Found ${matchingBookings.length} bookings for time slot "$timeSlot"',
      );

      // NEW: Sum up numberOfPeople from all bookings (not just count bookings)
      int totalPeople = 0;
      for (var doc in matchingBookings) {
        final data = doc.data();
        final people = data['numberOfPeople'] as int? ?? 1;
        totalPeople += people;
        print(
          '  👥 Booking ${doc.id}: $people people (Status: ${data['status']})',
        );
      }

      print(
        '📊 Total people booked: $totalPeople out of ${amenity.maxCapacity}',
      );

      // Check availability based on amenity settings
      if (!amenity.allowMultipleBookings) {
        // Single booking only
        final available = matchingBookings.isEmpty;
        print('✅ Single booking mode: ${available ? "Available" : "Booked"}');
        return {
          'available': available,
          'reason': available ? 'Available' : 'Already booked',
          'remainingSpots': available ? 1 : 0,
          'totalCapacity': 1,
          'bookingCount': matchingBookings.length,
          'totalPeople': totalPeople,
        };
      } else {
        // Multiple bookings allowed - check if enough capacity for requested number of people
        final remainingSpots = amenity.maxCapacity - totalPeople;
        final canBook = remainingSpots >= numberOfPeople;
        print('✅ Multiple booking mode:');
        print('   Max capacity: ${amenity.maxCapacity}');
        print('   Total people booked: $totalPeople');
        print('   Remaining spots: $remainingSpots');
        print('   Requested: $numberOfPeople people');
        print('   Can book: $canBook');
        return {
          'available': canBook,
          'reason': canBook ? 'Available' : 'Not enough capacity',
          'remainingSpots': remainingSpots > 0 ? remainingSpots : 0,
          'totalCapacity': amenity.maxCapacity,
          'bookingCount': matchingBookings.length,
          'totalPeople': totalPeople,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Error checking availability: $e');
      print('Stack trace: $stackTrace');
      // Fail closed. An availability error must never create a false
      // impression that a slot is free.
      return {
        'available': false,
        'reason': 'Unable to check availability',
        'remainingSpots': 0,
        'totalCapacity': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get bookings for a date range (for calendar blocking)
  Future<Map<String, List<Map<String, dynamic>>>> getBookingsForDateRange({
    required String amenityId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print(
        '📅 Fetching bookings from ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
      );

      final bookingsSnapshot = await _firestore
          .collection(bookingsCollection)
          .where('amenityId', isEqualTo: amenityId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      // Group bookings by date and time slot
      final Map<String, List<Map<String, dynamic>>> bookingsByDate = {};

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp;
        final date = timestamp.toDate();
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final timeSlot = data['timeSlot'] as String;

        if (!bookingsByDate.containsKey(dateKey)) {
          bookingsByDate[dateKey] = [];
        }

        bookingsByDate[dateKey]!.add({
          'timeSlot': timeSlot,
          'bookingId': doc.id,
        });
      }

      print('✅ Found bookings for ${bookingsByDate.length} dates');
      return bookingsByDate;
    } catch (e) {
      print('❌ Error fetching bookings for date range: $e');
      return {};
    }
  }

  Future<bool> _isDateFullyBookedDirect({
    required String amenityId,
    required DateTime date,
    int numberOfPeople = 1,
  }) async {
    try {
      final amenity = await getAmenityDetails(amenityId);
      if (amenity == null || amenity.timeSlots.isEmpty) return true;

      for (final timeSlot in amenity.timeSlots) {
        final availability = await _checkSlotAvailabilityDirect(
          amenityId: amenityId,
          date: date,
          timeSlot: timeSlot,
          numberOfPeople: numberOfPeople,
        );
        if (availability['available'] == true) return false;
      }
      return true;
    } catch (e) {
      print('❌ Error checking if date is fully booked: $e');
      return true;
    }
  }

  /// Check if a date is fully booked. Production uses one server-side
  /// availability request instead of reading other residents' bookings.
  Future<bool> isDateFullyBooked({
    required String amenityId,
    required DateTime date,
  }) async {
    if (_functions == null) {
      return _isDateFullyBookedDirect(amenityId: amenityId, date: date);
    }
    final blocked = await getFullyBookedDates(
      amenityId: amenityId,
      startDate: date,
      endDate: date,
    );
    return blocked.contains(_dateOnly(date));
  }

  // ============================================================================
  // CREATE BOOKING
  // ============================================================================

  /// Create a new booking in Firestore
  Future<BookingResult> createBooking({
    required String amenityId,
    required String amenityName,
    required DateTime date,
    required String timeSlot,
    String bookingType = 'daily', // NEW: 'daily', 'weekly', 'monthly', 'yearly'
    int numberOfPeople = 1, // NEW: Number of people
    List<String>? familyMembers, // NEW: Optional family member names
  }) async {
    final functions = _functions;
    if (functions != null) {
      try {
        final result = await functions.httpsCallable('createAmenityBooking').call({
          'amenityId': amenityId,
          'dateMs': _dateOnly(date).millisecondsSinceEpoch,
          'timeSlot': timeSlot,
          'bookingType': bookingType,
          'numberOfPeople': numberOfPeople,
          if (familyMembers != null && familyMembers.isNotEmpty)
            'familyMembers': familyMembers,
          'timezoneOffsetMinutes': date.timeZoneOffset.inMinutes,
        });
        final data = _stringMap(result.data);
        final bookingId = data['bookingId']?.toString();
        if (bookingId == null || bookingId.isEmpty) {
          return BookingResult.failure(
            message: 'The booking response was invalid.',
            errorCode: 'invalid-response',
          );
        }
        return BookingResult.success(
          message: 'Booking confirmed successfully',
          bookingId: bookingId,
        );
      } on FirebaseFunctionsException catch (e) {
        print('❌ Booking callable error: ${e.code} ${e.message}');
        return BookingResult.failure(
          message: e.message ?? _getErrorMessage(e.code),
          errorCode: e.code,
        );
      } catch (e) {
        print('❌ Booking callable error: $e');
        return BookingResult.failure(
          message: 'Failed to create booking. Please try again.',
        );
      }
    }

    try {
      print('🔵 Creating booking...');
      print('🏢 Amenity: $amenityName');
      print('📅 Date: $date');
      print('⏰ Time Slot: $timeSlot');
      print('📦 Booking Type: $bookingType');
      print('👥 Number of People: $numberOfPeople');

      // Get current user data
      final userData = await _getUserData();
      if (userData == null) {
        return BookingResult.failure(
          message: 'No user is currently signed in',
          errorCode: 'not-authenticated',
        );
      }

      final userId = userData['userId'] as String;
      final userName = userData['name'] ?? 'Unknown User';
      final userEmail = userData['email'] ?? '';
      final flatId = userData['flatId'] ?? '';
      final flatLabel = userData['flatLabel'] ?? userData['flatId'] ?? '';
      final buildingId = userData['buildingId'];
      final organizationId = userData['organizationId'];
      final communityId = userData['communityId']?.toString().trim() ?? '';
      if (communityId.isEmpty) {
        return BookingResult.failure(
          message: 'Your resident account is not assigned to a community.',
          errorCode: 'community-not-assigned',
        );
      }

      print('✅ User data fetched: $userName');
      print('🏢 Flat: $flatLabel');
      print('🏢 Building ID: $buildingId');

      // Get amenity details to fetch adminId and calculate price
      final amenity = await getAmenityDetails(amenityId);
      String? adminId;
      String? adminName;
      String? adminEmail;
      double price = 0;

      if (amenity != null) {
        // Fetch amenity document to get admin details
        final amenityDoc = await _firestore
            .collection(amenitiesCollection)
            .doc(amenityId)
            .get();

        if (amenityDoc.exists) {
          final amenityData = amenityDoc.data() as Map<String, dynamic>;
          adminId = amenityData['adminId']?.toString();
          adminName = amenityData['adminName']?.toString();
          adminEmail = amenityData['adminEmail']?.toString();

          print('✅ Admin data fetched: $adminName (ID: $adminId)');
        }

        // Calculate price based on booking type
        if (bookingType == 'daily') {
          price = amenity.effectivePricePerDay ?? 0;
        } else if (amenity.subscriptionPackages != null) {
          final packageKey = bookingType == 'weekly'
              ? 'Weekly'
              : bookingType == 'monthly'
              ? 'Monthly'
              : 'Yearly';
          price = amenity.subscriptionPackages![packageKey] ?? 0;
        }

        print('💰 Calculated price: ₹$price');
      }

      // Calculate package dates
      final subscriptionStartDate = date;
      DateTime subscriptionEndDate;
      int validityDays;
      String? packageType;

      switch (bookingType) {
        case 'weekly':
          subscriptionEndDate = date.add(const Duration(days: 7));
          validityDays = 7;
          packageType = 'Weekly';
          break;
        case 'monthly':
          subscriptionEndDate = date.add(const Duration(days: 30));
          validityDays = 30;
          packageType = 'Monthly';
          break;
        case 'yearly':
          subscriptionEndDate = date.add(const Duration(days: 365));
          validityDays = 365;
          packageType = 'Yearly';
          break;
        default: // daily
          subscriptionEndDate = date;
          validityDays = 1;
          packageType = null;
      }

      print(
        '📅 Subscription: ${subscriptionStartDate.toString().split(' ')[0]} to ${subscriptionEndDate.toString().split(' ')[0]}',
      );
      print('⏳ Validity: $validityDays days');

      // Create booking document
      final bookingData = {
        // User Info
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'flatId': flatId,
        'flatLabel': flatLabel,
        'buildingId': buildingId,
        'organizationId': organizationId,
        'communityId': communityId,

        // Amenity Info
        'amenityId': amenityId,
        'amenityName': amenityName,

        // Booking Type & Duration (NEW)
        'bookingType': bookingType,
        'packageType': packageType,

        // Date & Time
        'date': Timestamp.fromDate(date),
        'timeSlot': timeSlot,

        // Package Duration (NEW)
        'subscriptionStartDate': Timestamp.fromDate(subscriptionStartDate),
        'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
        'validityDays': validityDays,

        // Family Members (NEW)
        'numberOfPeople': numberOfPeople,

        // Pricing
        'price': price,
        'pricePerDay': amenity?.effectivePricePerDay ?? 0,

        // Status
        'status': 'confirmed', // confirmed, cancelled, completed, expired
        'cancellationDate': null,
        'cancellationReason': null,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add admin details if available
      if (adminId != null) {
        bookingData['adminId'] = adminId;
        if (adminName != null) bookingData['adminName'] = adminName;
        if (adminEmail != null) bookingData['adminEmail'] = adminEmail;
      }

      // Add family members if provided
      if (familyMembers != null && familyMembers.isNotEmpty) {
        bookingData['familyMembers'] = familyMembers;
      }

      print('📦 Booking data: $bookingData');

      // Add to Firestore
      final docRef = await _firestore
          .collection(bookingsCollection)
          .add(bookingData);

      print('✅ Booking created successfully!');
      print('🆔 Booking ID: ${docRef.id}');

      return BookingResult.success(
        message: 'Booking confirmed successfully',
        bookingId: docRef.id,
      );
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code}');
      print('❌ Message: ${e.message}');
      return BookingResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return BookingResult.failure(
        message: 'Failed to create booking. Please try again.',
      );
    }
  }

  // ============================================================================
  // UPDATE BOOKING
  // ============================================================================

  /// Cancel booking
  Future<BookingResult> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    final functions = _functions;
    if (functions != null) {
      try {
        await functions.httpsCallable('cancelAmenityBooking').call({
          'bookingId': bookingId,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        });
        return BookingResult.success(message: 'Booking cancelled successfully');
      } on FirebaseFunctionsException catch (e) {
        print('❌ Cancellation callable error: ${e.code} ${e.message}');
        return BookingResult.failure(
          message: e.message ?? _getErrorMessage(e.code),
          errorCode: e.code,
        );
      } catch (e) {
        print('❌ Cancellation callable error: $e');
        return BookingResult.failure(message: 'Failed to cancel booking');
      }
    }

    try {
      print('🔵 Cancelling booking: $bookingId');
      if (reason != null) {
        print('📝 Reason: $reason');
      }

      final updateData = {
        'status': 'cancelled',
        'cancellationDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add cancellation reason if provided
      if (reason != null && reason.isNotEmpty) {
        updateData['cancellationReason'] = reason;
      }

      await _firestore
          .collection(bookingsCollection)
          .doc(bookingId)
          .update(updateData);

      print('✅ Booking cancelled successfully');
      return BookingResult.success(message: 'Booking cancelled successfully');
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code}');
      return BookingResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      return BookingResult.failure(message: 'Failed to cancel booking');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Convert Firestore document to BookingModel object
  BookingModel _bookingFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse date timestamp
    DateTime date;
    try {
      final timestamp = data['date'] as Timestamp?;
      date = timestamp?.toDate() ?? DateTime.now();
    } catch (e) {
      date = DateTime.now();
    }

    // Parse createdAt timestamp
    DateTime createdAt;
    try {
      final timestamp = data['createdAt'] as Timestamp?;
      createdAt = timestamp?.toDate() ?? DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    // Parse subscription dates (NEW)
    DateTime? subscriptionStartDate;
    DateTime? subscriptionEndDate;
    try {
      final startTimestamp = data['subscriptionStartDate'] as Timestamp?;
      subscriptionStartDate = startTimestamp?.toDate();

      final endTimestamp = data['subscriptionEndDate'] as Timestamp?;
      subscriptionEndDate = endTimestamp?.toDate();
    } catch (e) {
      // Ignore parsing errors
    }

    return BookingModel(
      id: doc.id,
      amenityId: data['amenityId'] as String? ?? '',
      amenityName: data['amenityName'] as String? ?? 'Unknown',
      date: date,
      timeSlot: data['timeSlot'] as String? ?? '',
      status: data['status'] as String? ?? 'confirmed',
      createdAt: createdAt,
      userId: data['userId'] as String? ?? '',
      // NEW fields
      bookingType: data['bookingType'] as String? ?? 'daily',
      packageType: data['packageType'] as String?,
      numberOfPeople: data['numberOfPeople'] as int? ?? 1,
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      validityDays: data['validityDays'] as int? ?? 1,
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'Permission denied. Please check your access rights.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Booking not found.';
      case 'already-exists':
        return 'Booking already exists.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
