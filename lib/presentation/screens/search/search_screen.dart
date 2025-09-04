import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../data/models/parking_hours_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'Bãi xe Lê Văn Tám',
    'Bãi xe Bến Thành',
    'Bãi xe Quận 1',
  ];

  final List<ParkingLot> _nearbyParking = [
    ParkingLot(
      id: 1,
      name: 'Bãi xe Lê Văn Tám',
      address: 'Cần 29 nhà',
      latitude: 10.8231,
      longitude: 106.6297,
      pricePerHour: 15000,
      totalSlots: 50,
      availableSlots: 12,
      rating: 4.5,
      reviewCount: 127,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ 24/7'],
      description: 'Bãi đậu xe an toàn, tiện lợi',
      operatingHours: ParkingHours(
        monday: '06:00 - 22:00',
        tuesday: '06:00 - 22:00',
        wednesday: '06:00 - 22:00',
        thursday: '06:00 - 22:00',
        friday: '06:00 - 22:00',
        saturday: '06:00 - 22:00',
        sunday: '06:00 - 22:00',
      ),
      isOpen: true,
      distance: 500,
    ),
    ParkingLot(
      id: 2,
      name: 'Bãi xe Bến Thành',
      address: 'Cần 10 nhà',
      latitude: 10.8231,
      longitude: 106.6297,
      pricePerHour: 20000,
      totalSlots: 30,
      availableSlots: 5,
      rating: 4.1,
      reviewCount: 89,
      imageUrl: '',
      amenities: ['CCTV'],
      description: 'Gần chợ Bến Thành',
      operatingHours: ParkingHours(
        monday: '06:00 - 22:00',
        tuesday: '06:00 - 22:00',
        wednesday: '06:00 - 22:00',
        thursday: '06:00 - 22:00',
        friday: '06:00 - 22:00',
        saturday: '06:00 - 22:00',
        sunday: '06:00 - 22:00',
      ),
      isOpen: true,
      distance: 750,
    ),
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
          'Tìm kiếm',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.mic, color: AppColors.darkGrey),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm điểm đến của bạn',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Searches
                  if (_recentSearches.isNotEmpty) ...[
                    _buildSectionHeader('Tìm kiếm gần đây'),
                    ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
                    const SizedBox(height: 24),
                  ],

                  // Nearby Section
                  _buildSectionHeader('NEARBY'),
                  ..._nearbyParking.map((parking) => _buildParkingItem(parking)),
                  
                  const SizedBox(height: 24),
                  
                  // Suggestions Section  
                  _buildSectionHeader('NEARBY'),
                  _buildCategoryGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppThemes.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.history,
        color: AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        search,
        style: AppThemes.bodyMedium,
      ),
      trailing: IconButton(
        onPressed: () {
          // Remove from recent searches
        },
        icon: const Icon(
          Icons.close,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
      onTap: () {
        _searchController.text = search;
      },
    );
  }

  Widget _buildParkingItem(ParkingLot parking) {
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_parking,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parking.name,
                  style: AppThemes.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  parking.address,
                  style: AppThemes.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      parking.distanceText,
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${parking.availableSlots} chỗ trống',
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            parking.priceText,
            style: AppThemes.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.restaurant, 'name': 'Nhà hàng', 'color': AppColors.error},
      {'icon': Icons.local_hospital, 'name': 'Bệnh viện', 'color': AppColors.info},
      {'icon': Icons.school, 'name': 'Trường học', 'color': AppColors.warning},
      {'icon': Icons.shopping_cart, 'name': 'Mua sắm', 'color': AppColors.success},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: category['color'] as Color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['name'] as String,
                  style: AppThemes.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}