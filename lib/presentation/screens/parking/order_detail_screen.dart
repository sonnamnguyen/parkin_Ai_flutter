import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../../data/models/parking_order_model.dart';
import '../../../core/services/parking_order_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/services/vehicle_service.dart';
import '../../../data/models/vehicle_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final ParkingLot parkingLot;
  final ParkingSlot selectedSlot;

  const OrderDetailScreen({
    super.key,
    required this.parkingLot,
    required this.selectedSlot,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ParkingOrderService _orderService = ParkingOrderService();
  final VehicleService _vehicleService = VehicleService();
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0);
  // Removed scheduling feature per request
  bool _creating = false;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _loadingVehicles = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() { _loadingVehicles = true; });
    try {
      final resp = await _vehicleService.getVehicles(pageSize: 50);
      setState(() {
        _vehicles = resp.list;
        if (_vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.first;
        }
      });
    } catch (e) {
      // show silent error
    } finally {
      if (mounted) setState(() { _loadingVehicles = false; });
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
          'Chi tiết đơn đặt chỗ',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParkingInfo(),
            const SizedBox(height: 24),
            _buildTimeSelector(),
            const SizedBox(height: 24),
            _buildVehicleSelector(),
            const SizedBox(height: 24),
            _buildPricingDetails(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildParkingInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_parking,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.parkingLot.name,
                      style: AppThemes.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.parkingLot.address,
                      style: AppThemes.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Chỗ đậu ${widget.selectedSlot.slotNumber}',
                        style: AppThemes.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Thời gian',
            style: AppThemes.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildQuickTimeSelector(),
          const SizedBox(height: 16),
          _buildDatePicker(),
        ],
      ),
    );
  }

  Widget _buildQuickTimeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTimeCard(
                label: 'Từ',
                time: startTime,
                onTap: () => _selectTime(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeCard(
                label: 'Đến',
                time: endTime,
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDurationInfo(),
      ],
    );
  }

  // Removed schedule selector

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
              style: AppThemes.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppThemes.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')} : ${time.minute.toString().padLeft(2, '0')}',
              style: AppThemes.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationInfo() {
    final duration = Duration(
      hours: endTime.hour - startTime.hour,
      minutes: endTime.minute - startTime.minute,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Thời gian đậu xe: ${duration.inHours}h ${duration.inMinutes % 60}m',
        style: AppThemes.bodySmall.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Dịch vụ đặt xe',
            style: AppThemes.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _loadingVehicles
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<Vehicle>(
                  value: _selectedVehicle,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  hint: const Text('Chọn xe của bạn'),
                  items: _vehicles.map((v) => DropdownMenuItem<Vehicle>(
                    value: v,
                    child: Text('${v.displayName} • ${v.licensePlate}'),
                  )).toList(),
                  onChanged: (v) => setState(() { _selectedVehicle = v; }),
                ),
        ],
      ),
    );
  }

  Widget _buildPricingDetails() {
    final duration = Duration(
      hours: endTime.hour - startTime.hour,
      minutes: endTime.minute - startTime.minute,
    );
    final totalCost = widget.parkingLot.pricePerHour * duration.inHours;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Tổng cộng',
            style: AppThemes.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(
            'Giá đậu xe (${duration.inHours}h)',
            '${totalCost.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )} VNĐ',
          ),
          const Divider(height: 24),
          _buildPriceRow(
            'Tổng cộng',
            '${totalCost.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )} VNĐ',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      children: [
        Text(
          label,
          style: isTotal 
              ? AppThemes.bodyLarge.copyWith(fontWeight: FontWeight.bold)
              : AppThemes.bodyMedium,
        ),
        const Spacer(),
        Text(
          price,
          style: isTotal 
              ? AppThemes.headingSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                )
              : AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
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
          text: _creating ? 'Đang tạo đơn...' : 'Xác nhận & Thanh toán',
          onPressed: _creating ? null : () => _navigateToPayment(),
          width: double.infinity,
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime : endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime first = DateTime(now.year, now.month, now.day);
    final DateTime last = now.add(const Duration(days: 30));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() { selectedDate = picked; });
    }
  }

  // Removed navigate to schedule

  Future<void> _navigateToPayment() async {
    if (_creating) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn xe trước khi đặt chỗ')),
      );
      return;
    }
    
    setState(() { _creating = true; });
    
    try {
      print('=== CREATING PARKING ORDER ===');
      
      // Create start and end DateTime
      final DateTime startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );
      
      final DateTime endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );
      
      // Format dates for API
      final String startTimeStr = startDateTime.toIso8601String().replaceAll('T', ' ').substring(0, 19);
      final String endTimeStr = endDateTime.toIso8601String().replaceAll('T', ' ').substring(0, 19);
      
      print('Start time: $startTimeStr');
      print('End time: $endTimeStr');
      
      // Create order request
      final request = CreateOrderRequest(
        vehicleId: _selectedVehicle!.id,
        lotId: widget.parkingLot.id,
        slotId: int.parse(widget.selectedSlot.id),
        startTime: startTimeStr,
        endTime: endTimeStr,
      );
      
      // Create the order
      final order = await _orderService.createOrder(request);
      
      print('=== ORDER CREATED ===');
      print('Order ID: ${order.id}');
      
      // Navigate to payment with order details
      Navigator.of(context).pushNamed('/payment', arguments: {
        'order': order,
        'parkingLot': widget.parkingLot,
        'selectedSlot': widget.selectedSlot,
      });
      
    } catch (e) {
      print('=== ERROR CREATING ORDER ===');
      print('Error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo đơn đặt chỗ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() { _creating = false; });
    }
  }
}
