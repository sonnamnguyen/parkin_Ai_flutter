import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/parking_slot_model.dart';

class ParkingSlotService {
  final ApiClient _api = ApiClient();

  Future<List<ParkingSlot>> searchSlots({
    int? lotId,
    String? code,
    bool? isAvailable,
    String? slotType,
    String? floor,
    int page = 1,
    int pageSize = 50,
  }) async {
    final payload = <String, dynamic>{
      if (lotId != null) 'lot_id': lotId,
      if (code != null && code.isNotEmpty) 'code': code,
      if (isAvailable != null) 'is_available': isAvailable,
      if (slotType != null && slotType.isNotEmpty) 'slot_type': slotType,
      if (floor != null && floor.isNotEmpty) 'floor': floor,
      'page': page,
      'page_size': pageSize,
    };
    final Response response = await _api.post(ApiEndpoints.searchParkingSlots, data: payload);
    if (response.statusCode == 200) {
      final data = response.data;
      final List raw = (data is Map && data['list'] is List)
          ? data['list'] as List
          : (data is List ? data : const []);
      return raw.map((e) => _mapBackendSlot(e as Map<String, dynamic>)).toList();
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to fetch slots',
    );
  }

  ParkingSlot _mapBackendSlot(Map<String, dynamic> json) {
    // Backend fields: id, lot_id, lot_name, code, is_available, slot_type, floor, created_at
    final String status = (json['is_available'] == true) ? 'available' : 'occupied';
    return ParkingSlot(
      id: json['id'].toString(),
      lotId: (json['lot_id'] as num).toInt(),
      slotNumber: (json['code'] as String?) ?? '',
      status: SlotStatus.values.byName(status),
      type: (json['slot_type'] as String?) ?? 'standard',
    );
  }
}


