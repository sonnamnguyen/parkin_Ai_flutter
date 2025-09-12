import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_order_model.dart';
import '../../../core/services/parking_order_service.dart';
import '../../widgets/common/custom_button.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ParkingOrderService _orderService = ParkingOrderService();
  List<ParkingOrder> orders = [];
  bool _loading = false;
  String? _error;
  
  // Filter states
  String? _selectedStatus;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  
  // Filter options
  final List<String> _statusOptions = ['pending', 'confirmed', 'cancelled', 'completed', 'expired'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        orders.clear();
        _hasMore = true;
      });
    }
    
    setState(() { _loading = true; _error = null; });
    
    try {
      print('=== LOADING ORDERS ===');
      print('Page: $_currentPage');
      print('Status filter: $_selectedStatus');
      
      final response = await _orderService.getOrderHistory(
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      print('=== ORDERS LOADED ===');
      print('Number of orders: ${response.orders.length}');
      print('Total: ${response.total}');
      
      setState(() {
        if (refresh) {
          orders = response.orders;
        } else {
          orders.addAll(response.orders);
        }
        _hasMore = orders.length < response.total;
        _currentPage++;
      });
    } catch (e) {
      print('=== ERROR LOADING ORDERS ===');
      print('Error: $e');
      setState(() { _error = 'Không tải được lịch sử đặt chỗ: $e'; });
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
          'Lịch sử đặt chỗ',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter section
          _buildFilters(),
          
          // Orders list
          Expanded(
            child: _loading && orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : orders.isEmpty
                        ? const Center(child: Text('Không có lịch sử đặt chỗ'))
                        : RefreshIndicator(
                            onRefresh: () => _loadOrders(refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == orders.length) {
                                  return _buildLoadMoreButton();
                                }
                                return _buildOrderItem(orders[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            hint: const Text('Tất cả trạng thái'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tất cả trạng thái'),
              ),
              ..._statusOptions.map((status) => DropdownMenuItem<String>(
                value: status,
                child: Text(_getStatusText(status)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _loadOrders(refresh: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(ParkingOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn hàng #${order.id}',
                style: AppThemes.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(order.status.name),
                  style: AppThemes.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order.lotName != null)
            Text(
              'Bãi đỗ: ${order.lotName}',
              style: AppThemes.bodyMedium,
            ),
          if (order.slotCode != null)
            Text(
              'Chỗ đậu: ${order.slotCode}',
              style: AppThemes.bodyMedium,
            ),
          if (order.vehicleLicensePlate != null)
            Text(
              'Biển số: ${order.vehicleLicensePlate}',
              style: AppThemes.bodyMedium,
            ),
          const SizedBox(height: 8),
          Text(
            'Thời gian: ${_formatDateTime(order.startTime)} - ${_formatDateTime(order.endTime)}',
            style: AppThemes.bodySmall.copyWith(
              color: AppColors.darkGrey,
            ),
          ),
          if (order.totalAmount != null)
            Text(
              'Tổng tiền: ${order.totalAmount!.toStringAsFixed(0)} VNĐ',
              style: AppThemes.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Xem chi tiết',
                  onPressed: () => _viewOrderDetail(order.id),
                  width: double.infinity,
                ),
              ),
              if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed)
                const SizedBox(width: 12),
              if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed)
                Expanded(
                  child: CustomButton(
                    text: 'Hủy',
                    onPressed: () => _cancelOrder(order.id),
                    width: double.infinity,
                    backgroundColor: AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasMore
              ? CustomButton(
                  text: 'Tải thêm',
                  onPressed: () => _loadOrders(),
                  width: double.infinity,
                )
              : const SizedBox(),
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

  void _viewOrderDetail(int orderId) {
    Navigator.of(context).pushNamed(
      '/order-view',
      arguments: {'orderId': orderId},
    );
  }

  void _cancelOrder(int orderId) {
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
                await _orderService.cancelOrder(orderId);
                _loadOrders(refresh: true);
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
