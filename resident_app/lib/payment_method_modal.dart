import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'src/services/payment_service.dart';

// ============================================================================
// DESIGN CONSTANTS (matching exact design specs)
// ============================================================================

/// Primary blue color for selected state and accents
const kPrimary = Color(0xFF0E4778);

/// Modal background (white)
const kModalBackground = Color(0xFFFFFFFF);

/// Overlay dim color behind modal
const kOverlayColor = Color(0x5C000000); // rgba(0,0,0,0.36)

/// Card border color (light gray)
const kCardBorder = Color(0xFFE6E6E6);

/// Close icon color
const kCloseIconColor = Color(0xFF9B9B9B);

/// Placeholder/subtitle text color
const kSubtitleColor = Color(0xFFBDBDBD);

/// Card icon background colors (soft pastels)
const kUpiIconBg = Color(0xFFF6EDFF); // soft purple
const kCardIconBg = Color(0xFFEDF6FF); // soft blue
const kBankIconBg = Color(0xFFE9FBF0); // soft green

/// UPI icon color (purple)
const kUpiIconColor = Color(0xFF9333EA);

/// Card icon color (blue)
const kCardIconColor = Color(0xFF0E4778);

/// Bank icon color (green)
const kBankIconColor = Color(0xFF10B981);

/// Modal corner radius (16-20px)
const kModalRadius = 20.0;

/// Card corner radius
const kCardRadius = 16.0;

/// Icon container corner radius
const kIconRadius = 12.0;

/// Card padding (horizontal and vertical)
final kCardPadding = EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h);

/// Spacing between cards
const kCardSpacing = 12.0;

/// Modal horizontal padding
const kModalHorizontalPadding = 24.0;

/// Modal vertical padding
const kModalVerticalPadding = 24.0;

/// Icon container size
const kIconSize = 64.0;

/// Close button size (tappable area)
const kCloseButtonSize = 44.0;

// ============================================================================
// HELPER FUNCTION TO SHOW MODAL
// ============================================================================

/// Shows the payment method selection modal as a centered overlay
///
/// Usage:
/// ```dart
/// showPaymentMethodModal(context, (method) {
///   print('Selected: $method');
///   // Handle payment method selection
/// });
/// ```
Future<void> showPaymentMethodModal(
  BuildContext context,
  Future<void> Function(PaymentMethod) onSelect,
) {
  return showDialog(
    context: context,
    barrierColor: kOverlayColor,
    barrierDismissible: true,
    builder: (context) => PaymentMethodModal(onSelect: onSelect),
  );
}

// ============================================================================
// PAYMENT METHOD MODAL WIDGET
// ============================================================================

class PaymentMethodModal extends StatefulWidget {
  final Future<void> Function(PaymentMethod) onSelect;

  const PaymentMethodModal({super.key, required this.onSelect});

  @override
  State<PaymentMethodModal> createState() => _PaymentMethodModalState();
}

class _PaymentMethodModalState extends State<PaymentMethodModal> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  Future<void> _handleCardTap(PaymentMethod method) async {
    if (_isProcessing) return;

    setState(() {
      _selectedMethod = method;
      _isProcessing = true;
    });

    try {
      await widget.onSelect(method);
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500.w),
        decoration: BoxDecoration(
          color: kModalBackground,
          borderRadius: BorderRadius.circular(kModalRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kModalHorizontalPadding,
                  kModalVerticalPadding,
                  12.w,
                  20.h,
                ),
                child: Row(
                  children: [
                    // Spacer for centering title
                    const SizedBox(width: kCloseButtonSize),

                    // Title (centered)
                    Expanded(
                      child: Text(
                        'Choose Payment Method',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    // Close button
                    SizedBox(
                      width: kCloseButtonSize,
                      height: kCloseButtonSize,
                      child: IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: kCloseIconColor,
                          size: 24.w,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // Payment method cards
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kModalHorizontalPadding,
                  0,
                  kModalHorizontalPadding,
                  kModalVerticalPadding,
                ),
                child: Column(
                  children: [
                    // UPI Payment
                    PaymentMethodCard(
                      title: 'UPI Payment',
                      subtitle: 'Google Pay, PhonePe, Paytm',
                      iconColor: kUpiIconColor,
                      iconBackgroundColor: kUpiIconBg,
                      isSelected: _selectedMethod == PaymentMethod.upi,
                      onTap: _isProcessing
                          ? null
                          : () => _handleCardTap(PaymentMethod.upi),
                    ),

                    const SizedBox(height: kCardSpacing),

                    // Credit/Debit Card
                    PaymentMethodCard(
                      title: 'Credit/Debit Card',
                      subtitle: 'Visa, Mastercard, Rupay',
                      iconColor: kCardIconColor,
                      iconBackgroundColor: kCardIconBg,
                      isSelected: _selectedMethod == PaymentMethod.card,
                      onTap: _isProcessing
                          ? null
                          : () => _handleCardTap(PaymentMethod.card),
                    ),

                    const SizedBox(height: kCardSpacing),

                    // Net Banking
                    PaymentMethodCard(
                      title: 'Net Banking',
                      subtitle: 'All major banks',
                      iconColor: kBankIconColor,
                      iconBackgroundColor: kBankIconBg,
                      isSelected: _selectedMethod == PaymentMethod.netBanking,
                      onTap: _isProcessing
                          ? null
                          : () => _handleCardTap(PaymentMethod.netBanking),
                    ),
                    if (_isProcessing) ...[
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Processing test payment...',
                            style: TextStyle(
                              color: kSubtitleColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PAYMENT METHOD CARD WIDGET
// ============================================================================

class PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const PaymentMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          width: double.infinity,
          padding: kCardPadding,
          decoration: BoxDecoration(
            color: isSelected ? kPrimary.withOpacity(0.04) : kModalBackground,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(
              color: isSelected ? kPrimary : kCardBorder,
              width: isSelected ? 2 : 1,
            ),
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
              // Icon container
              Container(
                width: kIconSize,
                height: kIconSize,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(kIconRadius),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: iconColor,
                  size: 32.w,
                ),
              ),

              SizedBox(width: 16.w),

              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Subtitle
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: kSubtitleColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
