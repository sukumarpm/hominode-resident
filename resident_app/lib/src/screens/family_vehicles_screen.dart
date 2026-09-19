import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../components/app_segmented_control.dart';
import '../components/standard_screen.dart';
import '../modals/add_edit_member_modal.dart';
import '../modals/add_edit_vehicle_modal.dart';
import '../models/family_member.dart';
import '../models/vehicle.dart';
import '../services/family_firestore_service.dart';
import '../services/vehicle_firestore_service.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/family_card.dart';
import '../widgets/vehicle_card.dart';

class FamilyVehiclesScreen extends StatefulWidget {
  const FamilyVehiclesScreen({super.key});

  @override
  State<FamilyVehiclesScreen> createState() => _FamilyVehiclesScreenState();
}

class _FamilyVehiclesScreenState extends State<FamilyVehiclesScreen> {
  int _selectedTab = 0; // 0: Family Members, 1: Vehicles
  List<FamilyMember> _familyMembers = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  final _familyService = FamilyFirestoreService();
  final _vehicleService = VehicleFirestoreService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final members = await _familyService.getFamilyMembers();
      final vehicles = await _vehicleService.getVehicles();

      if (mounted) {
        setState(() {
          _familyMembers = members;
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'family_vehicles'.tr(),
      isScrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          SizedBox(height: 20.h),
          AppSegmentedControl(
            segments: ['family_members'.tr(), 'vehicles'.tr()],
            selectedIndex: _selectedTab,
            onChanged: (index) {
              setState(() => _selectedTab = index);
            },
          ),
          SizedBox(height: 20.h),
          _buildSectionHeader(),
          SizedBox(height: 16.h),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOldHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0E4778),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(4.w, 12.h, 16.w, 24.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20.w,
                ),
                padding: EdgeInsets.all(12.w),
                constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
              ),
              Text(
                'family_vehicles'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _selectedTab == 0
                  ? 'manage_your_family_members'.tr()
                  : 'manage_your_vehicles'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton.icon(
            onPressed: _showAddModal,
            icon: Icon(Icons.add, size: 18.w, color: Colors.white),
            label: Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E4778),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E4778)),
        ),
      );
    }

    if (_selectedTab == 0) {
      if (_familyMembers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64.w, color: Colors.grey[400]),
              SizedBox(height: 16.h),
              Text(
                'no_family_members_added_yet'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'tap_add_button_to_add_family_member'.tr(),
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        key: const ValueKey('family'),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _familyMembers.length,
        itemBuilder: (context, index) {
          final member = _familyMembers[index];
          return FamilyCard(
            member: member,
            onDelete: member.isPrimary
                ? null
                : () => _deleteFamilyMember(member.id),
            onTap: () => _editFamilyMember(member),
          );
        },
      );
    } else {
      if (_vehicles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                'no_vehicles_added_yet'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'tap_add_button_to_add_vehicle'.tr(),
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        key: const ValueKey('vehicles'),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return VehicleCard(
            vehicle: vehicle,
            onDelete: () => _deleteVehicle(vehicle.id),
            onTap: () => _editVehicle(vehicle),
          );
        },
      );
    }
  }

  void _showAddModal() {
    if (_selectedTab == 0) {
      AddEditMemberModal.show(
        context,
        onSave: (member) async {
          final id = await _familyService.addFamilyMember(member);
          if (id != null) {
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('family_member_added_successfully'.tr()),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('failed_to_add_family_member'.tr()),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              );
            }
          }
        },
      );
    } else {
      AddEditVehicleModal.show(
        context,
        onSave: (vehicle) async {
          final id = await _vehicleService.addVehicle(vehicle);
          if (id != null) {
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('vehicle_added_successfully'.tr()),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('failed_to_add_vehicle'.tr()),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              );
            }
          }
        },
      );
    }
  }

  void _editFamilyMember(FamilyMember member) {
    AddEditMemberModal.show(
      context,
      member: member,
      onSave: (updated) async {
        final success = await _familyService.updateFamilyMember(updated);
        if (success) {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('family_member_updated_successfully'.tr()),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('failed_to_update_family_member'.tr()),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        }
      },
    );
  }

  void _editVehicle(Vehicle vehicle) {
    AddEditVehicleModal.show(
      context,
      vehicle: vehicle,
      onSave: (updated) async {
        final success = await _vehicleService.updateVehicle(updated);
        if (success) {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('vehicle_updated_successfully'.tr()),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('failed_to_update_vehicle'.tr()),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _deleteFamilyMember(String id) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: 'delete_family_member'.tr(),
      message: 'are_you_sure_you_want_to_remove_this_family_member'.tr(),
    );

    if (confirmed && mounted) {
      final success = await _familyService.deleteFamilyMember(id);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('family_member_removed'.tr()),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failed_to_remove_family_member'.tr()),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteVehicle(String id) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: 'delete_vehicle'.tr(),
      message: 'are_you_sure_you_want_to_remove_this_vehicle'.tr(),
    );

    if (confirmed && mounted) {
      final success = await _vehicleService.deleteVehicle(id);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('vehicle_removed'.tr()),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failed_to_remove_vehicle'.tr()),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      }
    }
  }
}
