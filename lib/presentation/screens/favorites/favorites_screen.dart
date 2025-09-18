import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/favorite_service.dart';
import '../../../data/models/favorite_model.dart';
import '../../../core/services/parking_lot_service.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../routes/app_routes.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _service = FavoriteService();
  final ParkingLotService _lotService = ParkingLotService();
  List<FavoriteItem> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _service.getFavorites(page: 1, pageSize: 20);
      setState(() { _items = resp.list; });
    } catch (e) {
      setState(() { _error = 'Không tải được danh sách yêu thích'; });
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
          'Yêu thích',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _navigateToDetail(item),
                          child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_parking, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.lotName,
                                      style: AppThemes.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.lotAddress,
                                      style: AppThemes.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _navigateToDetail(item),
                                          icon: const Icon(Icons.visibility_outlined),
                                          label: const Text('Xem chi tiết'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _delete(item),
                                          icon: const Icon(Icons.delete_outline),
                                          label: const Text('Xóa'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _showDetail(FavoriteItem item) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.lotName),
        content: Text(item.lotAddress),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _delete(item);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(FavoriteItem item) async {
    try {
      await _service.deleteFavorite(item.id);
      if (!mounted) return;
      setState(() { _items.removeWhere((e) => e.id == item.id); });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa khỏi yêu thích')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e')),
      );
    }
  }

  Future<void> _navigateToDetail(FavoriteItem item) async {
    try {
      setState(() { _loading = true; });
      final ParkingLot lot = await _lotService.getParkingLotDetail(item.lotId);
      if (!mounted) return;
      setState(() { _loading = false; });
      // Navigate to parking lot detail screen
      Navigator.of(context).pushNamed(AppRoutes.parkingDetail, arguments: lot);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được chi tiết: $e')),
      );
    }
  }
}


