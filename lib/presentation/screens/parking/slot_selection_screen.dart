import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/services/parking_slot_service.dart';

class SlotSelectionScreen extends StatefulWidget {
  final ParkingLot parkingLot;

  const SlotSelectionScreen({super.key, required this.parkingLot});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  ParkingSlot? selectedSlot;
  final ParkingSlotService _slotService = ParkingSlotService();
  List<ParkingSlot> slots = [];
  bool _loading = false;
  String? _error;
  
  // Filter states
  String? _selectedSlotType;
  String? _selectedFloor;
  
  // Filter options
  final List<String> _slotTypes = ['standard', 'large'];
  final List<String> _floors = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    print('=== SLOT SELECTION SCREEN INIT ===');
    print('Parking Lot: ${widget.parkingLot}');
    print('Parking Lot ID: ${widget.parkingLot.id}');
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() { _loading = true; _error = null; });
    try {
      print('=== FETCHING SLOTS ===');
      print('Parking Lot ID: ${widget.parkingLot.id}');
      print('Selected Slot Type: $_selectedSlotType');
      print('Selected Floor: $_selectedFloor');
      
      final list = await _slotService.searchSlots(
        lotId: widget.parkingLot.id,
        slotType: _selectedSlotType,
        floor: _selectedFloor,
        pageSize: 100,
      );
      
      print('=== SLOTS RECEIVED ===');
      print('Number of slots: ${list.length}');
      print('Slots: $list');
      
      setState(() { slots = list; });
    } catch (e) {
      print('=== ERROR FETCHING SLOTS ===');
      print('Error: $e');
      setState(() { _error = 'Không tải được danh sách chỗ đậu: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkGrey),
        ),
        title: Text(
          'Chọn chỗ đậu',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Legend
          _buildLegend(),
          
          // Filters
          _buildFilters(),
          
          // Slot Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : Column(
                          children: [
                            _buildSlotGrid(),
                            const SizedBox(height: 20),
                            if (selectedSlot != null) _buildSelectedSlotInfo(),
                          ],
                        ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: selectedSlot != null ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Trống', AppColors.available),
          _buildLegendItem('Đang bận', AppColors.occupied),
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
          style: AppThemes.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bộ lọc',
            style: AppThemes.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Slot Type Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại chỗ đậu',
                      style: AppThemes.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedSlotType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Tất cả'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tất cả'),
                        ),
                        ..._slotTypes.map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type == 'standard' ? 'Tiêu chuẩn' : 'Lớn'),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSlotType = value;
                        });
                        _fetchSlots();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Floor Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tầng',
                      style: AppThemes.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedFloor,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Tất cả'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tất cả'),
                        ),
                        ..._floors.map((floor) => DropdownMenuItem<String>(
                          value: floor,
                          child: Text('Tầng $floor'),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFloor = value;
                        });
                        _fetchSlots();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGrid() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return _buildSlotItem(slot);
        },
      ),
    );
  }

  Widget _buildSlotItem(ParkingSlot slot) {
    final isSelected = selectedSlot?.id == slot.id;
    final canSelect = slot.status == SlotStatus.available;
    
    Color getSlotColor() {
      if (isSelected) return AppColors.primary;
      switch (slot.status) {
        case SlotStatus.available: return AppColors.available;
        case SlotStatus.occupied: return AppColors.occupied;
        case SlotStatus.reserved: return AppColors.occupied; // Treat reserved as busy
        case SlotStatus.maintenance: return AppColors.occupied; // Treat maintenance as busy
      }
    }

    Color getIconColor() {
      if (isSelected) return AppColors.white;
      switch (slot.status) {
        case SlotStatus.available: return AppColors.white;
        case SlotStatus.occupied: return AppColors.white;
        case SlotStatus.reserved: return AppColors.white;
        case SlotStatus.maintenance: return AppColors.white;
      }
    }

    return GestureDetector(
      onTap: canSelect ? () => _selectSlot(slot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: getSlotColor(),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Car Icon
            Icon(
              Icons.directions_car,
              size: 32,
              color: getIconColor(),
            ),
            const SizedBox(height: 8),
            // Slot Number
            Text(
              slot.slotNumber,
              style: AppThemes.bodyMedium.copyWith(
                color: getIconColor(),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSlotInfo() {
    if (selectedSlot == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_parking,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỗ đậu ${selectedSlot!.slotNumber}',
                  style: AppThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  selectedSlot!.status == SlotStatus.available ? 'Trống' : 'Đang bận',
                  style: AppThemes.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: 'Tiếp tục',
          onPressed: () => _navigateToOrderDetail(),
          width: double.infinity,
        ),
      ),
    );
  }

  void _selectSlot(ParkingSlot slot) {
    setState(() {
      selectedSlot = slot;
    });
  }

  void _navigateToOrderDetail() {
    Navigator.of(context).pushNamed(
      '/order-detail',
      arguments: {
        'parkingLot': widget.parkingLot,
        'selectedSlot': selectedSlot,
      },
    );
  }
}