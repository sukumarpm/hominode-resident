import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/components/app_segmented_control.dart';

/// Demo screen showcasing the AppSegmentedControl component
/// with various use cases and configurations
class AppSegmentedControlDemo extends StatefulWidget {
  const AppSegmentedControlDemo({super.key});

  @override
  State<AppSegmentedControlDemo> createState() =>
      _AppSegmentedControlDemoState();
}

class _AppSegmentedControlDemoState extends State<AppSegmentedControlDemo> {
  int _twoSegmentIndex = 0;
  int _threeSegmentIndex = 0;
  int _fourSegmentIndex = 0;
  int _fiveSegmentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Segmented Control',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Premium component with smooth animations',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2 Segments Example
                _buildSection(
                  title: '2 Segments',
                  subtitle: 'Messages: Chats / Notifications',
                  child: Column(
                    children: [
                      AppSegmentedControl(
                        segments: const ['Chats', 'Notifications'],
                        selectedIndex: _twoSegmentIndex,
                        onChanged: (index) {
                          setState(() => _twoSegmentIndex = index);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildContentCard(_twoSegmentIndex, [
                        'Showing all your chat conversations',
                        'Showing all your notifications',
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3 Segments Example
                _buildSection(
                  title: '3 Segments',
                  subtitle: 'Events: Events / Notices / Polls',
                  child: Column(
                    children: [
                      AppSegmentedControl(
                        segments: const ['Events', 'Notices', 'Polls'],
                        selectedIndex: _threeSegmentIndex,
                        onChanged: (index) {
                          setState(() => _threeSegmentIndex = index);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildContentCard(_threeSegmentIndex, [
                        'Upcoming community events',
                        'Important notices and announcements',
                        'Active polls and surveys',
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 4 Segments Example
                _buildSection(
                  title: '4 Segments',
                  subtitle: 'Marketplace: All / Furniture / Electronics / Other',
                  child: Column(
                    children: [
                      AppSegmentedControl(
                        segments: const ['All', 'Furniture', 'Electronics', 'Other'],
                        selectedIndex: _fourSegmentIndex,
                        onChanged: (index) {
                          setState(() => _fourSegmentIndex = index);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildContentCard(_fourSegmentIndex, [
                        'All marketplace items',
                        'Furniture and home decor',
                        'Electronics and gadgets',
                        'Other miscellaneous items',
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 5 Segments Example
                _buildSection(
                  title: '5 Segments (Maximum)',
                  subtitle: 'Status: All / Pending / Active / Completed / Cancelled',
                  child: Column(
                    children: [
                      AppSegmentedControl(
                        segments: const [
                          'All',
                          'Pending',
                          'Active',
                          'Done',
                          'Cancelled'
                        ],
                        selectedIndex: _fiveSegmentIndex,
                        onChanged: (index) {
                          setState(() => _fiveSegmentIndex = index);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildContentCard(_fiveSegmentIndex, [
                        'All items regardless of status',
                        'Items waiting for approval',
                        'Currently active items',
                        'Completed items',
                        'Cancelled items',
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Design Specs
                _buildSection(
                  title: 'Design Specifications',
                  subtitle: 'Component details',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSpecRow('Track Color', '#F0F1F3'),
                        _buildSpecRow('Height', '48px'),
                        _buildSpecRow('Corner Radius', '30px'),
                        _buildSpecRow('Active Pill', 'White + Shadow'),
                        _buildSpecRow('Shadow', 'rgba(16,24,40,0.12)'),
                        _buildSpecRow('Animation', '220ms easeOut'),
                        _buildSpecRow('Active Text', '#0F172A Bold'),
                        _buildSpecRow('Inactive Text', '#9AA0A6 Medium'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildContentCard(int index, List<String> messages) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(index),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                messages[index],
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
