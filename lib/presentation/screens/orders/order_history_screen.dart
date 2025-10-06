import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/parking_lot_service.dart';
import '../../../core/services/parking_order_service.dart';
import '../../../data/models/parking_order_model.dart';
import '../../../routes/app_routes.dart';
import '../main/main_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ParkingOrderService _orderService = ParkingOrderService();
  final ScrollController _scrollController = ScrollController();

  List<ParkingOrder> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _orders = [];
      });
    }
    setState(() => _isLoading = _orders.isEmpty);
    final res = await _orderService.getOrderHistory(
      // TODO: get current user id from auth provider/storage
      userId: null,
      page: _page,
      pageSize: _pageSize,
    );
    setState(() {
      if (refresh || _page == 1) {
        _orders = res.orders;
      } else {
        _orders.addAll(res.orders);
      }
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _isLoadingMore = true;
      _page += 1;
      _load();
    }
  }

  Future<void> _deleteOrder(ParkingOrder order) async {
    await _orderService.deleteOrder(order.id);
    setState(() {
      _orders.removeWhere((o) => o.id == order.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa đơn đặt chỗ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử đơn', style: TextStyle(color: Colors.black)),
        leading: Navigator.of(context).canPop() ? const BackButton(color: Colors.black) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.main),
            tooltip: 'Trang chủ',
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Dismissible(
                    key: ValueKey(order.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteOrder(order),
                    child: _OrderTile(order: order),
                  );
                },
              ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final ParkingOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(order.lotName ?? 'Bãi đỗ #${order.lotId}', style: AppThemes.bodyLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Chỗ: ${order.slotCode ?? order.slotId} • Giá: ${_formatVnd(order.totalAmount)}'),
            const SizedBox(height: 4),
            Text('Thời gian: ${order.startTime} - ${order.endTime}'),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    debugPrint('=== CHỈ ĐƯỜNG DEBUG START ===');
                    debugPrint('Order lotId: ${order.lotId}');
                    debugPrint('Order lotName: ${order.lotName}');
                    
                    final lotService = ParkingLotService();
                    final lot = await lotService.getParkingLotDetail(order.lotId);
                    debugPrint('Fetched lot details: ${lot.name}');
                    debugPrint('Lot coordinates: lat=${lot.latitude}, lng=${lot.longitude}');
                    
                    if (context.mounted) {
                      debugPrint('Navigating to main with open_lot_id: ${order.lotId}');
                      
                      // Store the lot ID globally and navigate
                      MainScreen.setPendingLotId(order.lotId);
                      
                      Navigator.of(context).pushReplacementNamed(
                        AppRoutes.main,
                      );
                      
                      debugPrint('Navigation completed');
                    }
                    debugPrint('=== CHỈ ĐƯỜNG DEBUG END ===');
                  } catch (e) {
                    debugPrint('=== CHỈ ĐƯỜNG ERROR ===');
                    debugPrint('Error: $e');
                    debugPrint('Error type: ${e.runtimeType}');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi lấy vị trí bãi đỗ: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Chỉ đường'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatVnd(double? amount) {
  if (amount == null) return '— VND';
  final intValue = amount.toInt();
  final str = intValue.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    buffer.write(str[i]);
    final posFromEnd = str.length - i - 1;
    if (posFromEnd % 3 == 0 && posFromEnd != 0) buffer.write(',');
  }
  return '${buffer.toString()} VND';
}


