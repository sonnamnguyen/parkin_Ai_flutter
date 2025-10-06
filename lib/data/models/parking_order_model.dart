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
    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? _parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    OrderStatus _parseStatus(dynamic value) {
      final String name = value?.toString() ?? 'pending';
      try {
        return OrderStatus.values.byName(name);
      } catch (_) {
        return OrderStatus.pending;
      }
    }

    return ParkingOrder(
      id: _parseInt(json['id']),
      vehicleId: _parseInt(json['vehicle_id']),
      lotId: _parseInt(json['lot_id']),
      slotId: _parseInt(json['slot_id']),
      startTime: (json['start_time']?.toString() ?? ''),
      endTime: (json['end_time']?.toString() ?? ''),
      status: _parseStatus(json['status']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      // Map both keys: some APIs use price instead of total_amount
      totalAmount: _parseDoubleNullable(json['total_amount'] ?? json['price']),
      // Map both keys: vehicle_plate or vehicle_license_plate
      vehicleLicensePlate: (json['vehicle_license_plate'] ?? json['vehicle_plate'])?.toString(),
      lotName: json['lot_name']?.toString(),
      slotCode: json['slot_code']?.toString(),
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
    final List<dynamic> rawList = (json['list'] as List?) ?? const [];
    final orders = rawList
        .map((e) => ParkingOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (json['total'] as int?) ?? orders.length;
    final page = (json['page'] as int?) ?? 1;
    final pageSize = (json['page_size'] as int?) ?? orders.length;
    return OrderListResponse(
      orders: orders,
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }
}
