import 'parking_lot_model.dart';
import 'parking_slot_model.dart';

enum BookingStatus { pending, confirmed, active, completed, cancelled }

class Booking {
  final int id;
  final int userId;
  final int lotId;
  final String slotId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final BookingStatus status;
  final DateTime createdAt;
  final String? vehicleId;
  final ParkingLot? parkingLot;
  final ParkingSlot? slot;

  Booking({
    required this.id,
    required this.userId,
    required this.lotId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.vehicleId,
    this.parkingLot,
    this.slot,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    lotId: json['lot_id'] as int,
    slotId: json['slot_id'] as String,
    startTime: DateTime.parse(json['start_time']),
    endTime: DateTime.parse(json['end_time']),
    totalAmount: double.parse(json['total_amount'].toString()),
    status: BookingStatus.values.byName(json['status']),
    createdAt: DateTime.parse(json['created_at']),
    vehicleId: json['vehicle_id'] as String?,
    parkingLot: json['parking_lot'] != null 
        ? ParkingLot.fromJson(json['parking_lot']) 
        : null,
    slot: json['slot'] != null 
        ? ParkingSlot.fromJson(json['slot']) 
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'lot_id': lotId,
    'slot_id': slotId,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'total_amount': totalAmount,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'vehicle_id': vehicleId,
    'parking_lot': parkingLot?.toJson(),
    'slot': slot?.toJson(),
  };

  Duration get duration => endTime.difference(startTime);
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
    }
    return '${minutes}m';
  }
  
  String get statusText {
    switch (status) {
      case BookingStatus.pending: return 'Đang xử lý';
      case BookingStatus.confirmed: return 'Đã xác nhận';
      case BookingStatus.active: return 'Đang sử dụng';
      case BookingStatus.completed: return 'Hoàn thành';
      case BookingStatus.cancelled: return 'Đã hủy';
    }
  }
}