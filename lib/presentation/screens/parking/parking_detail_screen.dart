// lib/presentation/screens/parking/parking_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../core/services/parking_lot_service.dart';
import '../../../core/services/favorite_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../../routes/app_routes.dart';

class ParkingDetailScreen extends StatefulWidget {
  final ParkingLot parkingLot;

  const ParkingDetailScreen({super.key, required this.parkingLot});

  @override
  State<ParkingDetailScreen> createState() => _ParkingDetailScreenState();
}

class _ParkingDetailScreenState extends State<ParkingDetailScreen> {
  final ParkingLotService _parkingLotService = ParkingLotService();
  ParkingLot? _currentParkingLot;
  bool _isLoading = false;
  String? _error;
  bool _isFavorite = false;
  int _retryCount = 0;
  static const int _maxRetry = 3;

  @override
  void initState() {
    super.initState();
    _currentParkingLot = widget.parkingLot;
    _loadParkingLotDetail();
    _loadFavoriteStatus();
  }

  Future<void> _loadParkingLotDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final parkingLot = await _parkingLotService.getParkingLotDetail(widget.parkingLot.id);
      setState(() {
        _currentParkingLot = parkingLot;
        _isLoading = false;
        _retryCount = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading parking lot detail: $e');
      // Auto retry on failure a few times (simulates pressing "Thử lại")
      if (mounted && _retryCount < _maxRetry) {
        _retryCount += 1;
        // Fast exponential backoff in milliseconds (e.g., 150ms, 300ms, 450ms)
        final int delayMs = 50 * _retryCount;
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (!mounted) return;
          _loadParkingLotDetail();
        });
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      // Optimistically check favorites list for this lot
      final favorites = await FavoriteService().getFavorites(lotName: _currentParkingLot?.name);
      final lotId = (_currentParkingLot ?? widget.parkingLot).id;
      final exists = favorites.list.any((f) => f.lotId == lotId);
      if (mounted) setState(() { _isFavorite = exists; });
    } catch (_) {
      // Ignore errors for status fetch
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkingLot = _currentParkingLot ?? widget.parkingLot;
    
    if (_isLoading) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải thông tin...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải thông tin',
                    style: AppThemes.headingMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadParkingLotDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
        children: [
          // Image Header
          _buildImageHeader(parkingLot),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildParkingInfo(parkingLot),
                  const SizedBox(height: 24),
                  _buildRating(parkingLot),
                  const SizedBox(height: 24),
                  _buildDescription(parkingLot),
                  const SizedBox(height: 24),
                  _buildAmenities(parkingLot),
                  const SizedBox(height: 24),
                  _buildOperatingHours(parkingLot),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: _buildBottomActionBar(parkingLot),
    );
  }

  Widget _buildImageHeader(ParkingLot parkingLot) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        image: DecorationImage(
          image: (parkingLot.imageUrl.isNotEmpty && parkingLot.imageUrl.startsWith('http'))
              ? NetworkImage(parkingLot.imageUrl)
              : const AssetImage('assets/images/parking_placeholder.jpg') as ImageProvider,
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          
          // App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.darkGrey,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Text(
                    'CHI TIẾT BÃI XE',
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  GestureDetector(
                    onTap: () async {
                      try {
                        if (_isFavorite) {
                          // Find the favorite id for this lot then delete
                          final list = await FavoriteService().getFavorites(

                            lotName: parkingLot.name,
                          );
                          final match = list.list.firstWhere(
                            (f) => f.lotId == parkingLot.id,
                            orElse: () => throw 'Không tìm thấy mục yêu thích',
                          );
                          await FavoriteService().deleteFavorite(match.id);
                          if (mounted) setState(() { _isFavorite = false; });
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa khỏi yêu thích')),
                          );
                        } else {
                          await FavoriteService().addFavorite(lotId: parkingLot.id);
                          if (mounted) setState(() { _isFavorite = true; });
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm vào yêu thích')),
                          );
                        }
                      } catch (e) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Thao tác yêu thích thất bại: $e')),
                        );
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : AppColors.darkGrey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingInfo(ParkingLot parkingLot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parkingLot.name,
          style: AppThemes.headingMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                parkingLot.address,
                style: AppThemes.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              icon: Icons.local_parking,
              text: '${parkingLot.availableSlots} chỗ trống',
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _buildInfoChip(
              icon: Icons.attach_money,
              text: parkingLot.formattedPrice,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppThemes.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(ParkingLot parkingLot) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                parkingLot.rating.toString(),
                style: AppThemes.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                color: AppColors.warning,
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${parkingLot.reviewCount} đánh giá',
          style: AppThemes.bodyMedium,
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed(
              AppRoutes.ratingComments,
              arguments: parkingLot,
            );
          },
          child: Text(
            'Xem đánh giá',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ParkingLot parkingLot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả',
          style: AppThemes.headingSmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          parkingLot.description,
          style: AppThemes.bodyMedium.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(ParkingLot parkingLot) {
    if (parkingLot.amenities.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiện ích',
          style: AppThemes.headingSmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: parkingLot.amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                amenity,
                style: AppThemes.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOperatingHours(ParkingLot parkingLot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giờ hoạt động',
          style: AppThemes.headingSmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(parkingLot),
                color: _getStatusColor(parkingLot),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _getStatusText(parkingLot),
                style: AppThemes.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(parkingLot),
                ),
              ),
              const Spacer(),
              Text(
                _getOperatingHoursText(parkingLot),
                style: AppThemes.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getOperatingHoursText(ParkingLot parkingLot) {
    // Check if we have valid operating hours
    if (parkingLot.openTime.isNotEmpty && parkingLot.closeTime.isNotEmpty) {
      // Check if both times are placeholder (15:04:05)
      if (parkingLot.openTime == '24/7' && parkingLot.closeTime == '24/7') {
        return '24/7';
      }
      
      // Check if times are the same (24/7 operation)
      if (parkingLot.openTime == parkingLot.closeTime) {
        return '24/7';
      }
      
      // Show normal hours
      return '${parkingLot.openTime} - ${parkingLot.closeTime}';
    }
    
    // Fallback to operating hours object if available
    if (parkingLot.operatingHours != null) {
      return parkingLot.operatingHours!.getTodayHours();
    }
    
    return 'N/A';
  }

  String _getStatusText(ParkingLot parkingLot) {
    // Check if it's 24/7 operation
    if (_is24Hours(parkingLot)) {
      return 'Luôn mở cửa';
    }
    
    // Regular status based on isOpen
    return parkingLot.isOpen ? 'Đang mở cửa' : 'Đã đóng cửa';
  }

  Color _getStatusColor(ParkingLot parkingLot) {
    // Check if it's 24/7 operation
    if (_is24Hours(parkingLot)) {
      return AppColors.success; // Green for always open
    }
    
    // Regular status color
    return parkingLot.isOpen ? AppColors.success : AppColors.error;
  }

  bool _is24Hours(ParkingLot parkingLot) {
    // Check if both times are placeholder (15:04:05) or formatted as 24/7
    if (parkingLot.openTime == '24/7' && parkingLot.closeTime == '24/7') {
      return true;
    }
    
    // Check if times are the same (24/7 operation)
    if (parkingLot.openTime == parkingLot.closeTime && parkingLot.openTime.isNotEmpty) {
      return true;
    }
    
    return false;
  }

  IconData _getStatusIcon(ParkingLot parkingLot) {
    // Check if it's 24/7 operation
    if (_is24Hours(parkingLot)) {
      return Icons.schedule; // Clock icon for 24/7
    }
    
    // Regular status icon
    return parkingLot.isOpen ? Icons.access_time : Icons.access_time_filled;
  }

  Widget _buildBottomActionBar(ParkingLot parkingLot) {
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
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá từ',
                  style: AppThemes.bodySmall,
                ),
                // Price shrinks if too long and uses integer formatting
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    parkingLot.priceText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemes.headingSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: CustomButton(
                text: 'Đặt chỗ ngay',
                onPressed: parkingLot.hasAvailableSlots 
                    ? () => _navigateToSlotSelection() 
                    : null,
                backgroundColor: parkingLot.hasAvailableSlots 
                    ? AppColors.primary 
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSlotSelection() {
    final parkingLot = _currentParkingLot ?? widget.parkingLot;
    Navigator.of(context).pushNamed(
      '/select-slot',
      arguments: parkingLot,
    );
  }
}
