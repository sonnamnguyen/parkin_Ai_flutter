import 'package:flutter/material.dart';
import 'dart:math';
import '../../../routes/app_routes.dart';
import '../main/main_screen.dart';

class TicketScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const TicketScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _isLoading = false;

  // Generate barcode data from order information
  String _generateBarcodeData() {
    final args = widget.arguments ?? {};
    final orderId = args['order_id'] as int? ?? 0;
    final lotId = args['lot_id'] as int? ?? 0;
    final slotCode = args['slot_code'] as String? ?? 'A01';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'PARK${orderId.toString().padLeft(6, '0')}${lotId.toString().padLeft(3, '0')}${slotCode}${timestamp.toString().substring(8)}';
  }

  // Get cancellation time text like the image
  String _getCancellationTimeText() {
    try {
      final args = widget.arguments ?? {};
      final startTimeStr = args['start_time'] as String?;
      final dateStr = args['date'] as String?;
      
      if (startTimeStr != null && dateStr != null) {
        final startDateTime = DateTime.parse('${dateStr}T$startTimeStr:00');
        final now = DateTime.now();
        final difference = startDateTime.difference(now);
        
        if (difference.isNegative) {
          return 'Đã hết hạn';
        } else {
          final minutes = difference.inMinutes;
          if (minutes > 60) {
            final hours = minutes ~/ 60;
            final remainingMinutes = minutes % 60;
            return 'Còn lại ${hours}h ${remainingMinutes}m';
          } else {
            return 'Còn lại $minutes phút';
          }
        }
      }
    } catch (e) {
      print('Error calculating cancellation time: $e');
    }
    return 'Còn lại 30 phút'; // Default fallback
  }

  // Create visual barcode matching the image style
  Widget _buildVisualBarcode() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final numberOfBars = 60; // Dense barcode like the image
        final barWidths = <double>[];
        
        // Create varying bar widths: thin, medium, thick (like the image)
        for (int i = 0; i < numberOfBars; i++) {
          if (i % 5 == 0) {
            barWidths.add(3.0); // Thick bars
          } else if (i % 3 == 0) {
            barWidths.add(2.0); // Medium bars
          } else {
            barWidths.add(1.0); // Thin bars
          }
        }

        // Calculate total width needed for bars
        final totalBarWidth = barWidths.reduce((a, b) => a + b);
        final availableWidth = constraints.maxWidth - 32; // Account for padding
        final spacingWidth = (availableWidth - totalBarWidth) / (numberOfBars - 1);

        return Container(
          height: 80, // Uniform height like the image
          color: Colors.white, // White background
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(numberOfBars, (index) {
              return Container(
                width: barWidths[index],
                height: 80, // Uniform height
                color: Colors.blue.shade900, // Dark blue like the image
                margin: EdgeInsets.only(
                  right: index == numberOfBars - 1 ? 0 : spacingWidth,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.arguments ?? {};
    final orderId = args['order_id'] as int?;
    final lotId = args['lot_id'] as int?;
    final lotName = args['lot_name'] as String? ?? 'Bãi xe Đại học Khoa học Tự nhiên';
    final slotCode = args['slot_code'] as String? ?? 'A01';
    final vehiclePlate = args['vehicle_plate'] as String? ?? 'B 1234 CD';
    final vehicleModel = args['vehicle_model'] as String? ?? '2021 Audi Q3';
    final startTime = args['start_time'] as String? ?? '12:00';
    final endTime = args['end_time'] as String? ?? '14:00';
    final date = args['date'] as String? ?? DateTime.now().toString().substring(0, 10);
    final totalAmount = args['total_amount'] as int? ?? 25000;
    final address = args['address'] as String? ?? '227 Nguyễn Văn Cừ, Quận 5, TP.HCM';
    final parkingSpot = args['parking_spot'] as String? ?? 'Chỗ A01';
    
    // Session parking details
    final sessionParking = args['session_parking_details'] as Map<String, dynamic>? ?? {};
    final operatingHours = sessionParking['operating_hours'] as String? ?? '07:00 - 22:00';
    final pricePerHour = sessionParking['price_per_hour'] as int? ?? 25000;
    final totalSlots = sessionParking['total_slots'] as int? ?? 50;
    final availableSlots = sessionParking['available_slots'] as int? ?? 35;
    
    // Slot order details
    final slotOrder = args['slot_order_details'] as Map<String, dynamic>? ?? {};
    final slotType = slotOrder['slot_type'] as String? ?? 'Standard';
    final vehicleType = slotOrder['vehicle_type'] as String? ?? 'Car';
    final bookingDuration = slotOrder['booking_duration'] as String? ?? '2 hours';

    return Scaffold(
      backgroundColor: const Color(0xFF6B46C1), // Purple background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Ticket Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Parking Location
                            Text(
                              lotName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Vehicle Information
                            Text(
                              'Phương tiện',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$vehicleModel • $vehiclePlate',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Reservation Time
                            Text(
                              'Thời gian giữ chỗ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$startTime-$endTime • $date',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Cancellation Time (like the image)
                            Text(
                              'Thời gian hủy đặt trước',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getCancellationTimeText(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Parking Spot
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF), // Light purple
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                parkingSpot,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Tear-off line
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[300]!,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[300]!,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[300]!,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Session Details
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chi tiết phiên đỗ xe',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Giờ hoạt động:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      Text(operatingHours, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Giá/giờ:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      Text('${pricePerHour.toString()} VND', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Loại chỗ:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      Text(slotType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Thời gian đặt:', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      Text(bookingDuration, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Barcode - Full width
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: _buildVisualBarcode(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Directions Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: lotId != null ? () => _navigateToDirections(lotId) : null,
                  icon: const Icon(Icons.navigation, color: Colors.black),
                  label: const Text(
                    'Chỉ đường',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToDirections(int lotId) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== TICKET SCREEN: Navigating to directions ===');
      print('Lot ID: $lotId');
      
      // Import MainScreen and use setPendingLotId
      // This will be handled by MainScreen when it loads
      MainScreen.setPendingLotId(lotId);
      
      // Navigate to main screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.main,
        (route) => false,
      );
      
      print('=== TICKET SCREEN: Navigation completed ===');
    } catch (e) {
      print('=== TICKET SCREEN: Navigation error ===');
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở chỉ đường: $e'),
            backgroundColor: Colors.red,
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
}