import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/services/other_services_service.dart';
import '../../widgets/common/custom_button.dart';

class OtherServiceOrderScreen extends StatefulWidget {
  final int lotId;
  final int serviceId;
  final int price;
  final int? vehicleId;

  const OtherServiceOrderScreen({super.key, required this.lotId, required this.serviceId, required this.price, this.vehicleId});

  @override
  State<OtherServiceOrderScreen> createState() => _OtherServiceOrderScreenState();
}

class _OtherServiceOrderScreenState extends State<OtherServiceOrderScreen> {
  final OtherServicesService _service = OtherServicesService();
  DateTime scheduled = DateTime.now().add(const Duration(minutes: 10));
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt dịch vụ khác'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thời gian hẹn', style: AppThemes.headingSmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(scheduled), style: AppThemes.bodyLarge),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SafeArea(
              child: CustomButton(
                text: 'Đặt dịch vụ (${widget.price} VNĐ)',
                onPressed: _creating ? null : _submit,
                isLoading: _creating,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      initialDate: scheduled,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduled));
    if (time == null) return;
    setState(() {
      scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    setState(() { _creating = true; });
    try {
      final scheduledStr = scheduled.toIso8601String().replaceAll('T', ' ').substring(0, 19);
      final vehicleId = widget.vehicleId ?? 1; // TODO: integrate user's selected vehicle
      final id = await _service.createServiceOrder(
        vehicleId: vehicleId,
        lotId: widget.lotId,
        serviceId: widget.serviceId,
        scheduledTime: scheduledStr,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed('/payment', arguments: {
        'orderId': id,
        'checkoutUrl': '',
        'qrCode': '',
        'amount': widget.price,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đặt dịch vụ: $e')));
    } finally {
      if (mounted) setState(() { _creating = false; });
    }
  }

  String _format(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}


