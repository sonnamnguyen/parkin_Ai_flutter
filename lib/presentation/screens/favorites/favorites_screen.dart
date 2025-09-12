import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/favorite_service.dart';
import '../../../data/models/favorite_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _service = FavoriteService();
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
                      return ListTile(
                        tileColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(item.lotName, style: AppThemes.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(item.lotAddress, style: AppThemes.bodyMedium),
                        onTap: () => _showDetail(item),
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
}


