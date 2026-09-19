import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class SubmitPaymentProofScreen extends StatefulWidget {
  final Map<String, dynamic> bill;

  const SubmitPaymentProofScreen({super.key, required this.bill});

  @override
  State<SubmitPaymentProofScreen> createState() =>
      _SubmitPaymentProofScreenState();
}

class _SubmitPaymentProofScreenState extends State<SubmitPaymentProofScreen> {
  final _referenceController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _receiptImage;
  bool _isSubmitting = false;

  static const Color _primaryBlue = Color(0xFF0E4778);

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (image == null || !mounted) return;

      setState(() {
        _receiptImage = image;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to select receipt: $e')));
    }
  }

  Future<void> _chooseReceiptSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickReceipt(source);
    }
  }

  Future<void> _submitPaymentProof() async {
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in again.');
      return;
    }

    if (_receiptImage == null) {
      _showMessage('Please attach your payment receipt.');
      return;
    }

    final billId = widget.bill['id']?.toString() ?? '';
    final communityId = widget.bill['communityId']?.toString() ?? '';
    final flatId = widget.bill['flatId']?.toString() ?? '';
    final amount = (widget.bill['amount'] as num?)?.toDouble() ?? 0;

    if (billId.isEmpty ||
        communityId.isEmpty ||
        flatId.isEmpty ||
        amount <= 0) {
      _showMessage('Bill information is incomplete.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Reference? uploadedReceiptRef;

    try {
      final paymentRef = FirebaseFirestore.instance
          .collection('payments')
          .doc();

      final extension = _fileExtension(_receiptImage!.path);

      final storagePath =
          'payment_receipts/'
          '$communityId/'
          '$billId/'
          '${user.uid}/'
          '${paymentRef.id}.$extension';

      uploadedReceiptRef = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: _contentType(extension),
        customMetadata: {
          'paymentId': paymentRef.id,
          'billId': billId,
          'communityId': communityId,
          'residentUid': user.uid,
        },
      );

      await uploadedReceiptRef.putFile(File(_receiptImage!.path), metadata);

      final now = Timestamp.now();

      final paymentData = <String, dynamic>{
        'id': paymentRef.id,
        'communityId': communityId,
        'billId': billId,
        'flatId': flatId,
        'userId': user.uid,
        'amount': amount,
        'method': 'external',
        'status': 'pending',
        'transactionId': _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        'receiptPath': storagePath,
        'paymentDate': now,
        'createdAt': now,
        'updatedAt': now,
      };

      print('💳 PAYMENT SUBMISSION DATA: $paymentData');

      await paymentRef.set(paymentData);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      // Avoid leaving an orphan receipt if Firestore creation fails.
      if (uploadedReceiptRef != null) {
        try {
          await uploadedReceiptRef.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      _showMessage('Payment proof could not be submitted: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _fileExtension(String path) {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return 'png';
      case 'heic':
        return 'heic';
      case 'heif':
        return 'heif';
      default:
        return 'jpg';
    }
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.bill['amount'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Payment Proof'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount Due',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w700,
                      color: _primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'Transaction / Reference No.',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),

            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'Optional',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              'Payment Receipt',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 10.h),

            InkWell(
              onTap: _isSubmitting ? null : _chooseReceiptSource,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: double.infinity,
                height: 180.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _receiptImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 42.w,
                            color: _primaryBlue,
                          ),
                          SizedBox(height: 10.h),
                          const Text('Take photo or choose from gallery'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.file(
                          File(_receiptImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 12.h),

            if (_receiptImage != null)
              TextButton.icon(
                onPressed: _isSubmitting ? null : _chooseReceiptSource,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Receipt'),
              ),

            SizedBox(height: 28.h),

            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPaymentProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit for Verification'),
              ),
            ),

            SizedBox(height: 14.h),

            const Text(
              'Your bill will remain pending until the payment is verified by your community administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
