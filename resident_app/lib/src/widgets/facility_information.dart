import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/booking_firestore_service.dart';

IconData facilityIcon(String? name) {
  switch (name?.toLowerCase()) {
    case 'pool':
    case 'swimming_pool':
      return Icons.pool;
    case 'gym':
    case 'fitness':
    case 'fitness_center':
      return Icons.fitness_center;
    case 'hall':
    case 'community_hall':
      return Icons.home_outlined;
    case 'lawn':
    case 'party_lawn':
      return Icons.people_outline;
    case 'tennis':
      return Icons.sports_tennis;
    case 'basketball':
      return Icons.sports_basketball;
    case 'playground':
      return Icons.park;
    case 'parking':
      return Icons.local_parking;
    case 'clubhouse':
      return Icons.house;
    default:
      return Icons.apartment;
  }
}

/// Shared read-only image presentation for cards and facility details.
///
/// AmenityModel.images is ordered; images[0] is the primary image. Legacy
/// imageUrl-only facilities are normalized by AmenityModel into a one-photo
/// gallery, so callers do not need a second presentation path.
class FacilityImage extends StatefulWidget {
  const FacilityImage({super.key, required this.amenity, this.height = 90});

  final AmenityModel amenity;
  final double height;

  @override
  State<FacilityImage> createState() => _FacilityImageState();
}

class _FacilityImageState extends State<FacilityImage> {
  late final PageController _pageController;
  int _page = 0;

  List<AmenityImage> get _photos => widget.amenity.images;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant FacilityImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldUrls = oldWidget.amenity.images.map((image) => image.url).toList();
    final newUrls = widget.amenity.images.map((image) => image.url).toList();

    if (!_sameStrings(oldUrls, newUrls)) {
      _page = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return ColoredBox(
      color: const Color(0xFFD6EBFF),
      child: Center(
        child: Icon(
          facilityIcon(widget.amenity.iconName),
          size: 44.w,
          color: const Color(0xFF0A64FF),
          semanticLabel: 'Facility image unavailable',
        ),
      ),
    );
  }

  void _goTo(int index) {
    final photos = _photos;
    if (photos.length < 2) return;

    final target = (index + photos.length) % photos.length;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;

    return SizedBox(
      height: widget.height.h,
      width: double.infinity,
      child: photos.isEmpty
          ? _fallback()
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  key: const ValueKey('facility-photo-page-view'),
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() => _page = index);
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      photos[index].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => _fallback(),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _fallback(),
                    );
                  },
                ),
                if (photos.length > 1) ...[
                  Positioned(
                    right: 6.w,
                    top: 6.h,
                    child: Container(
                      key: const ValueKey('facility-photo-count'),
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        '${_page + 1} / ${photos.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _FacilityPhotoArrow(
                        key: const ValueKey('facility-photo-previous'),
                        tooltip: 'Previous facility photo',
                        icon: Icons.chevron_left,
                        onPressed: () => _goTo(_page - 1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _FacilityPhotoArrow(
                        key: const ValueKey('facility-photo-next'),
                        tooltip: 'Next facility photo',
                        icon: Icons.chevron_right,
                        onPressed: () => _goTo(_page + 1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 5.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(photos.length, (index) {
                        final active = index == _page;
                        return GestureDetector(
                          key: ValueKey('facility-photo-dot-$index'),
                          onTap: () => _goTo(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: active ? 14.w : 6.w,
                            height: 6.h,
                            margin: EdgeInsets.symmetric(horizontal: 2.w),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(999.r),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FacilityPhotoArrow extends StatelessWidget {
  const _FacilityPhotoArrow({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: 18.w,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: 28.w, height: 28.h),
      ),
    );
  }
}

/// Document-backed information only; contains no booking actions or defaults
/// for opening hours, durations, or missing prices.
class FacilityInformation extends StatelessWidget {
  const FacilityInformation({super.key, required this.amenity});

  final AmenityModel amenity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: FacilityImage(amenity: amenity, height: 120),
        ),
        SizedBox(height: 12.h),
        Text(
          amenity.name,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        Text(amenity.type),
        if (amenity.buildingName != null)
          Text('Building: ${amenity.buildingName}'),
        if (amenity.description != null) ...[
          SizedBox(height: 8.h),
          Text(amenity.description!),
        ],
        SizedBox(height: 8.h),
        Text('Price: ${amenity.priceDisplay}'),
        SizedBox(height: 8.h),
        if (amenity.timeSlots.isNotEmpty) ...[
          const Text('Time slots'),
          for (final slot in amenity.timeSlots) Text(slot),
        ] else
          const Text('No time slots available'),
        if (amenity.bookingDurations.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text('Booking durations: ${amenity.bookingDurations.join(', ')}'),
        ],
        if (amenity.hasConfiguredCapacity) ...[
          SizedBox(height: 8.h),
          Text(
            'Capacity: ${amenity.maxCapacity} '
            '${amenity.maxCapacity == 1 ? 'person' : 'people'}',
          ),
        ],
      ],
    );
  }
}
