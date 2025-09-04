// lib/presentation/screens/parking/parking_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../widgets/common/custom_button.dart';

class ParkingDetailScreen extends StatefulWidget {
  final ParkingLot parkingLot;

  const ParkingDetailScreen({super.key, required this.parkingLot});

  @override
  State<ParkingDetailScreen> createState() => _ParkingDetailScreenState();
}

class _ParkingDetailScreenState extends State<ParkingDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Image Header
          _buildImageHeader(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildParkingInfo(),
                  const SizedBox(height: 24),
                  _buildRating(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildAmenities(),
                  const SizedBox(height: 24),
                  _buildOperatingHours(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        image: DecorationImage(
          image: NetworkImage(widget.parkingLot.imageUrl),
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
                  
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: AppColors.darkGrey,
                      size: 20,
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

  Widget _buildParkingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.parkingLot.name,
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
                widget.parkingLot.address,
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
              text: '${widget.parkingLot.availableSlots} chỗ trống',
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _buildInfoChip(
              icon: Icons.attach_money,
              text: widget.parkingLot.priceText,
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

  Widget _buildRating() {
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
                widget.parkingLot.rating.toString(),
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
          '${widget.parkingLot.reviewCount} đánh giá',
          style: AppThemes.bodyMedium,
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // TODO: Navigate to reviews
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

  Widget _buildDescription() {
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
          widget.parkingLot.description,
          style: AppThemes.bodyMedium.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    if (widget.parkingLot.amenities.isEmpty) return const SizedBox();
    
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
          children: widget.parkingLot.amenities.map((amenity) {
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

  Widget _buildOperatingHours() {
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
                widget.parkingLot.isOpen ? Icons.access_time : Icons.access_time_filled,
                color: widget.parkingLot.isOpen ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.parkingLot.isOpen ? 'Đang mở cửa' : 'Đã đóng cửa',
                style: AppThemes.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.parkingLot.isOpen ? AppColors.success : AppColors.error,
                ),
              ),
              const Spacer(),
              Text(
                widget.parkingLot.operatingHours.getTodayHours(),
                style: AppThemes.bodyMedium,
              ),
            ],
          ),
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
                Text(
                  widget.parkingLot.priceText,
                  style: AppThemes.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: CustomButton(
                text: 'Đặt chỗ ngay',
                onPressed: widget.parkingLot.hasAvailableSlots 
                    ? () => _navigateToSlotSelection() 
                    : null,
                backgroundColor: widget.parkingLot.hasAvailableSlots 
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
    Navigator.of(context).pushNamed(
      '/select-slot',
      arguments: widget.parkingLot,
    );
  }
}
