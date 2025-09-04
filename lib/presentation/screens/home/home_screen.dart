import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/parking_hours_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAnalyzing = false;

  // Mock data for nearby parking lots
  final List<ParkingLot> _nearbyParking = [
    ParkingLot(
      id: 1,
      name: 'Bãi xe Đại học Khoa học Tự nhiên',
      address: '144 Trần Đại Nghĩa, Quận Nhật',
      latitude: 10.8231,
      longitude: 106.6297,
      pricePerHour: 15000,
      totalSlots: 50,
      availableSlots: 12,
      rating: 4.1,
      reviewCount: 127,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ 24/7'],
      description: 'Bãi đậu xe an toàn gần đại học',
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
      name: 'Bãi xe Nguyễn Đình Chiểu',
      address: '283 Nguyễn Đình Chiểu, Q3',
      latitude: 10.7798,
      longitude: 106.6879,
      pricePerHour: 20000,
      totalSlots: 35,
      availableSlots: 8,
      rating: 4.3,
      reviewCount: 89,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ 24/7', 'Mái che'],
      description: 'Bãi đậu xe trung tâm quận 3',
      operatingHours: ParkingHours(
        monday: '06:00 - 23:00',
        tuesday: '06:00 - 23:00',
        wednesday: '06:00 - 23:00',
        thursday: '06:00 - 23:00',
        friday: '06:00 - 23:00',
        saturday: '06:00 - 23:00',
        sunday: '06:00 - 23:00',
      ),
      isOpen: true,
      distance: 300,
    ),
  ];

  int? _selectedParkingId;
  ParkingLot? _selectedParking;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      
        child: Column(
          children: [
            // Header Section
            Container(
              decoration: AppThemes.gradientBackground,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Top Bar with User Info
                    _buildTopBar(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Map Section
            Expanded(
              child: Stack(
                children: [
                  // Map Placeholder with Parking Markers
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.mapBackground,
                    ),
                    child: Stack(
                      children: [
                        // Map markers
                        ..._nearbyParking.asMap().entries.map((entry) {
                          final index = entry.key;
                          final parking = entry.value;
                          return Positioned(
                            top: 100.0 + (index * 100),
                            left: 50.0 + (index * 30),
                            child: _buildMapMarker(
                              available: parking.hasAvailableSlots,
                              parking: parking,
                              onTap: () => _selectParking(parking),
                            ),
                          );
                        }).toList(),

                        // Center location indicator
                        Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.white, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vehicle Card Overlay
                  if (_selectedParking != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildVehicleCard(parking: _selectedParking!),
                    ),

                  // Quick Actions at Bottom
                  Positioned(
                    bottom: 80, // Moved up to make room for search bar
                    left: 16,
                    right: 16,
                    child: _buildQuickActions(),
                  ),

                  // Search Bar at Bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildSearchBar(),
                  ),

                  // AI Analysis Button (animated)
                  if (_isAnalyzing)
                    Positioned(
                      bottom: 160, // Adjusted position
                      left: 0,
                      right: 0,
                      child: _buildAIAnalysisButton(),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    
  }

  Widget _buildTopBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Row(
          children: [
            // Menu Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.white,
                  size: 20,
                ),
               onPressed: () {
  print('Menu button pressed!'); // Debug print 1
  final ScaffoldState? scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
  print('ScaffoldState found: ${scaffoldState != null}'); // Debug print 2
  if (scaffoldState != null) {
    print('Attempting to open drawer...'); // Debug print 3
    scaffoldState.openDrawer();
    print('openDrawer() called'); // Debug print 4
  } else {
    print('ScaffoldState is null!'); // Debug print 5
  }
},
              ),
            ),

            const SizedBox(width: 12),

            const Spacer(),

            // Map Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.map,
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            const SizedBox(width: 12),

            // User Avatar
            GestureDetector(
              onTap: () {
                // TODO: Navigate to profile
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.white.withOpacity(0.2),
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapMarker({
    required bool available,
    required VoidCallback onTap,
    required ParkingLot parking,
  }) {
    final bool isSelected = _selectedParking?.id == parking.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error
              : (available ? AppColors.success : AppColors.error),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (isSelected
                      ? AppColors.error
                      : (available ? AppColors.success : AppColors.error))
                  .withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _selectParking(ParkingLot parking) {
    setState(() {
      // Toggle selection - if same parking is clicked, clear selection
      _selectedParking = _selectedParking?.id == parking.id ? null : parking;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchLocation,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: AppThemes.bodyMedium,
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/search');
              },
              readOnly: true,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement voice search
            },
            icon: const Icon(
              Icons.mic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({ParkingLot? parking}) {
    final selectedParking = parking ??
        _nearbyParking.firstWhere(
          (p) => p.id == _selectedParkingId,
          orElse: () => _nearbyParking.first,
        );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/parking-detail',
          arguments: selectedParking,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bãi đậu xe',
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    selectedParking.name,
                    style: AppThemes.headingMedium.copyWith(
                      color: AppColors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: Icons.home,
          label: AppStrings.nearby,
          color: AppColors.primary,
          onTap: () {
            _triggerAIAnalysis();
          },
        ),
        _buildQuickActionButton(
          icon: Icons.directions_car,
          label: 'Chợ',
          color: AppColors.info,
        ),
        _buildQuickActionButton(
          icon: Icons.fitness_center,
          label: 'Gym',
          color: AppColors.warning,
        ),
        _buildQuickActionButton(
          icon: Icons.account_balance,
          label: 'Bank',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ??
          () {
            // TODO: Implement quick action navigation
          },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppThemes.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisButton() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'I am analyzing your location',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerAIAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });

    // Simulate AI analysis
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showAIResult();
      }
    });
  }

  void _showAIResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Analysis Result',
              style: AppThemes.headingSmall,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is the best car park near your location!',
              style: AppThemes.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_nearbyParking.isNotEmpty) ...[
              Text(
                'Recommended:',
                style:
                    AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nearbyParking.first.name,
                      style: AppThemes.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_nearbyParking.first.availableSlots} slots available',
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      _nearbyParking.first.priceText,
                      style: AppThemes.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_nearbyParking.isNotEmpty) {
                Navigator.of(context).pushNamed(
                  '/parking-detail',
                  arguments: _nearbyParking.first,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showParkingDetails() {
    if (_nearbyParking.isNotEmpty) {
      Navigator.of(context).pushNamed(
        '/parking-detail',
        arguments: _nearbyParking.first,
      );
    }
  }
}
