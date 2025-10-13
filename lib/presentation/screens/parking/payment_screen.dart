import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../widgets/common/custom_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../routes/app_routes.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'qr';
  bool isProcessing = false;
  int? orderId;
  String? checkoutUrl;
  String? qrCode;
  int? amount;
  
  // Real API data
  dynamic parkingLot;
  dynamic selectedSlot;
  dynamic selectedVehicle;
  String? startTime;
  String? endTime;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the route is fully set up
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadArguments();
      }
    });
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    print('=== PAYMENT SCREEN ARGS DEBUG (initState) ===');
    print('Args type: ${args.runtimeType}');
    print('Args value: $args');
    
    if (args is Map<String, dynamic>) {
      setState(() {
        orderId = args['orderId'] as int?;
        checkoutUrl = args['checkoutUrl'] as String?;
        qrCode = args['qrCode'] as String?;
        amount = args['amount'] as int?;
        // Real API data
        parkingLot = args['parkingLot'];
        selectedSlot = args['selectedSlot'];
        selectedVehicle = args['selectedVehicle'];
        startTime = args['startTime'] as String?;
        endTime = args['endTime'] as String?;
      });
      
      print('Order ID: $orderId');
      print('Checkout URL: $checkoutUrl');
      print('QR Code: $qrCode');
      print('Amount: $amount');
      print('Parking Lot: $parkingLot');
      print('Selected Slot: $selectedSlot');
      print('Selected Vehicle: $selectedVehicle');
      print('Start Time: $startTime');
      print('End Time: $endTime');
    } else {
      print('No arguments provided in initState');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    print('=== PAYMENT SCREEN ARGS DEBUG ===');
    print('Args type: ${args.runtimeType}');
    print('Args value: $args');
    print('ModalRoute: ${ModalRoute.of(context)}');
    print('Settings: ${ModalRoute.of(context)?.settings}');
    
    if (args is Map<String, dynamic>) {
      orderId = args['orderId'] as int?;
      checkoutUrl = args['checkoutUrl'] as String?;
      qrCode = args['qrCode'] as String?;
      amount = args['amount'] as int?;
      
      print('Order ID: $orderId');
      print('Checkout URL: $checkoutUrl');
      print('QR Code: $qrCode');
      print('Amount: $amount');
    } else {
      orderId = null;
      checkoutUrl = null;
      qrCode = null;
      amount = null;
      print('No arguments provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have payment data
    final hasPaymentData = (qrCode != null && qrCode!.isNotEmpty) || 
                          (checkoutUrl != null && checkoutUrl!.isNotEmpty);
    
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
          'Thanh toán',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: hasPaymentData ? _buildSimplePaymentScreen() : _buildLoadingState(),
      bottomNavigationBar: hasPaymentData ? _buildSimpleBottomBar() : null,
    );
  }

  Widget _buildSimplePaymentScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big QR Code Image - Larger size for better visibility
          Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: qrCode != null && qrCode!.isNotEmpty
                  ? Image.network(
                      qrCode!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.qr_code, size: 120, color: Colors.grey),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.qr_code, size: 120, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Download button
          ElevatedButton.icon(
            onPressed: () async {
              if (qrCode != null && qrCode!.isNotEmpty) {
                await _downloadQRImage();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không có QR code để tải')),
                );
              }
            },
            icon: const Icon(Icons.download, size: 20),
            label: const Text('Tải ảnh QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Open bank app button
          if (qrCode != null && qrCode!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final uri = Uri.parse(qrCode!);
                  if (await canLaunch(uri.toString())) {
                    await launch(uri.toString());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể mở ứng dụng ngân hàng')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi khi mở ứng dụng ngân hàng')),
                  );
                }
              },
              icon: const Icon(Icons.account_balance, size: 20),
              label: const Text('Mở ứng dụng ngân hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang tạo liên kết thanh toán...',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng chờ trong giây lát',
            style: AppThemes.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết thanh toán', style: AppThemes.headingSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'Số tiền đã được hiển thị trong QR code',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRPayment() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Thanh toán',
            style: AppThemes.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (qrCode != null && qrCode!.isNotEmpty) ...[
            Text('QR URL: $qrCode', style: TextStyle(fontSize: 10, color: Colors.red)),
            const SizedBox(height: 8),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                qrCode!,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  print('QR Code loading progress: $loadingProgress');
                  if (loadingProgress == null) {
                    print('QR Code loaded successfully');
                    return child;
                  }
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text('Loading... ${(loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! * 100).toInt()}%'),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('QR Code loading error: $error');
                  print('QR Code stack trace: $stackTrace');
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading QR',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'URL: ${qrCode!.length > 30 ? qrCode!.substring(0, 30) + '...' : qrCode!}',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ]
          else if (checkoutUrl != null && checkoutUrl!.isNotEmpty) ...[
            Text('Using checkout URL: $checkoutUrl', style: TextStyle(fontSize: 10, color: Colors.blue)),
            const SizedBox(height: 8),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: checkoutUrl!,
                version: QrVersions.auto,
                size: 300,
              ),
            )
          ]
          else
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (qrCode != null && qrCode!.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                print('Testing QR code URL: $qrCode');
                try {
                  final response = await http.get(Uri.parse(qrCode!));
                  print('QR code URL response status: ${response.statusCode}');
                  print('QR code URL response headers: ${response.headers}');
                  if (response.statusCode == 200) {
                    print('QR code URL is accessible');
                  } else {
                    print('QR code URL returned status: ${response.statusCode}');
                  }
                } catch (e) {
                  print('Error testing QR code URL: $e');
                }
              },
              child: const Text('Test QR Code URL'),
            ),
          const SizedBox(height: 8),
          Text(
            'Quét QR để thanh toán bằng ứng dụng ngân hàng',
            style: AppThemes.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Mã đơn', style: AppThemes.bodyMedium),
              const SizedBox(width: 16),
              Text(
                (orderId?.toString() ?? '--'),
                style: AppThemes.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBottomBar() {
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
        child: CustomButton(
          text: 'Xong',
          onPressed: () {
            // Navigate to ticket screen with real API data
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.ticket,
              (route) => false,
              arguments: {
                'order_id': orderId,
                'lot_id': parkingLot?.id ?? 2,
                'lot_name': parkingLot?.name ?? 'Bãi xe Đại học Khoa học Tự nhiên',
                'slot_code': selectedSlot?.slotNumber ?? selectedSlot?.id ?? 'A01',
                'vehicle_plate': selectedVehicle?.licensePlate ?? 'B 1234 CD',
                'start_time': startTime?.substring(11, 16) ?? '12:00',
                'end_time': endTime?.substring(11, 16) ?? '14:00',
                'date': startTime?.substring(0, 10) ?? DateTime.now().toString().substring(0, 10),
                'total_amount': amount ?? 25000,
                'address': parkingLot?.address ?? '227 Nguyễn Văn Cừ, Quận 5, TP.HCM',
                'vehicle_model': selectedVehicle?.model ?? '2021 Audi Q3',
                'reservation_time': 'Thời gian giữ chỗ',
                'parking_spot': 'Chỗ ${selectedSlot?.slotNumber ?? selectedSlot?.id ?? 'A01'}',
                'session_parking_details': {
                  'lot_id': parkingLot?.id ?? 2,
                  'lot_name': parkingLot?.name ?? 'Bãi xe Đại học Khoa học Tự nhiên',
                  'address': parkingLot?.address ?? '227 Nguyễn Văn Cừ, Quận 5, TP.HCM',
                  'price_per_hour': parkingLot?.pricePerHour?.toInt() ?? 25000,
                  'operating_hours': '${parkingLot?.openTime ?? '07:00'} - ${parkingLot?.closeTime ?? '22:00'}',
                  'total_slots': parkingLot?.totalSlots ?? 50,
                  'available_slots': parkingLot?.availableSlots ?? 35,
                },
                'slot_order_details': {
                  'slot_id': selectedSlot?.id ?? '1',
                  'slot_code': selectedSlot?.slotNumber ?? selectedSlot?.id ?? 'A01',
                  'slot_type': 'Standard',
                  'vehicle_plate': selectedVehicle?.licensePlate ?? 'B 1234 CD',
                  'vehicle_type': selectedVehicle?.type ?? 'Car',
                  'booking_duration': _calculateDuration(),
                  'start_time': startTime?.substring(11, 16) ?? '12:00',
                  'end_time': endTime?.substring(11, 16) ?? '14:00',
                },
              },
            );
          },
          isLoading: false, // Never show loading for Xong button
          width: double.infinity,
        ),
      ),
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
        child: CustomButton(
          text: 'Xong',
          onPressed: isProcessing ? null : _processPayment,
          isLoading: isProcessing,
          width: double.infinity,
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Here we could poll order status and close when success.
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  String _formatAmount(int? amount) {
    if (amount == null || amount <= 0) return '--';
    // Display amount directly without division
    final s = amount.toString();
    final re = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(re, (m) => '${m[1]},') + ' VNĐ';
  }

  String _calculateDuration() {
    if (startTime != null && endTime != null) {
      try {
        final start = DateTime.parse(startTime!);
        final end = DateTime.parse(endTime!);
        final duration = end.difference(start);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${minutes}m';
        }
      } catch (e) {
        return '2 hours';
      }
    }
    return '2 hours';
  }

  Future<void> _downloadQRImage() async {
    try {
      // Show loading indicator
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
              Text('Đang tải ảnh QR code...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Request storage permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use media permissions
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
        }
        
        // Fallback to storage permission for older Android versions
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      } else {
        // For iOS, use photos permission
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần quyền truy cập bộ nhớ để tải ảnh. Vui lòng cấp quyền trong Cài đặt.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Download the image
      final response = await http.get(Uri.parse(qrCode!));
      if (response.statusCode == 200) {
        // Get the downloads directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }

          // Create filename with timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final file = File('${downloadsDir.path}/qr_code_$timestamp.jpg');

          // Write the image data
          await file.writeAsBytes(response.bodyBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã tải ảnh QR code thành công!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể truy cập thư mục tải xuống')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tải ảnh QR code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}