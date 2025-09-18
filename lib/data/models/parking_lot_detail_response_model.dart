import 'parking_lot_model.dart';

class ParkingLotDetailResponse {
  final ParkingLot lot;

  ParkingLotDetailResponse({
    required this.lot,
  });

  factory ParkingLotDetailResponse.fromJson(Map<String, dynamic> json) => ParkingLotDetailResponse(
    lot: ParkingLot.fromJson(json['lot'] is Map<String, dynamic> 
        ? json['lot'] as Map<String, dynamic>
        : json as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'lot': lot.toJson(),
  };

  @override
  String toString() => 'ParkingLotDetailResponse(lot: ${lot.name})';
}
