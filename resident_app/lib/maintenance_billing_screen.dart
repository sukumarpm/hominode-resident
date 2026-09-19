import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'payment_history_screen.dart';
import 'receipt_screen.dart';
import 'src/components/standard_screen.dart';
import 'src/providers/language_provider.dart';
import 'src/screens/submit_payment_proof_screen.dart';
import 'src/services/bill_firestore_service.dart';

// Design Constants
const kPrimaryBlue = Color(0xFF0E4778);
const kBackground = Color(0xFFFFFFFF);
const kDivider = Color(0xFFE6E6E6);
const kOrangeStart = Color(0xFFFF7A30);
const kOrangeEnd = Color(0xFFFF4E17);
const kPendingBg = Color(0xFFFFB59E);
const kPendingText = Color(0xFFA33E0C);
const kSuccessBg = Color(0xFFE9FCEB);
const kSuccessIcon = Color(0xFF12B76A);
const kDarkTitle = Color(0xFF111111);
const kSubtext = Color(0xFF7A7A7A);
const kBlackText = Color(0xFF333333);

const kSpacing = 16.0;
const kRadius = 16.0;

/// Maintenance & Billing Screen - Real-time Firestore Integration
class MaintenanceBillingScreen extends StatefulWidget {
  const MaintenanceBillingScreen({super.key});

  @override
  State<MaintenanceBillingScreen> createState() =>
      _MaintenanceBillingScreenState();
}

class _MaintenanceBillingScreenState extends State<MaintenanceBillingScreen> {
  final _billService = BillFirestoreService();

  Widget _buildSubmitPaymentCard(Map<String, dynamic> bill) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: kDarkTitle,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Pay using your community\'s available payment method, then upload the receipt for verification.',
            style: TextStyle(fontSize: 14.sp, height: 1.4, color: kSubtext),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitPaymentProofScreen(bill: bill),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Submit Payment Proof'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRejectedCard(
    Map<String, dynamic> bill,
    Map<String, dynamic> payment,
  ) {
    final reason = payment['rejectionReason']?.toString().trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Rejected',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          if (reason != null && reason.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Reason: $reason',
              style: TextStyle(fontSize: 14.sp, color: kSubtext),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitPaymentProofScreen(bill: bill),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resubmit Payment Proof'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSubmittedCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, color: kPrimaryBlue, size: 28.w),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Submitted',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: kDarkTitle,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Your payment receipt has been submitted and is awaiting administrator verification.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.4,
                    color: kSubtext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAction(Map<String, dynamic> bill) {
    final billId = bill['id']?.toString() ?? '';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _billService.streamLatestPaymentForBill(billId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ PAYMENT STREAM ERROR: ${snapshot.error}');

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: kDivider),
            ),
            child: Text(
              'Unable to load payment status. Please try again.',
              style: TextStyle(fontSize: 14.sp, color: kSubtext),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payment = snapshot.data;
        final paymentStatus = payment?['status']?.toString().toLowerCase();

        if (paymentStatus == 'pending') {
          return _buildPaymentSubmittedCard();
        }

        if (paymentStatus == 'failed' && payment != null) {
          return _buildPaymentRejectedCard(bill, payment);
        }

        return _buildSubmitPaymentCard(bill);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return StandardScreen(
          key: ValueKey(languageProvider.currentLanguageCode),
          title: 'maintenance_billing'.tr(),
          showBackButton: false,
          isScrollable: true,
          padding: const EdgeInsets.all(kSpacing),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _billService.streamBills(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                  ),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.w, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(
                        'error_loading_bills'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final bills = snapshot.data ?? [];

              // Separate pending and paid bills
              final pendingBills = bills
                  .where((bill) => bill['status'] == 'pending')
                  .toList();
              final paidBills = bills
                  .where((bill) => bill['status'] == 'paid')
                  .toList();

              // Get current pending bill (most recent)
              final currentBill = pendingBills.isNotEmpty
                  ? pendingBills.first
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Bill Card
                  if (currentBill != null)
                    _buildCurrentBillCard(currentBill)
                  else
                    _buildNoBillCard(),

                  SizedBox(height: 20.h),

                  // Bill Breakdown Card
                  if (currentBill != null) _buildBillBreakdownCard(currentBill),

                  if (currentBill != null) SizedBox(height: 24.h),
                  if (currentBill != null) _buildPaymentAction(currentBill),

                  if (currentBill != null) SizedBox(height: 24.h),

                  // Payment History Section
                  if (paidBills.isNotEmpty)
                    _buildPaymentHistorySection(paidBills)
                  else if (currentBill == null)
                    _buildNoHistoryCard(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Current Bill Card with orange gradient
  Widget _buildCurrentBillCard(Map<String, dynamic> bill) {
    final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
    final dueDate = (bill['dueDate'] as Timestamp?)?.toDate();
    final status = bill['status'] as String? ?? 'pending';
    final month = bill['month'] as String? ?? 'Current';

    // Format due date
    String dueDateStr = 'Due Date: Not Set';
    if (dueDate != null) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      dueDateStr =
          'Due Date: ${months[dueDate.month - 1]} ${dueDate.day}, ${dueDate.year}';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kOrangeStart, kOrangeEnd],
        ),
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: kOrangeEnd.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Current Bill" and status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month Bill',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: kPendingBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  status == 'pending'
                      ? 'Pending'
                      : status == 'overdue'
                      ? 'Overdue'
                      : 'Paid',
                  style: TextStyle(
                    color: kPendingText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Amount
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          SizedBox(height: 8.h),

          // Due Date
          Text(
            dueDateStr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// No Bill Card
  Widget _buildNoBillCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kDivider, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 64.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Pending Bills',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Bill Breakdown Card
  Widget _buildBillBreakdownCard(Map<String, dynamic> bill) {
    final breakdown = _billService.getBillBreakdown(bill);
    final total = _billService.calculateTotal(breakdown);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kDivider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Bill Breakdown',
            style: TextStyle(
              color: kDarkTitle,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 20.h),

          // Breakdown items - only show non-zero values
          ...breakdown.entries.where((entry) => entry.value > 0).map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildBreakdownItem(
                entry.key,
                '₹${entry.value.toStringAsFixed(0)}',
              ),
            );
          }),

          // Show message if no breakdown available
          if (breakdown.values.every((value) => value == 0))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'No breakdown available',
                style: TextStyle(
                  color: kSubtext,
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Divider
          const Divider(color: kDivider, thickness: 1),

          SizedBox(height: 16.h),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: kSubtext,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual breakdown item
  Widget _buildBreakdownItem(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: kSubtext,
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: kBlackText,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Payment History Section
  Widget _buildPaymentHistorySection(List<Map<String, dynamic>> paidBills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment History',
              style: TextStyle(
                color: kDarkTitle,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        PaymentHistoryScreen(paidBills: paidBills),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Payment history items (show first 3)
        ...paidBills.take(3).map((payment) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildPaymentHistoryItem(payment),
          );
        }),
      ],
    );
  }

  /// No History Card
  Widget _buildNoHistoryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kDivider, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 64.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Payment History',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your payment history will appear here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Individual payment history item
  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    final month = payment['month'] as String? ?? 'Unknown';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final paidAt = (payment['paidAt'] as Timestamp?)?.toDate();
    // Format paid date
    String paidDateStr = 'Paid';
    if (paidAt != null) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      paidDateStr =
          'Paid on ${months[paidAt.month - 1]} ${paidAt.day}, ${paidAt.year}';
    }

    return Builder(
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Success icon
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: kSuccessBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: kSuccessIcon, size: 28.w),
              ),

              SizedBox(width: 12.w),

              // Month and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month,
                      style: TextStyle(
                        color: kDarkTitle,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      paidDateStr,
                      style: TextStyle(
                        color: kSubtext,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount and receipt
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: kDarkTitle,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  InkWell(
                    onTap: () {
                      // Navigate to Receipt Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReceiptScreen(receipt: Receipt.fromBill(payment)),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          color: kPrimaryBlue,
                          size: 16.w,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Receipt',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bottom Navigation Bar

  /// Individual bottom navigation item
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        if (label == 'Home') {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? kPrimaryBlue : const Color(0xFF94A3B8),
              size: 24.w,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isActive ? kPrimaryBlue : const Color(0xFF94A3B8),
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
