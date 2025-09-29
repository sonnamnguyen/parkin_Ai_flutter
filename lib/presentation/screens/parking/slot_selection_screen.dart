import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/services/parking_slot_service.dart';
import '../../../core/services/other_services_service.dart';

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

  // Other services
  bool _showOtherServices = false;
  final OtherServicesService _otherService = OtherServicesService();
  List<OtherServiceItem> _otherServices = [];
  bool _loadingOtherServices = false;

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
      
      // Sort slots from first to last by slot number (natural ascending)
      list.sort((a, b) {
        int extractNum(String s) {
          final match = RegExp(r'\d+').firstMatch(s);
          return match != null ? int.parse(match.group(0)!) : 0;
        }
        final an = extractNum(a.slotNumber);
        final bn = extractNum(b.slotNumber);
        if (an != bn) return an.compareTo(bn);
        return a.slotNumber.compareTo(b.slotNumber);
      });
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
                            _buildOtherServicesToggle(),
                            const SizedBox(height: 8),
                            _buildSlotGrid(),
                            const SizedBox(height: 20),
                            if (selectedSlot != null) _buildSelectedSlotInfo(),
                            if (_showOtherServices) ...[
                              const SizedBox(height: 24),
                              _buildOtherServicesList(),
                            ],
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

  Widget _buildOtherServicesToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Dịch vụ khác tại bãi', style: AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        Switch(
          value: _showOtherServices,
          onChanged: (val) async {
            setState(() { _showOtherServices = val; });
            if (val && _otherServices.isEmpty) {
              setState(() { _loadingOtherServices = true; });
              try {
                final resp = await _otherService.getOtherServices(lotId: widget.parkingLot.id, isActive: true, page: 1, pageSize: 10);
                setState(() { _otherServices = resp.list; });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tải được dịch vụ khác: $e')));
                }
              } finally {
                if (mounted) setState(() { _loadingOtherServices = false; });
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildOtherServicesList() {
    if (_loadingOtherServices) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_otherServices.isEmpty) {
      return Text('Không có dịch vụ khác', style: AppThemes.bodyMedium.copyWith(color: AppColors.textSecondary));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _otherServices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final service = _otherServices[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: AppThemes.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(service.description, style: AppThemes.bodySmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Giá: ${service.price} VNĐ • ${service.durationMinutes} phút', style: AppThemes.bodySmall),
                  ],
                ),
              ),
              CustomButton(
                text: 'Đặt',
                onPressed: () => _orderOtherService(service),
                width: 100,
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _orderOtherService(OtherServiceItem service) async {
    try {
      // If parking order flow already has a selected time, reuse; else default now + 10 min
      final DateTime scheduled = DateTime.now().add(const Duration(minutes: 10));
      final String scheduledStr = scheduled.toIso8601String().replaceAll('T', ' ').substring(0, 19);

      // Need vehicle_id; navigate to pick if not available? For now, show error if missing
      // In a full flow, we would fetch user's default vehicle.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tạo đơn dịch vụ...')));

      // For MVP, require selectedSlot != null to infer lotId
      final lotId = widget.parkingLot.id;
      final vehicleId = 1; // TODO: integrate actual selected vehicle

      final orderId = await _otherService.createServiceOrder(
        vehicleId: vehicleId,
        lotId: lotId,
        serviceId: service.id,
        scheduledTime: scheduledStr,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã tạo đơn dịch vụ #$orderId')));
      // Navigate to payment screen using existing payment link flow
      Navigator.of(context).pushNamed('/payment', arguments: {
        'orderId': orderId,
        'checkoutUrl': '',
        'qrCode': '',
        'amount': service.price,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo đơn dịch vụ: $e')));
    }
  }
}