// lib/src/screens/flat_management_screen.dart
// Flat Management Screen with Occupancy Grid

import 'package:flutter/material.dart';
import '../models/flat_model.dart';
import '../models/building_model.dart';
import '../services/flat_service.dart';
import '../services/building_service.dart';
import '../components/standard_screen.dart';

class FlatManagementScreen extends StatefulWidget {
  const FlatManagementScreen({super.key});

  @override
  State<FlatManagementScreen> createState() => _FlatManagementScreenState();
}

class _FlatManagementScreenState extends State<FlatManagementScreen> {
  final _flatService = FlatService();
  final _buildingService = BuildingService();

  List<BuildingModel> _buildings = [];
  BuildingModel? _selectedBuilding;
  List<FlatModel> _flats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    setState(() => _isLoading = true);

    try {
      final buildings = await _buildingService.getBuildings();

      if (mounted) {
        setState(() {
          _buildings = buildings;
          if (buildings.isNotEmpty) {
            _selectedBuilding = buildings.first;
            _loadFlats();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      print('❌ Error loading buildings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFlats() async {
    if (_selectedBuilding == null) return;

    setState(() => _isLoading = true);

    try {
      final flats = await _flatService.getFlatsByBuilding(
        _selectedBuilding!.id,
      );

      if (mounted) {
        setState(() {
          _flats = flats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading flats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Flat Management',
      isScrollable: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          // Building selector and actions
          _buildHeader(),

          // Legend
          _buildLegend(),

          // Flat grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0E4778),
                      ),
                    ),
                  )
                : _flats.isEmpty
                ? _buildEmptyState()
                : _buildFlatGrid(),
          ),
        ],
      ),
    );
  }

  /// Header with building selector and actions
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Building dropdown
          if (_buildings.isNotEmpty)
            DropdownButtonFormField<BuildingModel>(
              initialValue: _selectedBuilding,
              decoration: InputDecoration(
                labelText: 'Select Building',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _buildings.map((building) {
                return DropdownMenuItem(
                  value: building,
                  child: Text(building.name),
                );
              }).toList(),
              onChanged: (building) {
                setState(() {
                  _selectedBuilding = building;
                  _loadFlats();
                });
              },
            ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddFlatDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Flat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E4778),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showBulkCreateDialog,
                  icon: const Icon(Icons.grid_on, size: 18),
                  label: const Text('Bulk Create'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0E4778),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF0E4778)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Legend showing status colors
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Vacant', const Color(0xFF10B981)),
          _buildLegendItem('Occupied', const Color(0xFF3B82F6)),
          _buildLegendItem('Maintenance', const Color(0xFFF97316)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Flats in This Building',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add flats to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Flat grid grouped by floor
  Widget _buildFlatGrid() {
    // Group flats by floor
    final Map<int, List<FlatModel>> flatsByFloor = {};
    for (var flat in _flats) {
      flatsByFloor.putIfAbsent(flat.floor, () => []).add(flat);
    }

    final floors = flatsByFloor.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: floors.length,
      itemBuilder: (context, index) {
        final floor = floors[index];
        final flats = flatsByFloor[floor]!;

        return _buildFloorSection(floor, flats);
      },
    );
  }

  /// Floor section with flats
  Widget _buildFloorSection(int floor, List<FlatModel> flats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Floor $floor',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),

        // Flats grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: flats.length,
          itemBuilder: (context, index) {
            return _buildFlatCard(flats[index]);
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Individual flat card
  Widget _buildFlatCard(FlatModel flat) {
    Color statusColor;
    switch (flat.status) {
      case 'occupied':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'maintenance':
        statusColor = const Color(0xFFF97316);
        break;
      default:
        statusColor = const Color(0xFF10B981);
    }

    return Material(
      color: statusColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showFlatDetailsDialog(flat),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                flat.flatNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (flat.residentIds.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Icon(Icons.person, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ========== DIALOGS ==========

  /// Show Add Flat Dialog
  void _showAddFlatDialog() {
    if (_selectedBuilding == null) return;

    final formKey = GlobalKey<FormState>();
    final flatNumberController = TextEditingController();
    final blockController = TextEditingController();
    final floorController = TextEditingController();
    final areaController = TextEditingController();
    final bedroomsController = TextEditingController();
    final bathroomsController = TextEditingController();
    String status = 'vacant';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Flat'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: flatNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Flat Number *',
                    hintText: 'e.g., 101, A-201',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter flat number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: blockController,
                  decoration: const InputDecoration(
                    labelText: 'Block *',
                    hintText: 'e.g., A, B, Tower 1',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter block';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: floorController,
                  decoration: const InputDecoration(
                    labelText: 'Floor *',
                    hintText: 'e.g., 1, 2, 10',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter floor';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area (sq ft)',
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bedroomsController,
                  decoration: const InputDecoration(
                    labelText: 'Bedrooms',
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bathroomsController,
                  decoration: const InputDecoration(
                    labelText: 'Bathrooms',
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'vacant', child: Text('Vacant')),
                    DropdownMenuItem(
                      value: 'occupied',
                      child: Text('Occupied'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) status = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                final flat = FlatModel(
                  id: '',
                  buildingId: _selectedBuilding!.id,
                  flatNumber: flatNumberController.text.trim(),
                  block: blockController.text.trim(),
                  floor: int.parse(floorController.text),
                  ownerId: null,
                  residentIds: [],
                  area: int.tryParse(areaController.text) ?? 0,
                  bedrooms: int.tryParse(bedroomsController.text) ?? 0,
                  bathrooms: int.tryParse(bathroomsController.text) ?? 0,
                  status: status,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final flatId = await _flatService.addFlat(flat);

                if (flatId != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Flat added successfully')),
                  );
                  _loadFlats();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add flat')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E4778),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Show Bulk Create Dialog
  void _showBulkCreateDialog() {
    if (_selectedBuilding == null) return;

    final formKey = GlobalKey<FormState>();
    final blockController = TextEditingController();
    final startFloorController = TextEditingController();
    final endFloorController = TextEditingController();
    final flatsPerFloorController = TextEditingController();
    final prefixController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Create Flats'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Building: ${_selectedBuilding!.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: blockController,
                  decoration: const InputDecoration(
                    labelText: 'Block *',
                    hintText: 'e.g., A, B, Tower 1',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter block';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: startFloorController,
                  decoration: const InputDecoration(
                    labelText: 'Start Floor *',
                    hintText: 'e.g., 1',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter start floor';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: endFloorController,
                  decoration: const InputDecoration(
                    labelText: 'End Floor *',
                    hintText: 'e.g., 10',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter end floor';
                    }
                    final endFloor = int.tryParse(value);
                    final startFloor = int.tryParse(startFloorController.text);
                    if (endFloor == null) {
                      return 'Please enter valid number';
                    }
                    if (startFloor != null && endFloor < startFloor) {
                      return 'End floor must be >= start floor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: flatsPerFloorController,
                  decoration: const InputDecoration(
                    labelText: 'Flats Per Floor *',
                    hintText: 'e.g., 4',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter flats per floor';
                    }
                    final count = int.tryParse(value);
                    if (count == null || count <= 0) {
                      return 'Please enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: prefixController,
                  decoration: const InputDecoration(
                    labelText: 'Flat Number Prefix',
                    hintText: 'Optional, e.g., A-',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Example:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Start: 1, End: 3, Per Floor: 4, Prefix: A-',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Creates: A-101, A-102, A-103, A-104, A-201...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                final startFloor = int.parse(startFloorController.text);
                final endFloor = int.parse(endFloorController.text);
                final flatsPerFloor = int.parse(flatsPerFloorController.text);
                final totalFlats = (endFloor - startFloor + 1) * flatsPerFloor;

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final created = await _flatService.bulkCreateFlats(
                  buildingId: _selectedBuilding!.id,
                  block: blockController.text.trim(),
                  startFloor: startFloor,
                  endFloor: endFloor,
                  flatsPerFloor: flatsPerFloor,
                  flatNumberPrefix: prefixController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context); // Close loading

                  if (created > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Created $created flats successfully'),
                      ),
                    );
                    _loadFlats();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create flats')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E4778),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Show Flat Details Dialog
  void _showFlatDetailsDialog(FlatModel flat) async {
    // Fetch resident details if any
    final List<Map<String, dynamic>> residents = [];
    for (final residentId in flat.residentIds) {
      final resident = await _flatService.getResidentDetails(residentId);
      if (resident != null) {
        residents.add(resident);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Flat ${flat.flatNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Block', flat.block),
              _buildDetailRow('Floor', flat.floor.toString()),
              _buildDetailRow('Status', flat.status.toUpperCase()),
              if (flat.area > 0) _buildDetailRow('Area', '${flat.area} sq ft'),
              if (flat.bedrooms > 0)
                _buildDetailRow('Bedrooms', flat.bedrooms.toString()),
              if (flat.bathrooms > 0)
                _buildDetailRow('Bathrooms', flat.bathrooms.toString()),

              const SizedBox(height: 16),
              const Text(
                'Residents',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),

              if (residents.isEmpty)
                const Text(
                  'No residents assigned',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                )
              else
                ...residents.map(
                  (resident) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resident['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                resident['email'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (flat.status == 'vacant' || flat.residentIds.isEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAssignResidentDialog(flat);
              },
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Assign Resident'),
            ),
          if (flat.residentIds.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRemoveResidentDialog(flat, residents);
              },
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('Remove Resident'),
            ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showChangeStatusDialog(flat);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Change Status'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Show Assign Resident Dialog
  void _showAssignResidentDialog(FlatModel flat) async {
    // Fetch available residents
    final availableResidents = await _flatService.getAvailableResidents();

    if (!mounted) return;

    if (availableResidents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available residents to assign')),
      );
      return;
    }

    String? selectedResidentId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Resident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flat: ${flat.flatNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Resident:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: availableResidents.map((resident) {
                      final isSelected = selectedResidentId == resident['id'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedResidentId = resident['id'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0E4778)
                                  : const Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? const Color(0xFF0E4778)
                                    : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resident['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      resident['email'] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedResidentId == null
                  ? null
                  : () async {
                      Navigator.pop(context);

                      final success = await _flatService.assignResident(
                        flatId: flat.id,
                        residentId: selectedResidentId!,
                        buildingId: flat.buildingId,
                      );

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Resident assigned successfully'),
                            ),
                          );
                          _loadFlats();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to assign resident'),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E4778),
                foregroundColor: Colors.white,
              ),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show Remove Resident Dialog
  void _showRemoveResidentDialog(
    FlatModel flat,
    List<Map<String, dynamic>> residents,
  ) {
    String? selectedResidentId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Remove Resident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flat: ${flat.flatNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Resident to Remove:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...residents.map((resident) {
                final isSelected = selectedResidentId == resident['id'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedResidentId = resident['id'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFEF2F2)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resident['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                resident['email'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedResidentId == null
                  ? null
                  : () async {
                      Navigator.pop(context);

                      final success = await _flatService.removeResident(
                        flatId: flat.id,
                        residentId: selectedResidentId!,
                      );

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Resident removed successfully'),
                            ),
                          );
                          _loadFlats();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to remove resident'),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show Change Status Dialog
  void _showChangeStatusDialog(FlatModel flat) {
    String selectedStatus = flat.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Flat Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flat: ${flat.flatNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Vacant'),
                value: 'vacant',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
                activeColor: const Color(0xFF10B981),
              ),
              RadioListTile<String>(
                title: const Text('Occupied'),
                value: 'occupied',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
                activeColor: const Color(0xFF3B82F6),
              ),
              RadioListTile<String>(
                title: const Text('Maintenance'),
                value: 'maintenance',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
                activeColor: const Color(0xFFF97316),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final success = await _flatService.updateFlatStatus(
                  flat.id,
                  selectedStatus,
                );

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully'),
                      ),
                    );
                    _loadFlats();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update status')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E4778),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
