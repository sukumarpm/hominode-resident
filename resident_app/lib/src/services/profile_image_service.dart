import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloudinary_service.dart';
import 'image_upload_flow_function.dart';

/// Result class for profile image operations (Flow Function Pattern)
class ProfileImageResult {
  final bool success;
  final String? message;
  final String? imageUrl;
  final String? errorCode;

  ProfileImageResult({
    required this.success,
    this.message,
    this.imageUrl,
    this.errorCode,
  });

  factory ProfileImageResult.success({
    String? message,
    String? imageUrl,
  }) {
    return ProfileImageResult(
      success: true,
      message: message ?? 'Operation successful',
      imageUrl: imageUrl,
    );
  }

  factory ProfileImageResult.failure({
    required String message,
    String? errorCode,
  }) {
    return ProfileImageResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Profile Image Service - Flow Function Pattern
/// Uploads to Cloudinary, stores URL in Firestore, fetches and displays
class ProfileImageService {
  static final ProfileImageService instance =
      ProfileImageService._internal();
  factory ProfileImageService() => instance;
  ProfileImageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // UPLOAD IMAGE - CLOUDINARY + FIRESTORE
  // ============================================================================

  /// Upload image to Cloudinary and save URL to Firestore (Real data only)
  /// Following the flow function pattern
  Future<ProfileImageResult> uploadProfileImage({
    required String imagePath,
  }) async {
    try {
      print('🔵 ProfileImageService: Starting profile image upload...');
      print('   Image path: $imagePath');
      print('   Cloudinary cloud name: de8yccofb');

      // Use the image upload flow function
      final flowResult = await ImageUploadFlowFunction.instance.uploadImage(
        imagePath: imagePath,
        folder: 'profile_pictures',
        publicId: null, // Will be auto-generated with user ID
      );

      if (!flowResult.success) {
        print('❌ ProfileImageService: Upload failed: ${flowResult.message}');
        return ProfileImageResult.failure(
          message: flowResult.message ?? 'Upload failed',
          errorCode: flowResult.errorCode,
        );
      }

      print('✅ ProfileImageService: Upload successful');
      print('   Image URL: ${flowResult.imageUrl}');
      print('   URL stored in Firestore: profileImage, profileImageUrl');
      print('   Timestamp stored: profileImageUpdatedAt');

      return ProfileImageResult.success(
        message: 'Profile image uploaded successfully to Cloudinary and stored in Firestore',
        imageUrl: flowResult.imageUrl,
      );
    } catch (e, stackTrace) {
      print('❌ ProfileImageService: Error: $e');
      print('   Stack trace: $stackTrace');
      return ProfileImageResult.failure(
        message: 'Failed to upload image: $e',
        errorCode: 'UPLOAD_ERROR',
      );
    }
  }

  // ============================================================================
  // FETCH IMAGE FROM FIRESTORE
  // ============================================================================

  /// Fetch image URL from Firestore (Real data only)
  /// Following the flow function pattern
  Future<ProfileImageResult> fetchProfileImage({
    required String userId,
  }) async {
    try {
      print('🔵 Fetching profile image from Firestore...');
      print('📁 User ID: $userId');

      // Get document from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        print('❌ User document not found in Firestore');
        print('   Collection: users');
        print('   Document ID: $userId');
        return ProfileImageResult.failure(
          message: 'User document not found in Firestore',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      print('✅ User document found');

      // Get image URL from Firestore (real data only)
      final data = doc.data();
      
      if (data == null) {
        print('❌ User document has no data');
        return ProfileImageResult.failure(
          message: 'User document has no data',
          errorCode: 'NO_DATA',
        );
      }

      // Check for profileImage or profileImageUrl fields
      final imageUrl = data['profileImage'] as String? ?? data['profileImageUrl'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        print('⚠️ No image URL found in Firestore');
        print('   Available fields: ${data.keys.toList()}');
        return ProfileImageResult.failure(
          message: 'No image URL found in user document',
          errorCode: 'IMAGE_NOT_FOUND',
        );
      }

      print('✅ Image URL fetched from Firestore');
      print('   Field: profileImage or profileImageUrl');
      print('   URL: $imageUrl');
      print('   URL length: ${imageUrl.length}');
      print('   Valid HTTPS: ${imageUrl.startsWith('https')}');

      return ProfileImageResult.success(
        message: 'Image fetched successfully from Firestore',
        imageUrl: imageUrl,
      );
    } catch (e, stackTrace) {
      print('❌ Fetch error: $e');
      print('   Stack trace: $stackTrace');
      return ProfileImageResult.failure(
        message: 'Failed to fetch image from Firestore: $e',
        errorCode: 'FETCH_ERROR',
      );
    }
  }

  // ============================================================================
  // STREAM IMAGE FROM FIRESTORE (Real-time)
  // ============================================================================

  /// Stream image URL from Firestore in real-time (Real data only)
  /// Following the flow function pattern
  /// Includes cache-busting to ensure fresh images are displayed
  Stream<ProfileImageResult> streamProfileImage({
    required String userId,
  }) {
    print('🔵 Setting up profile image stream...');
    print('📁 User ID: $userId');
    print('   Collection: users');
    print('   Document ID: $userId');

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      try {
        if (!doc.exists) {
          print('❌ User document not found in stream');
          return ProfileImageResult.failure(
            message: 'User document not found',
            errorCode: 'USER_NOT_FOUND',
          );
        }

        print('✅ User document received from stream');

        final data = doc.data();
        
        if (data == null) {
          print('❌ User document has no data');
          return ProfileImageResult.failure(
            message: 'User document has no data',
            errorCode: 'NO_DATA',
          );
        }

        // Get image URL from Firestore (real data only)
        var imageUrl = data['profileImage'] as String? ?? data['profileImageUrl'] as String?;

        if (imageUrl == null || imageUrl.isEmpty) {
          print('⚠️ No image URL in stream');
          print('   Available fields: ${data.keys.toList()}');
          return ProfileImageResult.failure(
            message: 'No image found in user document',
            errorCode: 'IMAGE_NOT_FOUND',
          );
        }

        print('✅ Image URL received from stream');
        print('   Field: profileImage or profileImageUrl');
        print('   URL: $imageUrl');

        // Add cache-busting parameter to force fresh image load
        // This ensures that when the same URL is used for a new image,
        // the browser/app doesn't serve the cached version
        final timestamp = data['profileImageUpdatedAt'];
        if (timestamp != null) {
          final cacheBuster = timestamp.toString().hashCode.abs();
          imageUrl = '$imageUrl?v=$cacheBuster';
          print('   ✅ Cache-buster added: v=$cacheBuster');
        } else {
          print('   ⚠️ No timestamp for cache-busting');
        }

        print('   Final URL: $imageUrl');
        return ProfileImageResult.success(
          message: 'Image received from stream',
          imageUrl: imageUrl,
        );
      } catch (e, stackTrace) {
        print('❌ Stream error: $e');
        print('   Stack trace: $stackTrace');
        return ProfileImageResult.failure(
          message: 'Stream error: $e',
          errorCode: 'STREAM_ERROR',
        );
      }
    });
  }

  // ============================================================================
  // DELETE IMAGE
  // ============================================================================

  /// Delete image from Cloudinary and Firestore
  /// Following the flow function pattern
  Future<ProfileImageResult> deleteProfileImage({
    required String userId,
    required String publicId,
  }) async {
    try {
      print('🔵 Deleting profile image...');
      print('📁 User ID: $userId');

      // Delete from Cloudinary
      print('🗑️ Deleting from Cloudinary...');
      await CloudinaryService.deleteImage(publicId);
      print('✅ Deleted from Cloudinary');

      // Delete from Firestore
      print('🗑️ Deleting from Firestore...');
      await _firestore.collection('users').doc(userId).update({
        'profileImage': FieldValue.delete(),
        'profileImageUrl': FieldValue.delete(),
        'profileImageUpdatedAt': FieldValue.delete(),
      });
      print('✅ Deleted from Firestore');

      return ProfileImageResult.success(
        message: 'Image deleted successfully',
      );
    } catch (e) {
      print('❌ Delete error: $e');
      return ProfileImageResult.failure(
        message: 'Failed to delete image: $e',
        errorCode: 'DELETE_ERROR',
      );
    }
  }

  // ============================================================================
  // FORCE REFRESH - Cache Invalidation
  // ============================================================================

  /// Force refresh profile image by updating the timestamp in Firestore
  /// This triggers the stream to emit a new event with cache-busting parameters
  /// Useful after uploading a new image to ensure the latest version is displayed
  Future<ProfileImageResult> forceRefreshProfileImage({
    required String userId,
  }) async {
    try {
      print('🔵 Force refreshing profile image...');
      print('📁 User ID: $userId');

      // Update the timestamp to trigger stream update with new cache-buster
      await _firestore.collection('users').doc(userId).update({
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Profile image cache invalidated');
      print('   Stream will emit new event with updated cache-buster');

      return ProfileImageResult.success(
        message: 'Profile image cache invalidated',
      );
    } catch (e) {
      print('❌ Force refresh error: $e');
      return ProfileImageResult.failure(
        message: 'Failed to refresh image cache: $e',
        errorCode: 'REFRESH_ERROR',
      );
    }
  }
}
