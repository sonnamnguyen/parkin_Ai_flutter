import 'parking_lot_model.dart';

class ParkingLotListResponse {
  final List<ParkingLot> list;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  ParkingLotListResponse({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ParkingLotListResponse.fromJson(Map<String, dynamic> json) => ParkingLotListResponse(
    list: (json['list'] as List? ?? [])
        .map((lot) => ParkingLot.fromJson(lot as Map<String, dynamic>))
        .toList(),
    total: _parseInt(json['total']),
    page: _parseInt(json['page']),
    pageSize: _parseInt(json['page_size']),
    totalPages: _parseInt(json['total_pages']),
  );

  Map<String, dynamic> toJson() => {
    'list': list.map((lot) => lot.toJson()).toList(),
    'total': total,
    'page': page,
    'page_size': pageSize,
    'total_pages': totalPages,
  };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() => 'ParkingLotListResponse(total: $total, page: $page, list: ${list.length} items)';
}
