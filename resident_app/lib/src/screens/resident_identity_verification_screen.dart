import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../services/resident_auth_routing.dart';
import '../services/resident_identity_service.dart';
import '../services/tenant_resolution_service.dart';

class ResidentIdentityVerificationScreen extends StatefulWidget {
  const ResidentIdentityVerificationScreen({super.key});

  @override
  State<ResidentIdentityVerificationScreen> createState() =>
      _ResidentIdentityVerificationScreenState();
}

class _ResidentIdentityVerificationScreenState
    extends State<ResidentIdentityVerificationScreen> {
  final _service = ResidentIdentityService();
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _upload() async {
    final proof = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (proof == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await _service.upload(proof);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity proof submitted for review.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _checkAccess() async {
    final result = await FirebaseAuthService().restoreResidentSession(
      context.read<TenantResolutionService>(),
    );
    if (mounted) ResidentAuthRouting.navigateToResult(context, result);
  }

  Future<void> _logout() async {
    await FirebaseAuthService().signOut(
      context.read<TenantResolutionService>(),
    );
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Identity Verification')),
    body: StreamBuilder<Map<String, dynamic>>(
      stream: _service.watchProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const <String, dynamic>{};
        final status =
            profile['identityVerificationStatus']?.toString() ??
            'verification_required';
        final type =
            (profile['residentType'] ??
                    profile['ownershipType'] ??
                    profile['declaredResidentType'])
                ?.toString()
                .toLowerCase();
        final rejected = status == 'rejected';
        final canUpload =
            snapshot.hasData &&
            ResidentIdentityService.canUploadForStatus(status);
        return ListView(
          padding: EdgeInsets.all(24.w),
          children: [
            Icon(
              Icons.badge_outlined,
              size: 72.w,
              color: const Color(0xFF0E4778),
            ),
            SizedBox(height: 20.h),
            Text(
              type == 'tenant'
                  ? 'Tenant identity verification is required'
                  : 'Identity verification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12.h),
            Text(_message(status), textAlign: TextAlign.center),
            if (rejected &&
                profile['identityVerificationRejectionReason'] != null) ...[
              SizedBox(height: 12.h),
              Text(
                'Admin note: ${profile['identityVerificationRejectionReason']}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 28.h),
            if (canUpload)
              FilledButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  _uploading
                      ? 'Uploading…'
                      : status == 'verification_required'
                      ? 'Upload identity proof'
                      : 'Upload a new proof',
                ),
              ),
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: _checkAccess,
              child: const Text('Check verification status'),
            ),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Contact your community administrator for support.',
                  ),
                ),
              ),
              child: const Text('Contact Admin / Support'),
            ),
            TextButton(onPressed: _logout, child: const Text('Logout')),
          ],
        );
      },
    ),
  );

  String _message(String status) => switch (status) {
    'pending' =>
      'Your identity proof is awaiting Admin review. Resident features remain restricted.',
    'verified' => 'Your identity proof is verified. Check access to continue.',
    'rejected' =>
      'Your identity proof was rejected. You may upload a new proof.',
    _ =>
      'Upload a clear JPEG or PNG image of an accepted identity document. Resident features remain restricted until verification is complete.',
  };
}
