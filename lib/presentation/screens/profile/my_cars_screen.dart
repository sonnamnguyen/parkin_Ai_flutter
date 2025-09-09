import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/vehicle_service.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/models/vehicle_list_response_model.dart';
import '../../widgets/common/custom_button.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final VehicleService _vehicleService = VehicleService();
  final List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalVehicles = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles({bool loadMore = false}) async {
    print('Loading vehicles - loadMore: $loadMore, currentPage: $_currentPage');
    
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _vehicles.clear();
      });
    }

    try {
      final response = await _vehicleService.getVehicles(
        type: 'car',
        page: _currentPage,
        pageSize: 10,
      );
      
      print('Received response: ${response.list.length} vehicles, total: ${response.total}');

      setState(() {
        if (loadMore) {
          _vehicles.addAll(response.list);
          _currentPage++;
        } else {
          _vehicles.clear();
          _vehicles.addAll(response.list);
          _currentPage = 2; // Next page for load more
        }
        
        _totalVehicles = response.total;
        _totalPages = (_totalVehicles / 10).ceil();
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách xe: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    try {
      await _vehicleService.deleteVehicle(vehicle.id);
      
      setState(() {
        _vehicles.removeWhere((v) => v.id == vehicle.id);
        _totalVehicles--;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa xe ${vehicle.brand} ${vehicle.model}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa xe: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          onPressed: () => Navigator.of(context).pushNamed('/main'),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkGrey),
        ),
        title: Text(
          AppStrings.myCars,
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with total count
            if (_totalVehicles > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Tổng cộng: $_totalVehicles xe',
                  style: AppThemes.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            
            // Cars List
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _vehicles.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _loadVehicles(),
                          child: ListView.builder(
                            itemCount: _vehicles.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _vehicles.length) {
                                // Load more when reaching the end
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _loadVehicles(loadMore: true);
                                });
                                return _buildLoadMoreIndicator();
                              }
                              final vehicle = _vehicles[index];
                              return _buildCarCard(vehicle, index);
                            },
                          ),
                        ),
            ),
            
            const SizedBox(height: 20),
            
            // Add Car Button
            CustomButton(
              text: 'Thêm xe mới',
              onPressed: _navigateToAddCar,
              width: double.infinity,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có xe nào',
            style: AppThemes.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm xe đầu tiên của bạn để bắt đầu',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Vehicle vehicle, int index) {
    // Colors for different car types
    final List<Color> cardColors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
    ];
    
    final cardColor = cardColors[index % cardColors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Car Icon/Brand Badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Icon(
                Icons.directions_car,
                color: cardColor,
                size: 30,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Car Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.brand} ${vehicle.model}',
                  style: AppThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.licensePlate,
                  style: AppThemes.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.color,
                  style: AppThemes.bodySmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tạo: ${_formatDate(vehicle.createdAt)}',
                  style: AppThemes.bodySmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Car Image Placeholder
          Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildCarImage(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Options Menu
          PopupMenuButton<String>(
            onSelected: (value) => _handleCarAction(value, vehicle),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 8),
                    Text(AppStrings.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.delete,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarImage() {
    // Since we don't have actual car images, show a placeholder
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.directions_car,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToAddCar() async {
    print('Navigating to add car screen');
    final result = await Navigator.of(context).pushNamed('/add-car');
    print('Returned from add car screen with result: $result');
    if (result == true) {
      // Refresh the list when a new car is added
      print('Refreshing vehicle list...');
      _loadVehicles();
    }
  }

  void _handleCarAction(String action, Vehicle vehicle) {
    switch (action) {
      case 'edit':
        _editCar(vehicle);
        break;
      case 'delete':
        _showDeleteConfirmation(vehicle);
        break;
    }
  }

  void _editCar(Vehicle vehicle) async {
    print('Editing vehicle: ${vehicle.toString()}');
    final result = await Navigator.of(context).pushNamed('/edit-car', arguments: vehicle);
    print('Returned from edit car screen with result: $result');
    if (result == true) {
      // Refresh the list when a car is updated
      print('Refreshing vehicle list after edit...');
      _loadVehicles();
    }
  }

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.delete),
        content: Text('Bạn có chắc chắn muốn xóa xe ${vehicle.brand} ${vehicle.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVehicle(vehicle);
            },
            child: Text(
              AppStrings.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}