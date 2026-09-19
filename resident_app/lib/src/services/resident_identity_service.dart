import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ResidentIdentityService {
  ResidentIdentityService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static bool canUploadForStatus(Object? status) =>
      status?.toString().trim().toLowerCase() != 'verified';

  Stream<Map<String, dynamic>> watchProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const {});
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? const {});
  }

  Future<void> upload(XFile proof) async {
    final bytes = await proof.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('Identity proof must be no larger than 5 MB.');
    }
    final lowerName = proof.name.toLowerCase();
    final contentType =
        proof.mimeType ??
        (lowerName.endsWith('.png') ? 'image/png' : 'image/jpeg');
    if (contentType != 'image/jpeg' && contentType != 'image/png') {
      throw StateError('Choose a JPEG or PNG identity proof.');
    }
    await _functions.httpsCallable('submitResidentIdentityProof').call({
      'contentType': contentType,
      'base64': base64Encode(bytes),
    });
  }
}
