import 'package:flutter/material.dart';

// ============================================================================
// DESIGN CONSTANTS (matching exact design specs)
// ============================================================================

/// Primary blue color for RSVP button and accents
const kPrimary = Color(0xFF0E4778);

/// Modal background (white)
const kModalBackground = Color(0xFFFFFFFF);

/// Overlay dim color behind modal
const kOverlayColor = Color(0x5C000000); // rgba(0,0,0,0.36)

/// Title text color
const kTitleColor = Color(0xFF111111);

/// Subtext / meta color
const kMetaColor = Color(0xFF6D6D6D);

/// Modal corner radius (16-20px)
const kModalRadius = 20.0;

/// Image corner radius (top corners)
const kImageRadius = 20.0;

/// Button corner radius
const kButtonRadius = 16.0;

/// Modal horizontal padding
const kModalHorizontalPadding = 24.0;

/// Modal vertical padding
const kModalVerticalPadding = 20.0;

/// Content spacing
const kContentSpacing = 16.0;

/// Icon size
const kIconSize = 24.0;

/// Close button size (tappable area)
const kCloseButtonSize = 44.0;

// ============================================================================
// EVENT DETAIL DATA MODEL
// ============================================================================

class EventDetail {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String date;
  final String startTime;
  final String endTime;
  final String location;
  final int attendees;
  final int capacity;
  bool isRsvped;

  EventDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attendees,
    required this.capacity,
    this.isRsvped = false,
  });

  /// Sample mock event
  static EventDetail sample() {
    return EventDetail(
      id: '1',
      title: 'Holi Celebration 2025',
      description:
          'Join us for a colorful Holi celebration with your neighbors!',
      imageUrl:
          'https://images.unsplash.com/photo-1583241800698-2d3d3d0c6b2e?w=800',
      date: 'Jan 1, 2026',
      startTime: '10:00 AM',
      endTime: '2:00 PM',
      location: 'Community Ground',
      attendees: 450,
      capacity: 1000,
    );
  }

  /// Get formatted date and time string
  String get dateTimeString => '$date • $startTime - $endTime';

  /// Get formatted time string
  String get timeString => '$startTime - $endTime';

  /// Get formatted attendees string
  String get attendeesString => '$attendees/$capacity attending';
}

// ============================================================================
// HELPER FUNCTION TO SHOW MODAL
// ============================================================================

/// Shows the event detail modal as a centered overlay
///
/// Usage:
/// ```dart
/// showEventDetailModal(context, EventDetail.sample(), (event) {
///   print('RSVP for: ${event.title}');
/// });
/// ```
Future<void> showEventDetailModal(
  BuildContext context,
  EventDetail event, {
  Function(EventDetail)? onRsvp,
}) {
  return showDialog(
    context: context,
    barrierColor: kOverlayColor,
    barrierDismissible: true,
    builder: (context) => EventDetailModal(event: event, onRsvp: onRsvp),
  );
}

// ============================================================================
// EVENT DETAIL MODAL WIDGET
// ============================================================================

class EventDetailModal extends StatefulWidget {
  final EventDetail event;
  final Function(EventDetail)? onRsvp;

  const EventDetailModal({super.key, required this.event, this.onRsvp});

  @override
  State<EventDetailModal> createState() => _EventDetailModalState();
}

class _EventDetailModalState extends State<EventDetailModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup entrance animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _handleRsvp() {
    setState(() {
      widget.event.isRsvped = !widget.event.isRsvped;
    });

    if (widget.onRsvp != null) {
      widget.onRsvp!(widget.event);
    }

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.event.isRsvped
              ? 'RSVP confirmed for ${widget.event.title}'
              : 'RSVP cancelled for ${widget.event.title}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
            child: Stack(
              children: [
                // Main content
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header image with rounded top corners
                      HeaderImage(
                        imageUrl: widget.event.imageUrl,
                        onTap: () {
                          // Optional: Show full-screen image preview
                          print('Image tapped');
                        },
                      ),

                      // Content section
                      Padding(
                        padding: const EdgeInsets.all(kModalHorizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Event title (20-22pt Semibold, centered)
                            Text(
                              widget.event.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kTitleColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Description (16-18pt Regular)
                            Text(
                              widget.event.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: kMetaColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                letterSpacing: -0.2,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Icon meta rows
                            IconMetaRow(
                              icon: Icons.calendar_today_outlined,
                              text: widget.event.dateTimeString,
                            ),

                            const SizedBox(height: 12),

                            IconMetaRow(
                              icon: Icons.location_on_outlined,
                              text: widget.event.location,
                            ),

                            const SizedBox(height: 12),

                            IconMetaRow(
                              icon: Icons.access_time_outlined,
                              text: widget.event.timeString,
                            ),

                            const SizedBox(height: 12),

                            IconMetaRow(
                              icon: Icons.people_outline,
                              text: widget.event.attendeesString,
                            ),

                            const SizedBox(height: 28),

                            // RSVP Button
                            PrimaryButton(
                              text: widget.event.isRsvped
                                  ? 'Cancel RSVP'
                                  : 'RSVP Now',
                              onPressed: _handleRsvp,
                              isActive: !widget.event.isRsvped,
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleClose,
                      borderRadius: BorderRadius.circular(kCloseButtonSize / 2),
                      child: Container(
                        width: kCloseButtonSize,
                        height: kCloseButtonSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF9B9B9B),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER IMAGE WIDGET
// ============================================================================

/// Large full-width event image with rounded top corners
/// Aspect ratio: 16:9 or similar
class HeaderImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const HeaderImage({super.key, required this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kImageRadius),
          topRight: Radius.circular(kImageRadius),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ICON META ROW WIDGET
// ============================================================================

/// Row with icon and text for event metadata
/// Icon size: 24px
/// Text: 14-15pt Regular
/// Spacing: 12px between icon and text
class IconMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const IconMetaRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kMetaColor, size: kIconSize),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: kMetaColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIMARY BUTTON WIDGET
// ============================================================================

/// Large full-width RSVP button
/// Button text: 18-20pt Medium, white
/// Background: Primary blue (#2563EB)
/// Vertical padding: 16-20px
/// Corner radius: 16px
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isActive;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? kPrimary : Colors.grey[400],
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
