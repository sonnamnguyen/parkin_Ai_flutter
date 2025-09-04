import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../widgets/common/custom_button.dart';

class SlotSelectionScreen extends StatefulWidget {
  final ParkingLot parkingLot;

  const SlotSelectionScreen({super.key, required this.parkingLot});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  ParkingSlot? selectedSlot;
  
  // Mock data for slots
  final List<ParkingSlot> slots = [
    ParkingSlot(id: 'A01', lotId: 1, slotNumber: 'A01', status: SlotStatus.available, type: 'standard'),
    ParkingSlot(id: 'A02', lotId: 1, slotNumber: 'A02', status: SlotStatus.occupied, type: 'standard'),
    ParkingSlot(id: 'A03', lotId: 1, slotNumber: 'A03', status: SlotStatus.available, type: 'standard'),
    ParkingSlot(id: 'A04', lotId: 1, slotNumber: 'A04', status: SlotStatus.reserved, type: 'standard'),
    ParkingSlot(id: 'A05', lotId: 1, slotNumber: 'A05', status: SlotStatus.available, type: 'large'),
    ParkingSlot(id: 'A06', lotId: 1, slotNumber: 'A06', status: SlotStatus.available, type: 'standard'),
    ParkingSlot(id: 'B01', lotId: 1, slotNumber: 'B01', status: SlotStatus.occupied, type: 'standard'),
    ParkingSlot(id: 'B02', lotId: 1, slotNumber: 'B02', status: SlotStatus.available, type: 'standard'),
    ParkingSlot(id: 'B03', lotId: 1, slotNumber: 'B03', status: SlotStatus.maintenance, type: 'standard'),
    ParkingSlot(id: 'B04', lotId: 1, slotNumber: 'B04', status: SlotStatus.available, type: 'standard'),
  ];

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
          
          // Slot Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
          _buildLegendItem('Đã đậu', AppColors.occupied),
          _buildLegendItem('Đã đặt', AppColors.reserved),
          _buildLegendItem('Bảo trì', AppColors.maintenance),
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

  Widget _buildSlotGrid() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
        case SlotStatus.reserved: return AppColors.reserved;
        case SlotStatus.maintenance: return AppColors.maintenance;
      }
    }

    return GestureDetector(
      onTap: canSelect ? () => _selectSlot(slot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: getSlotColor(),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                slot.slotNumber,
                style: AppThemes.bodySmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (slot.type == 'large')
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 8,
                    color: AppColors.primary,
                  ),
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
                  selectedSlot!.type == 'large' ? 'Chỗ lớn' : 'Chỗ tiêu chuẩn',
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