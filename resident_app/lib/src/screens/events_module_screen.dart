// lib/src/screens/events_module_screen.dart
// Main Events Module screen with tab switching

import 'package:flutter/material.dart';
import '../components/primary_header.dart';
import '../components/app_segmented_control.dart';
import 'events_tab.dart';
import 'notices_tab.dart';
import 'polls_tab.dart';

class EventsModuleScreen extends StatefulWidget {
  final int initialTab;

  const EventsModuleScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<EventsModuleScreen> createState() => _EventsModuleScreenState();
}

class _EventsModuleScreenState extends State<EventsModuleScreen> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTab;
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const EventsTab(key: ValueKey('events'));
      case 1:
        return const NoticesTab(key: ValueKey('notices'));
      case 2:
        return const PollsTab(key: ValueKey('polls'));
      default:
        return const EventsTab(key: ValueKey('events'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const PrimaryHeader(title: 'Events & Announcements'),
            const SizedBox(height: 20),
            // Tabs
            AppSegmentedControl(
              segments: const ['Events', 'Notices', 'Polls'],
              selectedIndex: _selectedTabIndex,
              onChanged: (index) {
                setState(() => _selectedTabIndex = index);
              },
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
