import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

class OtherServiceItem {
  final int id;
  final int lotId;
  final String lotName;
  final String name;
  final String description;
  final int price;
  final int durationMinutes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  OtherServiceItem({
    required this.id,
    required this.lotId,
    required this.lotName,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OtherServiceItem.fromJson(Map<String, dynamic> json) {
    return OtherServiceItem(
      id: (json['id'] as num).toInt(),
      lotId: (json['lot_id'] as num).toInt(),
      lotName: (json['lot_name'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }
}

class OtherServicesListResponse {
  final List<OtherServiceItem> list;
  final int total;

  OtherServicesListResponse({required this.list, required this.total});

  factory OtherServicesListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['list'] as List? ?? const [])
        .map((e) => OtherServiceItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final total = (json['total'] as num?)?.toInt() ?? items.length;
    return OtherServicesListResponse(list: items, total: total);
    
  }
}

class OtherServicesService {
  final ApiClient _api = ApiClient();

  Future<OtherServicesListResponse> getOtherServices({
    required int lotId,
    bool isActive = true,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Response response = await _api.get(
      ApiEndpoints.otherServices,
      queryParameters: {
        'lot_id': lotId,
        'is_active': isActive,
        'page': page,
        'page_size': pageSize,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return OtherServicesListResponse.fromJson(data);
      }
      return OtherServicesListResponse(list: const [], total: 0);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to fetch other services',
    );
  }

  Future<int> createServiceOrder({
    required int vehicleId,
    required int lotId,
    required int serviceId,
    required String scheduledTime, // format yyyy-MM-dd HH:mm:ss
  }) async {
    final Response response = await _api.post(
      ApiEndpoints.serviceOrders,
      data: {
        'vehicle_id': vehicleId,
        'lot_id': lotId,
        'service_id': serviceId,
        'scheduled_time': scheduledTime,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      if (body is Map<String, dynamic> && body['id'] != null) {
        return (body['id'] as num).toInt();
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to create service order',
    );
  }
}
