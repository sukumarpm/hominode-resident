// lib/src/services/resident_login_service.dart
// Resident Login Service - Handles login validation and resident access checks

// lib/src/services/resident_login_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ResidentLoginFailureReason {
  userNotFound,
  invalidPassword,
  authenticationFailed,
  roleNotConfigured,
  notResident,
  accountInactive,
  noFlatAssignment,
  configurationError,
  unknown,
}

class ResidentLoginResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? userData;
  final String? flatId;
  final String? buildingId;

  /// IMPORTANT:
  /// Used by UI/navigation to determine what kind of failure occurred.
  final ResidentLoginFailureReason? failureReason;

  const ResidentLoginResult({
    required this.success,
    this.message,
    this.userData,
    this.flatId,
    this.buildingId,
    this.failureReason,
  });

  factory ResidentLoginResult.success({
    required Map<String, dynamic> userData,
    required String flatId,
    required String buildingId,
  }) {
    return ResidentLoginResult(
      success: true,
      message: 'Login successful',
      userData: userData,
      flatId: flatId,
      buildingId: buildingId,
      failureReason: null,
    );
  }

  factory ResidentLoginResult.failure({
    required String message,
    required ResidentLoginFailureReason reason,
  }) {
    return ResidentLoginResult(
      success: false,
      message: message,
      failureReason: reason,
    );
  }
}

/// Resident Login Service
/// Validates login credentials and resident access
class ResidentLoginService {
  // Singleton pattern
  static final ResidentLoginService instance = ResidentLoginService._internal();
  factory ResidentLoginService() => instance;
  ResidentLoginService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Login with email/phone and password, then validate resident access
  ///
  /// This method:
  /// 1. Validates credentials directly from Firestore
  /// 2. Fetches user document from Firestore
  /// 3. Validates resident role and flat assignment
  /// 4. Returns user data with flat information
  Future<ResidentLoginResult> loginAsResident({
    required String identifier,
    required String password,
  }) async {
    try {
      print('🔵 ResidentLoginService: Starting resident login...');
      print('   Identifier: $identifier');

      // Step 1: Find user in Firestore and validate password
      print('🔐 Step 1: Validating credentials in Firestore...');

      String loginEmail = identifier.trim();
      QuerySnapshot userQuerySnapshot;

      // Check if identifier is phone number
      final isPhone = RegExp(r'^[\d+\s()-]+$').hasMatch(loginEmail);

      if (isPhone) {
        print('📱 Phone number detected, looking up user in Firestore...');

        // Clean phone number
        String cleanPhone = loginEmail.replaceAll(RegExp(r'[\s()-]'), '');

        // Remove country code if present
        if (cleanPhone.startsWith('+91')) {
          cleanPhone = cleanPhone.substring(3);
        } else if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
          cleanPhone = cleanPhone.substring(2);
        }

        print('   Searching for phone: $cleanPhone');

        // Try multiple phone format variations
        final phoneVariations = [cleanPhone, '+91$cleanPhone', '91$cleanPhone'];

        QuerySnapshot? foundQuery;

        for (var phoneVar in phoneVariations) {
          print('   Trying: $phoneVar');
          final query = await _firestore
              .collection('users')
              .where('phone', isEqualTo: phoneVar)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            foundQuery = query;
            print('   ✅ Found user with phone: $phoneVar');
            break;
          }
        }

        if (foundQuery == null || foundQuery.docs.isEmpty) {
          print('❌ No user found with phone: $cleanPhone');
          return ResidentLoginResult.failure(
            message: 'No account found with this phone number',
          );
        }

        userQuerySnapshot = foundQuery;

        // Get email from Firestore
        final userData = foundQuery.docs.first.data() as Map<String, dynamic>;
        loginEmail = userData['email'] as String;
        print('✅ Found user with phone: $loginEmail');
      } else {
        print('📧 Email detected, searching in Firestore...');
        print('   Searching for email: $loginEmail');

        // Search by email
        userQuerySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: loginEmail)
            .limit(1)
            .get();

        if (userQuerySnapshot.docs.isEmpty) {
          print('❌ No user found with email: $loginEmail');
          return ResidentLoginResult.failure(
            message: 'No account found with this email',
          );
        }

        print('✅ Found user with email: $loginEmail');
      }

      // Get user document
      final userDoc = userQuerySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;

      print('✅ User document found');
      print('   Document ID: ${userDoc.id}');
      print('   Name: ${userData['name']}');
      print('   Email: ${userData['email']}');
      print('   Role: ${userData['role']}');
      print('   Status: ${userData['status']}');
      print('   FlatId: ${userData['flatId']}');
      print('   BuildingId: ${userData['buildingId']}');

      // Verify password
      print('🔐 Step 2: Verifying password...');

      if (!userData.containsKey('password')) {
        print('❌ Password field not found in user document');
        return ResidentLoginResult.failure(
          message: 'Account configuration error. Please contact support.',
        );
      }

      final storedPassword = userData['password'] as String;

      if (storedPassword != password) {
        print('❌ Password mismatch');
        return ResidentLoginResult.failure(
          message: 'Invalid email or password',
        );
      }

      print('✅ Password verified successfully');

      // Step 3: Sync with Firebase Auth (REQUIRED for Firestore rules)
      print('🔐 Step 3: Syncing with Firebase Auth...');

      try {
        UserCredential? userCredential;
        String? firebaseUid;

        try {
          // Try to sign in with Firebase Auth
          userCredential = await _auth.signInWithEmailAndPassword(
            email: loginEmail,
            password: password,
          );
          firebaseUid = userCredential.user!.uid;
          print('✅ Firebase Auth sign-in successful');
          print('   Firebase UID: $firebaseUid');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            // Create Firebase Auth user
            print('⚠️  User not in Firebase Auth, creating account...');
            try {
              userCredential = await _auth.createUserWithEmailAndPassword(
                email: loginEmail,
                password: password,
              );
              firebaseUid = userCredential.user!.uid;
              print('✅ Firebase Auth account created');
              print('   Firebase UID: $firebaseUid');
            } catch (createError) {
              print('❌ Could not create Firebase Auth account: $createError');
              return ResidentLoginResult.failure(
                message: 'Authentication setup failed. Please try again.',
              );
            }
          } else {
            print('❌ Firebase Auth error: ${e.code}');
            return ResidentLoginResult.failure(
              message: 'Authentication failed. Please try again.',
            );
          }
        }

        // CRITICAL: Update Firestore user document with Firebase UID
        // This is required for Firestore rules to work
        print('📝 Updating Firestore user document with Firebase UID...');

        // Update the user document with the Firebase UID
        await _firestore.collection('users').doc(userDoc.id).update({
          'uid': firebaseUid,
          'authUid': firebaseUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Firestore user document updated with Firebase UID');
        print('   Document ID: ${userDoc.id}');
        print('   Firebase UID: $firebaseUid');

        // Update userData with the new UID
        userData['uid'] = firebaseUid;
        userData['authUid'] = firebaseUid;
      } catch (e) {
        print('❌ Firebase Auth sync failed: $e');
        return ResidentLoginResult.failure(
          message: 'Authentication failed. Please try again.',
        );
      }

      // Step 4: Validate resident role
      print('🔐 Step 4: Validating resident role...');

      final role = userData['role'] as String?;
      if (role == null || role.isEmpty) {
        print('❌ No role assigned to user');
        return ResidentLoginResult.failure(
          message: 'User role not configured. Please contact support.',
        );
      }

      if (role != 'resident') {
        print('❌ User is not a resident: $role');
        return ResidentLoginResult.failure(
          message: 'Access denied. Only residents can login here.',
        );
      }

      print('✅ User is a resident');

      // Step 5: Validate account status
      print('🔐 Step 5: Validating account status...');

      final status = userData['status'] as String?;
      if (status != null && status.isNotEmpty && status != 'active') {
        print('❌ Account is not active: $status');
        return ResidentLoginResult.failure(
          message: 'Your account is $status. Please contact support.',
        );
      }

      print('✅ Account is active');

      // Step 6: Validate flat assignment
      print('🔐 Step 6: Validating flat assignment...');

      final flatIdValue = userData['flatId'];
      String? flatId;

      if (flatIdValue != null) {
        flatId = flatIdValue.toString().trim();
        if (flatId.isEmpty) {
          flatId = null;
        }
      }

      if (flatId == null || flatId.isEmpty) {
        print('❌ No flat assigned to user');
        return ResidentLoginResult.failure(
          message:
              'Access Restricted – Your account is not yet assigned to a flat',
        );
      }

      print('✅ User has flat assigned: $flatId');

      // Step 7: Get building ID
      print('🔐 Step 7: Getting building information...');

      final buildingIdValue = userData['buildingId'];
      String buildingId = '';

      if (buildingIdValue != null) {
        buildingId = buildingIdValue.toString().trim();
      }

      print('✅ Building ID: $buildingId');

      // All validations passed
      print('✅ All validations passed!');
      print('   Resident: ${userData['name']}');
      print('   Flat: $flatId');
      print('   Building: $buildingId');

      return ResidentLoginResult.success(
        userData: userData,
        flatId: flatId,
        buildingId: buildingId,
      );
    } catch (e, stackTrace) {
      print('❌ Unexpected error: $e');
      print('   Stack trace: $stackTrace');
      return ResidentLoginResult.failure(
        message: 'Login failed. Please try again.',
      );
    }
  }

  /// Get user-friendly error message for Firebase Auth errors
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  /// Validate email format
  bool validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validate phone number format
  bool validatePhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length == 10;
  }
}
