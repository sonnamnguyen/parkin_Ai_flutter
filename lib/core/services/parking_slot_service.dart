import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/parking_slot_model.dart';

class ParkingSlotService {
  final ApiClient _api = ApiClient();

  Future<List<ParkingSlot>> searchSlots({
    required int lotId,
    String? code,
    bool? isAvailable,
    String? slotType,
    String? floor,
    int page = 1,
    int pageSize = 50,
  }) async {
    print('=== SEARCH SLOTS METHOD CALLED ===');
    print('lotId: $lotId');
    print('code: $code');
    print('slotType: $slotType');
    print('floor: $floor');
    final payload = <String, dynamic>{
      'lot_id': lotId, // Required parameter
      'code': code ?? '', // API requires code parameter (can be empty)
      if (isAvailable != null) 'is_available': isAvailable,
      if (slotType != null && slotType.isNotEmpty) 'slot_type': slotType,
      if (floor != null && floor.isNotEmpty) 'floor': floor,
      'page': page,
      'page_size': pageSize,
    };
    try {
      print('=== PARKING SLOT SERVICE ===');
      print('Request URL: ${ApiEndpoints.searchParkingSlots}');
      print('Request payload: $payload');
      print('Payload type: ${payload.runtimeType}');
      
      final Response response = await _api.getWithBody(ApiEndpoints.searchParkingSlots, data: payload);
      
      print('Parking slots response status: ${response.statusCode}');
      print('Parking slots response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List raw = (data is Map && data['list'] is List)
            ? data['list'] as List
            : (data is List ? data : const []);
        return raw.map((e) => _mapBackendSlot(e as Map<String, dynamic>)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch slots: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in searchSlots: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in searchSlots: $e');
      rethrow;
    }
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


