// lib/src/screens/admin_dashboard_screen.dart
// Admin Dashboard Screen with real-time statistics

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_statistics_service.dart';
import '../widgets/skeleton_loader.dart';
import 'building_management_screen.dart';
import 'flat_management_screen.dart';

// Design Constants
const kPrimaryBlue = Color(0xFF0E4778);
const kBackground = Color(0xFFF8F9FA);
const kCardWhite = Color(0xFFFFFFFF);
const kBorderColor = Color(0xFFE6E6E6);
const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminStatisticsService();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Status bar spacer
            Container(
              color: Colors.black,
              height: MediaQuery.of(context).padding.top,
            ),

            // Main content
            Expanded(
              child: Container(
                color: kBackground,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),

                      const SizedBox(height: 24),

                      // Statistics Cards
                      _buildStatisticsSection(),

                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActionsSection(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with gradient
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E4778), Color(0xFF061C4C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time society management',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Statistics Section with real-time data
  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Residents and Flats
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _adminService.streamTotalResidents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonLoader(height: 120);
                    }
                    final count = snapshot.data ?? 0;
                    return _buildStatCard(
                      icon: Icons.people,
                      iconColor: const Color(0xFF3B82F6),
                      iconBg: const Color(0xFFDBEAFE),
                      value: count.toString(),
                      label: 'Total Residents',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<int>(
                  stream: _adminService.streamTotalFlats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonLoader(height: 120);
                    }
                    final count = snapshot.data ?? 0;
                    return _buildStatCard(
                      icon: Icons.apartment,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFFEDE9FF),
                      value: count.toString(),
                      label: 'Total Flats',
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Pending Visitors and Complaints
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _adminService.streamPendingVisitors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonLoader(height: 120);
                    }
                    final count = snapshot.data ?? 0;
                    return _buildStatCard(
                      icon: Icons.person_add,
                      iconColor: const Color(0xFFF97316),
                      iconBg: const Color(0xFFFFF3E8),
                      value: count.toString(),
                      label: 'Pending Visitors',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<int>(
                  stream: _adminService.streamPendingComplaints(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonLoader(height: 120);
                    }
                    final count = snapshot.data ?? 0;
                    return _buildStatCard(
                      icon: Icons.report_problem,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEE2E2),
                      value: count.toString(),
                      label: 'Pending Issues',
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Monthly Collection (full width)
          StreamBuilder<double>(
            stream: _adminService.streamMonthlyCollection(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SkeletonLoader(height: 120),
                );
              }
              final amount = snapshot.data ?? 0;
              return _buildCollectionCard(amount);
            },
          ),
        ],
      ),
    );
  }

  /// Individual stat card
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor, width: 1),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Monthly collection card
  Widget _buildCollectionCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'This Month Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.business,
                  label: 'Add Building',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuildingManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.receipt_long,
                  label: 'Add Bill',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    _showComingSoonDialog('Add Bill');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.home_work,
                  label: 'Manage Flats',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlatManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.check_circle,
                  label: 'Approve Visitor',
                  color: const Color(0xFFF97316),
                  onTap: () {
                    _showApproveVisitorDialog();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.list_alt,
                  label: 'View Complaints',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    _showComingSoonDialog('View Complaints');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(), // Empty space for symmetry
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Action card
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: kCardWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: kBorderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show approve visitor dialog
  void _showApproveVisitorDialog() async {
    final visitors = await _adminService.getPendingVisitors();

    if (!mounted) return;

    if (visitors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No pending visitors'),
          backgroundColor: const Color(0xFF6B7280),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Visitors'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(visitor['name'] ?? 'Unknown'),
                subtitle: Text(visitor['purpose'] ?? 'No purpose'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final success = await _adminService.approveVisitor(
                      visitor['id'],
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Visitor approved'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text('Approve'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show coming soon dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
