enum OrderStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  expired,
}

class ParkingOrder {
  final int id;
  final int vehicleId;
  final int lotId;
  final int slotId;
  final String startTime;
  final String endTime;
  final OrderStatus status;
  final String? createdAt;
  final String? updatedAt;
  final double? totalAmount;
  final String? vehicleLicensePlate;
  final String? lotName;
  final String? slotCode;

  ParkingOrder({
    required this.id,
    required this.vehicleId,
    required this.lotId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.totalAmount,
    this.vehicleLicensePlate,
    this.lotName,
    this.slotCode,
  });

  factory ParkingOrder.fromJson(Map<String, dynamic> json) {
    return ParkingOrder(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'] as int,
      lotId: json['lot_id'] as int,
      slotId: json['slot_id'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: OrderStatus.values.byName(json['status'] as String),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      vehicleLicensePlate: json['vehicle_license_plate'] as String?,
      lotName: json['lot_name'] as String?,
      slotCode: json['slot_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'lot_id': lotId,
      'slot_id': slotId,
      'start_time': startTime,
      'end_time': endTime,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'total_amount': totalAmount,
      'vehicle_license_plate': vehicleLicensePlate,
      'lot_name': lotName,
      'slot_code': slotCode,
    };
  }
}

class CreateOrderRequest {
  final int vehicleId;
  final int lotId;
  final int slotId;
  final String startTime;
  final String endTime;

  CreateOrderRequest({
    required this.vehicleId,
    required this.lotId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'lot_id': lotId,
      'slot_id': slotId,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class OrderListResponse {
  final List<ParkingOrder> orders;
  final int total;
  final int page;
  final int pageSize;

  OrderListResponse({
    required this.orders,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders: (json['list'] as List)
          .map((e) => ParkingOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }
}
