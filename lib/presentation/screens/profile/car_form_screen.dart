import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/vehicle_service.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/models/vehicle_request_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class CarFormScreen extends StatefulWidget {
  final Vehicle? vehicle; // null for create, Vehicle object for edit

  const CarFormScreen({super.key, this.vehicle});

  @override
  State<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends State<CarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedType = 'car';
  final VehicleService _vehicleService = VehicleService();

  // Vehicle types
  final List<Map<String, String>> _vehicleTypes = [
    {'value': 'car', 'label': 'Ô tô'},
    {'value': 'motorcycle', 'label': 'Xe máy'},
    {'value': 'bicycle', 'label': 'Xe đạp'},
    {'value': 'truck', 'label': 'Xe tải'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.vehicle != null) {
      // Edit mode - populate form with existing data
      _licensePlateController.text = widget.vehicle!.licensePlate;
      _brandController.text = widget.vehicle!.brand;
      _modelController.text = widget.vehicle!.model;
      _colorController.text = widget.vehicle!.color;
      _selectedType = widget.vehicle!.type;
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicleRequest = VehicleRequest(
        licensePlate: _licensePlateController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        type: _selectedType,
      );

      if (widget.vehicle == null) {
        // Create new vehicle
        final newVehicle = await _vehicleService.addVehicle(vehicleRequest);
        print('Created vehicle: ${newVehicle.toString()}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm xe thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Update existing vehicle
        final updatedVehicle = await _vehicleService.updateVehicle(widget.vehicle!.id, vehicleRequest);
        print('Updated vehicle: ${updatedVehicle.toString()}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật xe thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('Error saving vehicle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.vehicle != null;
    final title = isEditMode ? 'Chỉnh sửa xe' : 'Thêm xe mới';

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
          title,
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      isEditMode ? Icons.edit : Icons.add_circle_outline,
                      color: AppColors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEditMode ? 'Chỉnh sửa thông tin xe' : 'Thêm xe mới vào danh sách',
                      style: AppThemes.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // License Plate Field
              CustomTextField(
                controller: _licensePlateController,
                label: 'Biển số xe',
                hintText: '30A-22345',
                prefixIcon: Icons.confirmation_number_outlined,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập biển số xe';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Brand Field
              CustomTextField(
                controller: _brandController,
                label: 'Hãng xe',
                hintText: 'Toyota, Honda, Ford...',
                prefixIcon: Icons.business_outlined,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập hãng xe';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Model Field
              CustomTextField(
                controller: _modelController,
                label: 'Dòng xe',
                hintText: 'Camry, Civic, Focus...',
                prefixIcon: Icons.directions_car_outlined,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập dòng xe';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Color Field
              CustomTextField(
                controller: _colorController,
                label: 'Màu sắc',
                hintText: 'Đen, Trắng, Xanh...',
                prefixIcon: Icons.palette_outlined,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập màu sắc';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Vehicle Type Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại xe',
                    style: AppThemes.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                        style: AppThemes.bodyLarge,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                        items: _vehicleTypes.map<DropdownMenuItem<String>>((Map<String, String> type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Row(
                              children: [
                                Icon(
                                  _getVehicleTypeIcon(type['value']!),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(type['label']!),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: isEditMode ? 'CẬP NHẬT XE' : 'THÊM XE',
                onPressed: _isLoading ? null : _saveVehicle,
                isLoading: _isLoading,
                width: double.infinity,
                icon: isEditMode ? Icons.save : Icons.add,
              ),

              const SizedBox(height: 20),

              // Cancel Button
              if (isEditMode)
                CustomButton(
                  text: 'HỦY',
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  width: double.infinity,
                  backgroundColor: AppColors.textSecondary,
                  icon: Icons.close,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleTypeIcon(String type) {
    switch (type) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }
}
