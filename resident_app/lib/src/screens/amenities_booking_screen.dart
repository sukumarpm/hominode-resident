import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../components/standard_screen.dart';
import '../modals/booking_modal.dart';
import '../models/amenity.dart';
import '../models/booking.dart';
import '../services/booking_firestore_service.dart';
import '../widgets/facility_information.dart';

class AmenitiesBookingScreen extends StatefulWidget {
  const AmenitiesBookingScreen({super.key, this.bookingService});
  final BookingFirestoreService? bookingService;

  @override
  State<AmenitiesBookingScreen> createState() => _AmenitiesBookingScreenState();
}

class _AmenitiesBookingScreenState extends State<AmenitiesBookingScreen> {
  late final _bookingService =
      widget.bookingService ?? BookingFirestoreService();
  late final _amenitiesStream = _bookingService.streamAmenitiesRealtime();

  Future<void> _handleCancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel the booking for ${booking.amenityName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5757),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && booking.id != null) {
      try {
        final result = await _bookingService.cancelBooking(booking.id!);
        if (result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to cancel booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Amenities Booking',
      onBackPressed: () => Navigator.maybePop(context),
      isScrollable: true,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Amenities Section
          SizedBox(height: 18.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Amenities',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0E2247),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Explore facility details, fees and available booking options.',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF667792),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildAmenitiesStream(),
          ),

          // My Bookings Section
          SizedBox(height: 32.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildBookingsStream(),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildAmenitiesStream() {
    return StreamBuilder<List<AmenityModel>>(
      stream: _amenitiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 34.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFE7EDF5)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFFED7D7)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 36.w,
                  color: const Color(0xFFDC3C3C),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Unable to load amenities',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7F1D1D),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF9B5555),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final amenities = snapshot.data ?? const <AmenityModel>[];
        if (amenities.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFE7EDF5)),
            ),
            child: Column(
              children: [
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 28.w,
                    color: const Color(0xFF1558D6),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'No amenities available',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0E2247),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Facilities made available by your community will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.4,
                    color: const Color(0xFF667792),
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 700;
            final spacing = 14.w;
            final itemWidth = useTwoColumns
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: 14.h,
              children: amenities.map((amenity) {
                return SizedBox(
                  width: itemWidth,
                  child: AmenityCard(
                    amenity: amenity,
                    onTap: () => _handleAmenityTap(context, amenity),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingsStream() {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.streamMyBookingsRealtime(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.w,
                    color: Color(0xFFFF5757),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading bookings',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FD),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFE2EAF5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3EDFB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: 24.w,
                    color: const Color(0xFF1558D6),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No bookings yet',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E2247),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Your upcoming amenity bookings will appear here.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF667792),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Data state
        final bookings = snapshot.data!;
        return Column(
          children: bookings.map((booking) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: BookingCard(
                booking: booking,
                onCancel: () => _handleCancelBooking(booking),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleAmenityTap(
    BuildContext context,
    AmenityModel amenity,
  ) async {
    final amenityLegacy = Amenity(
      id: amenity.id,
      communityId: amenity.communityId,
      name: amenity.name,
      price: amenity.priceDisplay,
      isAvailable: amenity.isAvailable,
      iconName: amenity.iconName ?? 'apartment',
      backgroundColor: '#D6EBFF',
      iconColor: '#0A64FF',
    );

    await BookingModal.show(context, amenityLegacy);
  }
}

// ============================================
// AMENITY CARD WIDGET
// ============================================

class AmenityCard extends StatelessWidget {
  final AmenityModel amenity;
  final VoidCallback? onTap;

  const AmenityCard({super.key, required this.amenity, this.onTap});

  Widget _infoChip({
    required IconData icon,
    required String label,
    Color foreground = const Color(0xFF43546F),
    Color background = const Color(0xFFF3F6FA),
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: foreground),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceText = amenity.priceDisplay;
    final hasValidPrice = priceText != 'Price unavailable';
    final isFree = priceText == 'Free';
    final feeBadge = !hasValidPrice
        ? 'FEE NOT SET'
        : isFree
        ? 'FREE'
        : 'PAID';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE3EAF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F173A63),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child: FacilityImage(amenity: amenity, height: 178),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                amenity.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0E2247),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 5.h,
                                children: [
                                  Text(
                                    amenity.type,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF667792),
                                    ),
                                  ),
                                  if (amenity.buildingName != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14.w,
                                          color: const Color(0xFF667792),
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          amenity.buildingName!,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF667792),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: amenity.isAvailable
                                ? const Color(0xFFE7F8EE)
                                : const Color(0xFFFFECEC),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            amenity.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: amenity.isAvailable
                                  ? const Color(0xFF078A49)
                                  : const Color(0xFFD23D3D),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (amenity.description != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        amenity.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          height: 1.45,
                          color: const Color(0xFF53627A),
                        ),
                      ),
                    ],

                    SizedBox(height: 14.h),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 13.w,
                        vertical: 11.h,
                      ),
                      decoration: BoxDecoration(
                        color: isFree
                            ? const Color(0xFFF0FBF5)
                            : const Color(0xFFF1F6FF),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? const Color(0xFFD9F5E5)
                                  : const Color(0xFFDDEAFF),
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                            child: Text(
                              feeBadge,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isFree
                                    ? const Color(0xFF078A49)
                                    : const Color(0xFF1558D6),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              priceText,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: isFree
                                    ? const Color(0xFF078A49)
                                    : const Color(0xFF1558D6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    Wrap(
                      spacing: 7.w,
                      runSpacing: 7.h,
                      children: [
                        _infoChip(
                          icon: Icons.schedule_rounded,
                          label: amenity.timeSlotsDisplay,
                        ),
                        _infoChip(
                          icon: Icons.people_alt_outlined,
                          label: amenity.capacityDisplay,
                        ),
                        if (amenity.bookingDurations.isNotEmpty)
                          _infoChip(
                            icon: Icons.timelapse_rounded,
                            label: amenity.bookingDurations.join(' • '),
                          ),
                        if (amenity.hasPackages)
                          _infoChip(
                            icon: Icons.card_membership_rounded,
                            label: 'Packages available',
                            foreground: const Color(0xFF078A49),
                            background: const Color(0xFFEAF9F0),
                          ),
                      ],
                    ),

                    SizedBox(height: 15.h),

                    Container(
                      width: double.infinity,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1558D6),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View details & book',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18.w,
                            color: Colors.white,
                          ),
                        ],
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

// ============================================
// BOOKING CARD WIDGET
// ============================================

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;

  const BookingCard({super.key, required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.amenityName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              StatusPill(status: booking.status),
            ],
          ),
          SizedBox(height: 8.h),

          // Booking Type & People
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: booking.isPackage
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  booking.isPackage ? booking.packageType! : 'Daily',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: booking.isPackage
                        ? const Color(0xFF0E4778)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              if (booking.numberOfPeople > 1) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 12.w, color: Color(0xFF10B981)),
                      SizedBox(width: 4.w),
                      Text(
                        '${booking.numberOfPeople} people',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Date & Time
          Row(
            children: [
              Icon(Icons.access_time, size: 16.w, color: Color(0xFF8A8A8A)),
              SizedBox(width: 6.w),
              Text(
                '${booking.formattedDate} • ${booking.timeSlot}',
                style: TextStyle(fontSize: 13.sp, color: Color(0xFF8A8A8A)),
              ),
            ],
          ),

          // Package Duration (if applicable)
          if (booking.isPackage && booking.packageDuration.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.w,
                  color: Color(0xFF8A8A8A),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Valid: ${booking.packageDuration}',
                    style: TextStyle(fontSize: 12.sp, color: Color(0xFF8A8A8A)),
                  ),
                ),
              ],
            ),
          ],

          // Price
          if (booking.price > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16.w,
                  color: Color(0xFF8A8A8A),
                ),
                SizedBox(width: 6.w),
                Text(
                  '₹${booking.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0E4778),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton(
              onPressed: booking.status == 'cancelled' ? null : onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF5757), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                disabledForegroundColor: const Color(0xFF9B9B9B),
              ),
              child: Text(
                booking.status == 'cancelled' ? 'Cancelled' : 'Cancel Booking',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: booking.status == 'cancelled'
                      ? const Color(0xFF9B9B9B)
                      : const Color(0xFFFF5757),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// STATUS PILL WIDGET
// ============================================

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  Color get _backgroundColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFFE5F6E9);
      case 'pending':
        return const Color(0xFFFFF4E6);
      case 'cancelled':
        return const Color(0xFFFFECEC);
      default:
        return const Color(0xFFE5F6E9);
    }
  }

  Color get _textColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFF0AA03C);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
        return const Color(0xFFFF5757);
      default:
        return const Color(0xFF0AA03C);
    }
  }

  String get _displayText {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _displayText,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
