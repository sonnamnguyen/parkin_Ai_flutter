import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../widgets/common/custom_button.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  // Mock data for cars
  final List<Map<String, dynamic>> _cars = [
    {
      'id': 1,
      'brand': 'Mercedes',
      'model': 'G 63',
      'licensePlate': 'A 61026',
      'color': 'Black',
      'image': 'assets/images/mercedes_g63.png', // This would be actual asset
    },
    {
      'id': 2,
      'brand': 'Ford',
      'model': 'F350',
      'licensePlate': 'A 61026',
      'color': 'Blue',
      'image': 'assets/images/ford_f350.png',
    },
    {
      'id': 3,
      'brand': 'Tesla',
      'model': 'Model 3',
      'licensePlate': 'B 10033',
      'color': 'White',
      'image': 'assets/images/tesla_model3.png',
    },
  ];

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
            // Cars List
            Expanded(
              child: _cars.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _cars.length,
                      itemBuilder: (context, index) {
                        final car = _cars[index];
                        return _buildCarCard(car, index);
                      },
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

  Widget _buildCarCard(Map<String, dynamic> car, int index) {
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
                  '${car['brand']} ${car['model']}',
                  style: AppThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  car['licensePlate'],
                  style: AppThemes.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  car['color'],
                  style: AppThemes.bodySmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
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
              child: _buildCarImage(car['image']),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Options Menu
          PopupMenuButton<String>(
            onSelected: (value) => _handleCarAction(value, car),
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

  Widget _buildCarImage(String imagePath) {
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

  void _navigateToAddCar() {
    Navigator.of(context).pushNamed('/add-car');
  }

  void _handleCarAction(String action, Map<String, dynamic> car) {
    switch (action) {
      case 'edit':
        _editCar(car);
        break;
      case 'delete':
        _deleteCar(car);
        break;
    }
  }

  void _editCar(Map<String, dynamic> car) {
    Navigator.of(context).pushNamed('/edit-car', arguments: car);
  }

  void _deleteCar(Map<String, dynamic> car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.delete),
        content: Text('Bạn có chắc chắn muốn xóa xe ${car['brand']} ${car['model']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cars.removeWhere((c) => c['id'] == car['id']);
              });
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa xe ${car['brand']} ${car['model']}'),
                  backgroundColor: AppColors.success,
                ),
              );
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