// lib/src/services/resident_database_service.dart
// Resident-specific database service with read-only access

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/flat_model.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import '../models/visitor_model.dart';
import '../models/notice_model.dart';
import '../models/complaint_model.dart';
import 'firebase_auth_service.dart';

/// Result class for database operations
class ResidentDataResult<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;

  ResidentDataResult({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
  });

  factory ResidentDataResult.success({String? message, T? data}) {
    return ResidentDataResult(
      success: true,
      message: message ?? 'Data fetched successfully',
      data: data,
    );
  }

  factory ResidentDataResult.failure({
    required String message,
    String? errorCode,
  }) {
    return ResidentDataResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Resident-specific database service
/// Provides read-only access to resident's own data
class ResidentDatabaseService {
  // Singleton pattern
  static final ResidentDatabaseService instance =
      ResidentDatabaseService._internal();
  factory ResidentDatabaseService() => instance;
  ResidentDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Collection names
  static const String usersCollection = 'users';
  static const String flatsCollection = 'flats';
  static const String billsCollection = 'bills';
  static const String paymentsCollection = 'payments';
  static const String visitorsCollection = 'visitors';
  static const String noticesCollection = 'notices';
  static const String complaintsCollection = 'complaints';

  // ============================================================================
  // PROFILE DATA
  // ============================================================================

  /// Create a new user in Firestore
  Future<ResidentDataResult<UserModel>> createUser({
    required String userId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? photoURL,
    String role = 'resident',
  }) async {
    try {
      print('🔵 ResidentDatabaseService.createUser called');
      print('🆔 User ID: $userId');
      print('👤 Full Name: $fullName');
      print('📧 Email: $email');
      print('📱 Phone: $phoneNumber');

      final user = UserModel(
        id: userId,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        photoURL: photoURL,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      print('📦 User model created');
      print('💾 Attempting to write to Firestore...');
      print('📍 Collection: $usersCollection');
      print('📄 Document ID: $userId');

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .set(user.toMap());

      print('✅ Firestore write successful!');

      return ResidentDataResult.success(
        message: 'User created successfully',
        data: user,
      );
    } on FirebaseException catch (e) {
      print('❌ Firebase Exception: ${e.code}');
      print('❌ Message: ${e.message}');
      print('❌ Details: ${e.toString()}');
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e, stackTrace) {
      print('❌ General Exception: $e');
      print('📍 Stack trace: $stackTrace');
      return ResidentDataResult.failure(message: 'Failed to create user: $e');
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get current user's profile
  Future<ResidentDataResult<UserModel>> getMyProfile() async {
    try {
      final currentUser = _authService.getCurrentUser();

      if (currentUser == null) {
        return ResidentDataResult.failure(
          message: 'No user is currently signed in',
          errorCode: 'not-authenticated',
        );
      }

      final doc = await _firestore
          .collection(usersCollection)
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) {
        return ResidentDataResult.failure(
          message: 'User profile not found',
          errorCode: 'not-found',
        );
      }

      final user = UserModel.fromSnapshot(doc);
      return ResidentDataResult.success(data: user);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(message: 'Failed to fetch profile: $e');
    }
  }

  /// Stream current user's profile (real-time updates)
  Stream<UserModel?> streamMyProfile() {
    final currentUser = _authService.getCurrentUser();

    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(usersCollection)
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromSnapshot(doc);
          }
          return null;
        });
  }

  // ============================================================================
  // FLAT DETAILS
  // ============================================================================

  /// Get current user's flat details
  Future<ResidentDataResult<FlatModel>> getMyFlat() async {
    try {
      final currentUser = _authService.getCurrentUser();

      if (currentUser == null) {
        return ResidentDataResult.failure(
          message: 'No user is currently signed in',
          errorCode: 'not-authenticated',
        );
      }

      // Query flats where current user is a resident
      final snapshot = await _firestore
          .collection(flatsCollection)
          .where('residentIds', arrayContains: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return ResidentDataResult.failure(
          message: 'No flat assigned to this user',
          errorCode: 'not-found',
        );
      }

      final flat = FlatModel.fromSnapshot(snapshot.docs.first);
      return ResidentDataResult.success(data: flat);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch flat details: $e',
      );
    }
  }

  /// Stream current user's flat details (real-time updates)
  Stream<FlatModel?> streamMyFlat() {
    final currentUser = _authService.getCurrentUser();

    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(flatsCollection)
        .where('residentIds', arrayContains: currentUser.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return FlatModel.fromSnapshot(snapshot.docs.first);
          }
          return null;
        });
  }

  // ============================================================================
  // BILLS
  // ============================================================================

  /// Get all bills for current user's flat
  Future<ResidentDataResult<List<BillModel>>> getMyBills({
    String? status,
    int? limit,
  }) async {
    try {
      // First get the user's flat
      final flatResult = await getMyFlat();

      if (!flatResult.success || flatResult.data == null) {
        return ResidentDataResult.failure(
          message: 'Unable to fetch bills: ${flatResult.message}',
        );
      }

      final flatId = flatResult.data!.id;

      // Query bills for this flat
      Query query = _firestore
          .collection(billsCollection)
          .where('flatId', isEqualTo: flatId)
          .orderBy('dueDate', descending: true);

      // Filter by status if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Limit results if specified
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final bills = snapshot.docs
          .map((doc) => BillModel.fromSnapshot(doc))
          .toList();

      return ResidentDataResult.success(data: bills);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(message: 'Failed to fetch bills: $e');
    }
  }

  /// Get pending bills for current user's flat
  Future<ResidentDataResult<List<BillModel>>> getMyPendingBills() async {
    return await getMyBills(status: 'pending');
  }

  /// Get paid bills for current user's flat
  Future<ResidentDataResult<List<BillModel>>> getMyPaidBills({
    int? limit,
  }) async {
    return await getMyBills(status: 'paid', limit: limit);
  }

  /// Stream bills for current user's flat (real-time updates)
  Stream<List<BillModel>> streamMyBills({String? status}) async* {
    final flatResult = await getMyFlat();

    if (!flatResult.success || flatResult.data == null) {
      yield [];
      return;
    }

    final flatId = flatResult.data!.id;

    Query query = _firestore
        .collection(billsCollection)
        .where('flatId', isEqualTo: flatId)
        .orderBy('dueDate', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    yield* query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BillModel.fromSnapshot(doc)).toList();
    });
  }

  /// Get total pending amount
  Future<ResidentDataResult<double>> getMyTotalPendingAmount() async {
    try {
      final billsResult = await getMyPendingBills();

      if (!billsResult.success) {
        return ResidentDataResult.failure(
          message: billsResult.message ?? 'Failed to calculate pending amount',
        );
      }

      final total =
          billsResult.data?.fold<double>(0, (sum, bill) => sum + bill.amount) ??
          0;

      return ResidentDataResult.success(data: total);
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to calculate pending amount: $e',
      );
    }
  }

  // ============================================================================
  // PAYMENTS
  // ============================================================================

  /// Get all payments for current user's flat
  Future<ResidentDataResult<List<PaymentModel>>> getMyPayments({
    int? limit,
  }) async {
    try {
      final flatResult = await getMyFlat();

      if (!flatResult.success || flatResult.data == null) {
        return ResidentDataResult.failure(
          message: 'Unable to fetch payments: ${flatResult.message}',
        );
      }

      final flatId = flatResult.data!.id;

      Query query = _firestore
          .collection(paymentsCollection)
          .where('flatId', isEqualTo: flatId)
          .orderBy('paymentDate', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromSnapshot(doc))
          .toList();

      return ResidentDataResult.success(data: payments);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch payments: $e',
      );
    }
  }

  /// Get recent payments (last 10)
  Future<ResidentDataResult<List<PaymentModel>>> getMyRecentPayments() async {
    return await getMyPayments(limit: 10);
  }

  /// Stream payments for current user's flat (real-time updates)
  Stream<List<PaymentModel>> streamMyPayments() async* {
    final flatResult = await getMyFlat();

    if (!flatResult.success || flatResult.data == null) {
      yield [];
      return;
    }

    final flatId = flatResult.data!.id;

    yield* _firestore
        .collection(paymentsCollection)
        .where('flatId', isEqualTo: flatId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentModel.fromSnapshot(doc))
              .toList();
        });
  }

  /// Get payment history for a specific bill
  Future<ResidentDataResult<List<PaymentModel>>> getPaymentsForBill(
    String billId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(paymentsCollection)
          .where('billId', isEqualTo: billId)
          .orderBy('paymentDate', descending: true)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromSnapshot(doc))
          .toList();

      return ResidentDataResult.success(data: payments);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch payment history: $e',
      );
    }
  }

  // ============================================================================
  // VISITORS
  // ============================================================================

  /// Get all visitors for current user's flat
  Future<ResidentDataResult<List<VisitorModel>>> getMyVisitors({
    String? status,
    int? limit,
  }) async {
    try {
      final flatResult = await getMyFlat();

      if (!flatResult.success || flatResult.data == null) {
        return ResidentDataResult.failure(
          message: 'Unable to fetch visitors: ${flatResult.message}',
        );
      }

      final flatId = flatResult.data!.id;

      Query query = _firestore
          .collection(visitorsCollection)
          .where('flatId', isEqualTo: flatId)
          .orderBy('expectedArrival', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final visitors = snapshot.docs
          .map((doc) => VisitorModel.fromSnapshot(doc))
          .toList();

      return ResidentDataResult.success(data: visitors);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch visitors: $e',
      );
    }
  }

  /// Get expected visitors
  Future<ResidentDataResult<List<VisitorModel>>> getMyExpectedVisitors() async {
    return await getMyVisitors(status: 'expected');
  }

  /// Get recent visitors (last 20)
  Future<ResidentDataResult<List<VisitorModel>>> getMyRecentVisitors() async {
    return await getMyVisitors(limit: 20);
  }

  /// Stream visitors for current user's flat (real-time updates)
  Stream<List<VisitorModel>> streamMyVisitors({String? status}) async* {
    final flatResult = await getMyFlat();

    if (!flatResult.success || flatResult.data == null) {
      yield [];
      return;
    }

    final flatId = flatResult.data!.id;

    Query query = _firestore
        .collection(visitorsCollection)
        .where('flatId', isEqualTo: flatId)
        .orderBy('expectedArrival', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    yield* query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VisitorModel.fromSnapshot(doc))
          .toList();
    });
  }

  // ============================================================================
  // NOTICES
  // ============================================================================

  /// Get all active notices
  Future<ResidentDataResult<List<NoticeModel>>> getActiveNotices({
    int? limit,
  }) async {
    try {
      final flatResult = await getMyFlat();

      Query query = _firestore
          .collection(noticesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('publishDate', descending: true);

      // Filter by target flats if user has a flat
      if (flatResult.success && flatResult.data != null) {
        final flatId = flatResult.data!.id;
        // Get notices that target all flats or specifically this flat
        query = query.where(
          'targetFlats',
          whereIn: [
            [],
            [flatId],
          ],
        );
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final notices = snapshot.docs
          .map((doc) => NoticeModel.fromSnapshot(doc))
          .toList();

      return ResidentDataResult.success(data: notices);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(message: 'Failed to fetch notices: $e');
    }
  }

  /// Get recent notices (last 10)
  Future<ResidentDataResult<List<NoticeModel>>> getRecentNotices() async {
    return await getActiveNotices(limit: 10);
  }

  /// Get urgent notices
  Future<ResidentDataResult<List<NoticeModel>>> getUrgentNotices() async {
    try {
      final snapshot = await _firestore
          .collection(noticesCollection)
          .where('isActive', isEqualTo: true)
          .where('priority', isEqualTo: 'high')
          .orderBy('publishDate', descending: true)
          .limit(5)
          .get();

      final notices = snapshot.docs
          .map((doc) => NoticeModel.fromSnapshot(doc))
          .toList();

      return ResidentDataResult.success(data: notices);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch urgent notices: $e',
      );
    }
  }

  /// Stream active notices (real-time updates)
  Stream<List<NoticeModel>> streamActiveNotices() {
    return _firestore
        .collection(noticesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('publishDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NoticeModel.fromSnapshot(doc))
              .toList();
        });
  }

  // ============================================================================
  // COMPLAINTS
  // ============================================================================

  /// Get all complaints owned by the current resident in their community.
  Future<ResidentDataResult<List<ComplaintModel>>> getMyComplaints({
    String? status,
    int? limit,
  }) async {
    try {
      final currentUser = _authService.getCurrentUser();
      final profileResult = await getMyProfile();
      if (currentUser == null ||
          !profileResult.success ||
          profileResult.data == null ||
          profileResult.data!.communityId.trim().isEmpty) {
        return ResidentDataResult.failure(
          message: 'Unable to resolve the resident complaint scope.',
        );
      }

      final communityId = profileResult.data!.communityId.trim();

      Query query = _firestore
          .collection(complaintsCollection)
          .where('communityId', isEqualTo: communityId)
          .where('userId', isEqualTo: currentUser.uid);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      var complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromSnapshot(doc))
          .toList();
      complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (limit != null && complaints.length > limit) {
        complaints = complaints.take(limit).toList();
      }

      return ResidentDataResult.success(data: complaints);
    } on FirebaseException catch (e) {
      return ResidentDataResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch complaints: $e',
      );
    }
  }

  /// Get open complaints
  Future<ResidentDataResult<List<ComplaintModel>>> getMyOpenComplaints() async {
    return await getMyComplaints(status: 'open');
  }

  /// Get resolved complaints
  Future<ResidentDataResult<List<ComplaintModel>>> getMyResolvedComplaints({
    int? limit,
  }) async {
    return await getMyComplaints(status: 'resolved', limit: limit);
  }

  /// Stream complaints owned by the current resident in their community.
  Stream<List<ComplaintModel>> streamMyComplaints({String? status}) async* {
    final currentUser = _authService.getCurrentUser();
    final profileResult = await getMyProfile();
    if (currentUser == null ||
        !profileResult.success ||
        profileResult.data == null ||
        profileResult.data!.communityId.trim().isEmpty) {
      yield [];
      return;
    }

    final communityId = profileResult.data!.communityId.trim();

    Query query = _firestore
        .collection(complaintsCollection)
        .where('communityId', isEqualTo: communityId)
        .where('userId', isEqualTo: currentUser.uid);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    yield* query.snapshots().map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromSnapshot(doc))
          .toList();
      complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return complaints;
    });
  }

  // ============================================================================
  // DASHBOARD SUMMARY
  // ============================================================================

  /// Get dashboard summary data
  Future<ResidentDataResult<DashboardSummary>> getDashboardSummary() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        getMyPendingBills(),
        getMyExpectedVisitors(),
        getMyOpenComplaints(),
        getRecentNotices(),
      ]);

      final pendingBills = results[0] as ResidentDataResult<List<BillModel>>;
      final expectedVisitors =
          results[1] as ResidentDataResult<List<VisitorModel>>;
      final openComplaints =
          results[2] as ResidentDataResult<List<ComplaintModel>>;
      final recentNotices = results[3] as ResidentDataResult<List<NoticeModel>>;

      final summary = DashboardSummary(
        pendingBillsCount: pendingBills.data?.length ?? 0,
        totalPendingAmount:
            pendingBills.data?.fold<double>(
              0,
              (sum, bill) => sum + bill.amount,
            ) ??
            0,
        expectedVisitorsCount: expectedVisitors.data?.length ?? 0,
        openComplaintsCount: openComplaints.data?.length ?? 0,
        unreadNoticesCount: recentNotices.data?.length ?? 0,
      );

      return ResidentDataResult.success(data: summary);
    } catch (e) {
      return ResidentDataResult.failure(
        message: 'Failed to fetch dashboard summary: $e',
      );
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get user-friendly error message
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'You don\'t have permission to access this data';
      case 'not-found':
        return 'The requested data was not found';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again';
      case 'not-authenticated':
        return 'Please sign in to access this data';
      default:
        return 'An error occurred. Please try again';
    }
  }
}

/// Dashboard summary data class
class DashboardSummary {
  final int pendingBillsCount;
  final double totalPendingAmount;
  final int expectedVisitorsCount;
  final int openComplaintsCount;
  final int unreadNoticesCount;

  DashboardSummary({
    required this.pendingBillsCount,
    required this.totalPendingAmount,
    required this.expectedVisitorsCount,
    required this.openComplaintsCount,
    required this.unreadNoticesCount,
  });

  bool get hasAlerts =>
      pendingBillsCount > 0 ||
      expectedVisitorsCount > 0 ||
      openComplaintsCount > 0 ||
      unreadNoticesCount > 0;
}
