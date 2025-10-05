import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/parking_lot_service.dart';
import '../../../core/services/parking_slot_service.dart';
import '../../../core/services/parking_order_service.dart';
import '../../../core/services/vehicle_service.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_slot_model.dart';
import '../../../data/models/parking_order_model.dart';
import '../../../data/models/vehicle_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'package:geolocator/geolocator.dart';
import '../../../routes/app_routes.dart';

class AiFastBookingScreen extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;

  const AiFastBookingScreen({
    super.key,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<AiFastBookingScreen> createState() => _AiFastBookingScreenState();
}

class _AiFastBookingScreenState extends State<AiFastBookingScreen> {
  final ParkingLotService _parkingLotService = ParkingLotService();
  final ParkingSlotService _slotService = ParkingSlotService();
  final ParkingOrderService _orderService = ParkingOrderService();
  final VehicleService _vehicleService = VehicleService();
  final TextEditingController _preferencesController = TextEditingController();
  
  List<ParkingLot> _parkingLots = [];
  AiRecommendation? _aiRecommendation;
  ParkingLot? _selectedParkingLot;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });
      
      await _findNearbyParkingLots();
    } catch (e) {
      setState(() {
        _error = 'Không thể lấy vị trí hiện tại: $e';
      });
    }
  }

  Future<void> _findNearbyParkingLots() async {
    if (_currentLatitude == null || _currentLongitude == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _parkingLotService.getNearbyParkingLots(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        radius: 5000, // 5km radius
      );
      
      setState(() {
        _parkingLots = response.list;
        _isLoading = false;
      });
      
      if (_parkingLots.isNotEmpty) {
        await _getAiRecommendation();
      } else {
        setState(() {
          _error = 'Không tìm thấy bãi đỗ xe nào gần đây';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tìm bãi đỗ xe: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getAiRecommendation() async {
    if (_parkingLots.isEmpty || _currentLatitude == null || _currentLongitude == null) return;
    
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final recommendation = await AiService.getBestParkingLot(
        parkingLots: _parkingLots,
        userLatitude: _currentLatitude!,
        userLongitude: _currentLongitude!,
        userPreferences: _preferencesController.text.trim().isEmpty 
            ? null 
            : _preferencesController.text.trim(),
      );
      
      setState(() {
        _aiRecommendation = recommendation;
        _selectedParkingLot = recommendation.recommendedLot; // Set default selection
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi AI: $e';
        _isAnalyzing = false;
      });
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
          'AI Đặt Chỗ Nhanh',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshRecommendation,
            icon: const Icon(Icons.refresh, color: AppColors.darkGrey),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_isAnalyzing) {
      return _buildAnalyzingState();
    }
    
    if (_aiRecommendation == null) {
      return _buildInitialState();
    }
    
    return _buildRecommendationState();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Đang tìm bãi đỗ xe gần đây...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Thử lại',
              onPressed: _getCurrentLocation,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'AI đang phân tích...',
            style: AppThemes.headingSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm bãi đỗ xe tốt nhất cho bạn',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.psychology,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'AI Đặt Chỗ Thông Minh',
                  style: AppThemes.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI sẽ phân tích khoảng cách, giá cả và tình trạng để tìm bãi đỗ xe tốt nhất cho bạn',
                  textAlign: TextAlign.center,
                  style: AppThemes.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preferences Input
          Text(
            'Sở thích của bạn (tùy chọn)',
            style: AppThemes.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _preferencesController,
            label: 'Sở thích',
            hintText: 'Ví dụ: Gần bệnh viện, giá rẻ, có bảo vệ...',
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Start Analysis Button
          CustomButton(
            text: 'Bắt đầu phân tích AI',
            onPressed: _getAiRecommendation,
            width: double.infinity,
            isLoading: _isAnalyzing,
          ),
          
          const SizedBox(height: 12),
          
          // Test API Connection Button
          CustomButton(
            text: 'Test API Connection',
            onPressed: _testApiConnection,
            width: double.infinity,
            backgroundColor: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationState() {
    final recommendation = _aiRecommendation!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation.aiMessage,
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Selection Info
          if (_selectedParkingLot != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã chọn: ${_selectedParkingLot!.name}',
                      style: AppThemes.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Recommended Parking Lot
          Text(
            'Bãi đỗ xe được đề xuất',
            style: AppThemes.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chạm vào bãi đỗ xe để chọn',
            style: AppThemes.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildParkingLotCard(
            recommendation.recommendedLot,
            isRecommended: true,
            confidence: recommendation.confidenceScore,
            reasoning: recommendation.reasoning,
          ),
          
          const SizedBox(height: 20),
          
          // Alternatives
          if (recommendation.alternatives.isNotEmpty) ...[
            Text(
              'Lựa chọn khác',
              style: AppThemes.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            ...recommendation.alternatives.map((alt) => 
              _buildParkingLotCard(alt.lot, isRecommended: false, reason: alt.reason)
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _isLoading ? 'Đang đặt chỗ...' : 'Đặt chỗ ngay',
                  onPressed: (_selectedParkingLot != null && !_isLoading)
                      ? () => _bookParkingLot(_selectedParkingLot!)
                      : null,
                  backgroundColor: AppColors.primary,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Phân tích lại',
                  onPressed: _isLoading ? null : _refreshRecommendation,
                  backgroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParkingLotCard(
    ParkingLot lot, {
    required bool isRecommended,
    double? confidence,
    String? reasoning,
    String? reason,
  }) {
    final isSelected = _selectedParkingLot?.id == lot.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedParkingLot = lot;
        });
        // Add haptic feedback
        // HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : isRecommended 
                  ? AppColors.primary.withOpacity(0.05) 
                  : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary
                : isRecommended 
                    ? AppColors.primary 
                    : AppColors.lightGrey,
            width: isSelected ? 3 : isRecommended ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lot.name,
                  style: AppThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Đã chọn',
                    style: AppThemes.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (isRecommended) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Đề xuất',
                    style: AppThemes.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            lot.address,
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildInfoChip(
                Icons.local_parking,
                '${lot.availableSlots}/${lot.totalSlots} chỗ',
                lot.availableSlots > 0 ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.attach_money,
                '${lot.pricePerHour.toInt()}k/h',
                AppColors.warning,
              ),
              const SizedBox(width: 8),
              if (confidence != null)
                _buildInfoChip(
                  Icons.psychology,
                  '${(confidence * 100).toInt()}%',
                  AppColors.primary,
                ),
            ],
          ),
          
          if (reasoning != null || reason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reasoning ?? reason ?? '',
                style: AppThemes.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          
          // Tap indicator
          if (!isSelected) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Chạm để chọn',
                  style: AppThemes.bodySmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppThemes.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshRecommendation() {
    setState(() {
      _aiRecommendation = null;
    });
    _getAiRecommendation();
  }

  Future<void> _bookParkingLot(ParkingLot lot) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Đang tìm ngày trống...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // 1. Get first available slot
      final slots = await _slotService.searchSlots(
        lotId: lot.id,
        isAvailable: true,
        pageSize: 1,
      );
      
      if (slots.isEmpty) {
        throw Exception('Không có chỗ trống trong bãi đỗ xe này');
      }
      
      final firstSlot = slots.first;

      // 2. Get first vehicle (car)
      final vehicles = await _vehicleService.getVehicles(
        type: 'car',
        pageSize: 1,
      );
      
      if (vehicles.list.isEmpty) {
        throw Exception('Bạn chưa có xe nào. Vui lòng thêm xe trước khi đặt chỗ');
      }
      
      final firstVehicle = vehicles.list.first;

      // 3. Find next available day (check operating hours only)
      // Use device's exact local time (no timezone conversion)
      final now = DateTime.now(); // This gets device local time
      debugPrint('Device time: ${now.hour}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}');
      DateTime bookingDate = now.add(const Duration(days: 1)); // Start with tomorrow
      
      // Ensure booking time is within operating hours (07:00 - 22:00)
      final bookingTime = bookingDate.hour;
      if (bookingTime < 7 || bookingTime >= 22) {
        // Move to 7:00 AM of the next day
        bookingDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, 7, 0);
      }
      
      // 4. Create the booking with automatic retry
      ParkingOrder? order;
      int retryCount = 0;
      const maxRetries = 7; // Try up to 7 days ahead
      
      String startTime = bookingDate.toIso8601String();
      String endTime = bookingDate.add(const Duration(hours: 1)).toIso8601String();
      
      while (order == null && retryCount < maxRetries) {
        try {
          final orderRequest = CreateOrderRequest(
            vehicleId: firstVehicle.id,
            lotId: lot.id,
            slotId: int.parse(firstSlot.id),
            startTime: startTime,
            endTime: endTime,
          );

          order = await _orderService.createOrder(orderRequest);
          debugPrint('Booking successful on attempt ${retryCount + 1}');
          
        } catch (e) {
          final errorMessage = e.toString().toLowerCase();
          debugPrint('Booking error: $errorMessage');
          
          // Check if it's a booking conflict error
          if (errorMessage.contains('already booked') || 
              errorMessage.contains('đã được đặt') ||
              errorMessage.contains('conflict') ||
              errorMessage.contains('occupied') ||
              errorMessage.contains('the slot is already booked for the selected time')) {
            
            retryCount++;
            debugPrint('Booking conflict detected, retrying with day+$retryCount');
            
            // Move to next day
            bookingDate = bookingDate.add(const Duration(days: 1));
            
            // Check if new date is within operating hours
            final newBookingTime = bookingDate.hour;
            if (newBookingTime < 7 || newBookingTime >= 22) {
              // Move to 7:00 AM of the next day
              bookingDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, 7, 0);
            }
            
            // Update times for retry
            startTime = bookingDate.toIso8601String();
            endTime = bookingDate.add(const Duration(hours: 1)).toIso8601String();
            
            // Show retry notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ngày ${retryCount == 1 ? 'hôm nay' : 'ngày ${retryCount}'} đã được đặt, thử ngày ${retryCount + 1}...'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.warning,
              ),
            );
            
            // Wait a bit before retry
            await Future.delayed(const Duration(milliseconds: 500));
            
          } else {
            // If it's not a booking conflict, also retry with next day
            retryCount++;
            debugPrint('Non-conflict error detected, retrying with day+$retryCount: $errorMessage');
            
            // Move to next day
            bookingDate = bookingDate.add(const Duration(days: 1));
            
            // Check if new date is within operating hours
            final newBookingTime = bookingDate.hour;
            if (newBookingTime < 7 || newBookingTime >= 22) {
              // Move to 7:00 AM of the next day
              bookingDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day, 7, 0);
            }
            
            // Update times for retry
            startTime = bookingDate.toIso8601String();
            endTime = bookingDate.add(const Duration(hours: 1)).toIso8601String();
            
            // Show retry notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi ngày ${retryCount == 1 ? 'hôm nay' : 'ngày ${retryCount}'}, thử ngày ${retryCount + 1}...'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.warning,
              ),
            );
            
            // Wait a bit before retry
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      if (order == null) {
        throw Exception('Không thể đặt chỗ sau $maxRetries ngày. Vui lòng chọn ngày thủ công.');
      }

      // 5. Show success and navigate to home
      final selectedDate = bookingDate; // Already device local time
      final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
      final timeStr = '${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}';
      
      // Check current operating status using exact device time
      final currentDeviceTime = DateTime.now(); // Device local time
      final currentHour = currentDeviceTime.hour;
      final currentMinute = currentDeviceTime.minute;
      final isCurrentlyOpen = currentHour >= 7 && currentHour < 22;
      final statusText = isCurrentlyOpen ? 'Đang Mở Cửa' : 'Đã đóng cửa';
      
      // Show current device time for reference (exact device time)
      final currentTimeStr = '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt chỗ thành công! Mã đơn: ${order.id}\nNgày: $dateStr lúc $timeStr\nTrạng thái: $statusText (Thời gian hiện tại: $currentTimeStr)${retryCount > 0 ? '\nĐã thử ${retryCount + 1} ngày' : ''}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Navigate back to home
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.main,
        (route) => false,
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt chỗ: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final isWorking = await AiService.testApiConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isWorking 
                ? '✅ Gemini API connection successful!' 
                : '❌ Gemini API connection failed. Check console for details.',
            ),
            backgroundColor: isWorking ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API test error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}
