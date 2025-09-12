import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_order_model.dart';
import '../../../core/services/parking_order_service.dart';
import '../../widgets/common/custom_button.dart';

class OrderViewScreen extends StatefulWidget {
  final int orderId;

  const OrderViewScreen({super.key, required this.orderId});

  @override
  State<OrderViewScreen> createState() => _OrderViewScreenState();
}

class _OrderViewScreenState extends State<OrderViewScreen> {
  final ParkingOrderService _orderService = ParkingOrderService();
  ParkingOrder? order;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() { _loading = true; _error = null; });
    
    try {
      print('=== LOADING ORDER DETAIL ===');
      print('Order ID: ${widget.orderId}');
      
      final orderDetail = await _orderService.getOrderDetail(widget.orderId);
      
      print('=== ORDER DETAIL LOADED ===');
      print('Order: $orderDetail');
      
      setState(() { order = orderDetail; });
    } catch (e) {
      print('=== ERROR LOADING ORDER DETAIL ===');
      print('Error: $e');
      setState(() { _error = 'Không tải được chi tiết đơn đặt chỗ: $e'; });
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
          'Chi tiết đơn đặt chỗ',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : order == null
                  ? const Center(child: Text('Không tìm thấy đơn đặt chỗ'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildOrderInfo(),
                          const SizedBox(height: 24),
                          _buildOrderDetails(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOrderInfo() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn hàng #${order!.id}',
                style: AppThemes.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order!.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStatusText(order!.status.name),
                  style: AppThemes.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (order!.createdAt != null)
            Text(
              'Ngày tạo: ${_formatDateTime(order!.createdAt!)}',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.darkGrey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
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
            'Thông tin đặt chỗ',
            style: AppThemes.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Bãi đỗ xe', order!.lotName ?? 'Không xác định'),
          _buildDetailRow('Chỗ đậu', order!.slotCode ?? 'Không xác định'),
          _buildDetailRow('Biển số xe', order!.vehicleLicensePlate ?? 'Không xác định'),
          _buildDetailRow('Thời gian bắt đầu', _formatDateTime(order!.startTime)),
          _buildDetailRow('Thời gian kết thúc', _formatDateTime(order!.endTime)),
          if (order!.totalAmount != null)
            _buildDetailRow('Tổng tiền', '${order!.totalAmount!.toStringAsFixed(0)} VNĐ'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppThemes.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (order!.status == OrderStatus.pending || order!.status == OrderStatus.confirmed)
          CustomButton(
            text: 'Hủy đơn đặt chỗ',
            onPressed: () => _cancelOrder(),
            width: double.infinity,
            backgroundColor: AppColors.error,
          ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
          width: double.infinity,
          backgroundColor: AppColors.lightGrey,
          textColor: AppColors.darkGrey,
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'cancelled': return 'Đã hủy';
      case 'completed': return 'Hoàn thành';
      case 'expired': return 'Hết hạn';
      default: return status;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return AppColors.warning;
      case OrderStatus.confirmed: return AppColors.success;
      case OrderStatus.cancelled: return AppColors.error;
      case OrderStatus.completed: return AppColors.primary;
      case OrderStatus.expired: return AppColors.darkGrey;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final DateTime date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn đặt chỗ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _orderService.cancelOrder(order!.id);
                _loadOrderDetail(); // Reload to update status
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã hủy đơn đặt chỗ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi hủy đơn: $e')),
                );
              }
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }
}
