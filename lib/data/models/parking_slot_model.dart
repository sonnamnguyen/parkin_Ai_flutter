enum SlotStatus { available, occupied, reserved, maintenance }

class ParkingSlot {
  final String id;
  final int lotId;
  final String slotNumber;
  final SlotStatus status;
  final String type; // compact, standard, large, disabled
  final double? reservedUntil; // timestamp if reserved
  final bool isElectricCharging;

  ParkingSlot({
    required this.id,
    required this.lotId,
    required this.slotNumber,
    required this.status,
    required this.type,
    this.reservedUntil,
    this.isElectricCharging = false,
  });

  factory ParkingSlot.fromJson(Map<String, dynamic> json) => ParkingSlot(
    id: json['id'] as String,
    lotId: json['lot_id'] as int,
    slotNumber: json['slot_number'] as String,
    status: SlotStatus.values.byName(json['status']),
    type: json['type'] as String,
    reservedUntil: json['reserved_until'] != null 
        ? double.parse(json['reserved_until'].toString()) 
        : null,
    isElectricCharging: json['is_electric_charging'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lot_id': lotId,
    'slot_number': slotNumber,
    'status': status.name,
    'type': type,
    'reserved_until': reservedUntil,
    'is_electric_charging': isElectricCharging,
  };

  bool get isAvailable => status == SlotStatus.available;
}