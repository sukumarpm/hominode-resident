// lib/src/services/firebase_auth_firestore_service.dart
// Complete Firebase Authentication + Firestore Service

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Result class for authentication operations
class AuthFirestoreResult {
  final bool success;
  final String? message;
  final User? user;
  final String? errorCode;

  AuthFirestoreResult({
    required this.success,
    this.message,
    this.user,
    this.errorCode,
  });

  factory AuthFirestoreResult.success({String? message, User? user}) {
    return AuthFirestoreResult(
      success: true,
      message: message ?? 'Operation successful',
      user: user,
    );
  }

  factory AuthFirestoreResult.failure({required String message, String? errorCode}) {
    return AuthFirestoreResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Firebase Authentication + Firestore Service
/// Handles user registration, login, and profile management
class FirebaseAuthFirestoreService {
  // Singleton pattern
  static final FirebaseAuthFirestoreService instance = FirebaseAuthFirestoreService._internal();
  factory FirebaseAuthFirestoreService() => instance;
  FirebaseAuthFirestoreService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection name
  static const String usersCollection = 'users';

  // ============================================================================
  // REGISTRATION
  // ============================================================================

  /// Register user with email and password, then save to Firestore
  Future<AuthFirestoreResult> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      print('🔵 Starting registration...');
      print('📧 Email: $email');
      print('👤 Name: $name');

      // Step 1: Create Firebase Auth user
      print('🔐 Creating Firebase Auth user...');
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        return AuthFirestoreResult.failure(
          message: 'Failed to create user account',
        );
      }

      print('✅ Firebase Auth user created');
      print('🆔 UID: ${user.uid}');

      // Step 2: Update display name
      await user.updateDisplayName(name);
      print('✅ Display name updated');

      // Step 3: Save user data to Firestore
      print('💾 Saving to Firestore...');
      await _saveUserToFirestore(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
      );

      print('✅ User data saved to Firestore');
      print('🎉 Registration complete!');

      return AuthFirestoreResult.success(
        message: 'Account created successfully',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      return AuthFirestoreResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } on FirebaseException catch (e) {
      print('❌ Firestore Error: ${e.code}');
      return AuthFirestoreResult.failure(
        message: _getFirestoreErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return AuthFirestoreResult.failure(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Save user data to Firestore
  Future<void> _saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
    String? phone,
  }) async {
    final userData = {
      'authUid': uid, // Link to Firebase Auth UID
      'uid': uid, // Keep for backward compatibility
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'resident',
      'flatId': null, // Will be assigned by admin
      'flatLabel': null, // Will be assigned by admin
      'buildingId': null, // Will be assigned by admin
      'profileImage': null,
      'photoURL': null,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    print('📦 User data to save: $userData');

    await _firestore
        .collection(usersCollection)
        .doc(uid)
        .set(userData, SetOptions(merge: true));

    print('✅ Firestore document created at: $usersCollection/$uid');
  }

  // ============================================================================
  // LOGIN
  // ============================================================================

  /// Login with email/phone and password
  /// Accepts either email or phone number as identifier
  Future<AuthFirestoreResult> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Starting login...');
      print('📧 Identifier: $email');

      String loginEmail = email.trim();

      // Check if input is a phone number (contains only digits and +)
      final isPhoneNumber = RegExp(r'^[\d+\s()-]+$').hasMatch(loginEmail);

      if (isPhoneNumber) {
        print('📱 Phone number detected, looking up email...');
        
        // Clean phone number (remove spaces, dashes, parentheses)
        final cleanPhone = loginEmail.replaceAll(RegExp(r'[\s()-]'), '');
        
        // Query Firestore to find user by phone number
        final querySnapshot = await _firestore
            .collection(usersCollection)
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print('❌ No user found with phone number: $cleanPhone');
          return AuthFirestoreResult.failure(
            message: 'No account found with this phone number',
          );
        }

        // Get the email from Firestore
        final userData = querySnapshot.docs.first.data();
        loginEmail = userData['email'] as String;
        print('✅ Found email for phone number: $loginEmail');
      }

      // Now login with email
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        return AuthFirestoreResult.failure(
          message: 'Login failed. Please try again.',
        );
      }

      print('✅ Login successful');
      print('🆔 UID: ${user.uid}');

      // Verify user exists in Firestore
      final userDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print('⚠️ User not found in Firestore, creating profile...');
        // Create profile if it doesn't exist
        await _saveUserToFirestore(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? loginEmail,
          phone: user.phoneNumber,
        );
      } else {
        // Update authUid if missing
        final data = userDoc.data();
        if (data != null && !data.containsKey('authUid')) {
          print('⚠️ authUid missing, updating document...');
          await _firestore
              .collection(usersCollection)
              .doc(user.uid)
              .update({
            'authUid': user.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ authUid added to existing document');
        }
      }

      return AuthFirestoreResult.success(
        message: 'Login successful',
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Login Error: ${e.code}');
      return AuthFirestoreResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return AuthFirestoreResult.failure(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  /// Get current user's profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No current user');
        return null;
      }

      print('🔵 Fetching profile for user: ${user.uid}');
      print('🔵 Querying by authUid field...');
      
      // Query by authUid field instead of document ID
      final querySnapshot = await _firestore
          .collection(usersCollection)
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print('✅ Profile data fetched from document: ${doc.id}');
        
        // Map Firestore fields to expected format
        return {
          'name': data['name'] ?? '',
          'email': data['email'] ?? user.email ?? '',
          'phone': data['phone'] ?? '',
          'flatNumber': data['flatLabel'] ?? data['flatId'] ?? '',
          'profileImage': data['profileImage'] ?? data['photoURL'],
          'role': data['role'] ?? 'resident',
          'flatId': data['flatId'],
          'flatLabel': data['flatLabel'],
          'documentId': doc.id, // Store the actual document ID
        };
      }
      
      print('⚠️ Profile document does not exist for authUid: ${user.uid}');
      return null;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Stream user profile (real-time updates)
  Stream<Map<String, dynamic>?> streamUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    // Query by authUid field instead of document ID
    return _firestore
        .collection(usersCollection)
        .where('authUid', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final data = doc.data();
            // Map Firestore fields to expected format
            return {
              'name': data['name'] ?? '',
              'email': data['email'] ?? user.email ?? '',
              'phone': data['phone'] ?? '',
              'flatNumber': data['flatLabel'] ?? data['flatId'] ?? '',
              'profileImage': data['profileImage'] ?? data['photoURL'],
              'role': data['role'] ?? 'resident',
              'flatId': data['flatId'],
              'flatLabel': data['flatLabel'],
              'documentId': doc.id, // Store the actual document ID
            };
          }
          return null;
        });
  }

  /// Update user profile in Firestore
  Future<AuthFirestoreResult> updateUserProfile({
    String? name,
    String? phone,
    String? photoUrl,
    String? flatNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthFirestoreResult.failure(
          message: 'No user is currently signed in',
        );
      }

      print('🔵 Updating profile for user: ${user.uid}');
      print('🔵 Querying by authUid field...');
      
      // Query by authUid field to find the document
      final querySnapshot = await _firestore
          .collection(usersCollection)
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ No document found with authUid: ${user.uid}');
        return AuthFirestoreResult.failure(
          message: 'User profile not found',
        );
      }

      final docId = querySnapshot.docs.first.id;
      print('✅ Found document ID: $docId');
      
      final updates = <String, dynamic>{};
      
      if (name != null) {
        updates['name'] = name;
        await user.updateDisplayName(name);
        print('✅ Updated name: $name');
      }
      
      if (phone != null) {
        updates['phone'] = phone;
        print('✅ Updated phone: $phone');
      }
      
      if (photoUrl != null) {
        updates['profileImage'] = photoUrl;
        await user.updatePhotoURL(photoUrl);
        print('✅ Updated photo URL');
      }

      if (flatNumber != null) {
        updates['flatLabel'] = flatNumber;
        print('✅ Updated flatLabel: $flatNumber');
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        
        print('💾 Saving updates to Firestore document: $docId');
        
        await _firestore
            .collection(usersCollection)
            .doc(docId)
            .update(updates);
        
        print('✅ Profile updated successfully');
      }

      return AuthFirestoreResult.success(
        message: 'Profile updated successfully',
      );
    } catch (e) {
      print('❌ Error updating profile: $e');
      return AuthFirestoreResult.failure(
        message: 'Failed to update profile: $e',
      );
    }
  }

  // ============================================================================
  // LOGOUT
  // ============================================================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ User signed out');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  // ============================================================================
  // CURRENT USER
  // ============================================================================

  /// Get current Firebase Auth user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Stream auth state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // ============================================================================
  // PASSWORD RESET
  // ============================================================================

  /// Send password reset email
  Future<AuthFirestoreResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthFirestoreResult.success(
        message: 'Password reset email sent',
      );
    } on FirebaseAuthException catch (e) {
      return AuthFirestoreResult.failure(
        message: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      return AuthFirestoreResult.failure(
        message: 'Failed to send password reset email',
      );
    }
  }

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  /// Get user-friendly error message for Firebase Auth errors
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Get user-friendly error message for Firestore errors
  String _getFirestoreErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'Permission denied. Please contact support.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Data not found.';
      case 'already-exists':
        return 'Data already exists.';
      default:
        return 'Database error. Please try again.';
    }
  }
}
