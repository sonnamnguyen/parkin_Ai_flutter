import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    
                    const SizedBox(height: 24),
                    
                    // Vehicle Selection Card
                    _buildVehicleCard(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Map Section
            Expanded(
              child: Stack(
                children: [
                  // Map Placeholder
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.mapBackground,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Map will be integrated here',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Google Maps integration coming soon',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Search Bar Overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildSearchBar(),
                  ),
                  
                  // Quick Actions at Bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildQuickActions(),
                  ),
                  
                  // AI Analysis Button (when needed)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: _buildAIAnalysisButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Row(
          children: [
            // Map/Menu Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu,
                color: AppColors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Location Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.white,
                size: 20,
              ),
            ),
            
            const Spacer(),
            
            // Map Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppStrings.map,
                style: AppThemes.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // User Avatar
            CircleAvatar(
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
          ],
        );
      },
    );
  }

  Widget _buildVehicleCard() {
    return Container(
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
                  'Nguyễn Đình Chiểu',
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
    );
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
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: AppThemes.bodyMedium,
              ),
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

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: Icons.home,
          label: AppStrings.nearby,
          color: AppColors.primary,
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
  }) {
    return GestureDetector(
      onTap: () {
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
      child: GestureDetector(
        onTap: () {
          // TODO: Implement AI analysis
          _showAIAnalysisDialog();
        },
        child: Container(
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
      ),
    );
  }

  void _showAIAnalysisDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Analysis'),
        content: const Text('This is the best car park near your location!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}