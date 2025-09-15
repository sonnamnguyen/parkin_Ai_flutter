import 'dart:convert';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/parking_lot_model.dart';
import '../../data/models/parking_lot_list_response_model.dart';
import '../../data/models/parking_lot_detail_response_model.dart';

class ParkingLotService {
  final ApiClient _apiClient = ApiClient();

  // Get parking lots with filters
  Future<ParkingLotListResponse> getParkingLots({
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      print('Fetching parking lots with filters...');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radius != null) queryParams['radius'] = radius;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get(
        ApiEndpoints.parkingLots,
        queryParameters: queryParams,
      );

      print('Parking lots response status: ${response.statusCode}');
      try {
        print('Parking lots response data: ${response.data}');
      } catch (_) {
        // Some interceptors may stream data; avoid crashing logs
      }

      if (response.statusCode == 200) {
        final data = response.data;
        // Accept either {list: [...]} or {data: {list: [...]}}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('list')) {
            return ParkingLotListResponse.fromJson(data);
          }
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            return ParkingLotListResponse.fromJson(data['data'] as Map<String, dynamic>);
          }
        }
        // If format unexpected, try to coerce minimal list
        if (data is List) {
          return ParkingLotListResponse.fromJson({'list': data, 'total': data.length});
        }
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Unexpected parking list format: ${data.runtimeType}',
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch parking lots',
        );
      }
    } on DioException catch (e) {
      print('DioException in getParkingLots: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in getParkingLots: $e');
      rethrow;
    }
  }

  // Get nearby parking lots
  Future<ParkingLotListResponse> getNearbyParkingLots({
    required double latitude,
    required double longitude,
    double radius = 5.0,
    int page = 1,
    int pageSize = 10,
  }) async {
    return getParkingLots(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      isActive: true,
      page: page,
      pageSize: pageSize,
    );
  }

  // Search parking lots
  Future<ParkingLotListResponse> searchParkingLots({
    required String query,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int pageSize = 10,
  }) async {
    return getParkingLots(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      isActive: true,
      page: page,
      pageSize: pageSize,
      search: query,
    );
  }

  // Get parking lot detail
  Future<ParkingLot> getParkingLotDetail(int id) async {
    try {
      print('Fetching parking lot detail for ID: $id');
      
      final response = await _apiClient.get(ApiEndpoints.parkingLotDetail(id));

      print('Parking lot detail response status: ${response.statusCode}');
      try { print('Parking lot detail response data: ${response.data}'); } catch (_) {}

      if (response.statusCode == 200) {
        dynamic data = response.data;
        // Some backends may return a JSON string despite application/json
        if (data is String) {
          try {
            data = _safeJsonDecode(data);
          } catch (e) {
            throw Exception('Invalid JSON format for parking lot detail: $e');
          }
        }
        if (data is Map<String, dynamic>) {
          // Handle wrappers like { data: { lot: {...} } }
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            data = data['data'];
          }
          // Allow either { lot: {...} } or direct lot object
          if (data.containsKey('lot')) {
            return ParkingLotDetailResponse.fromJson(data as Map<String, dynamic>).lot;
          }
          return ParkingLot.fromJson(data as Map<String, dynamic>);
        }
        throw Exception('Unexpected parking lot detail format: ${data.runtimeType}');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch parking lot detail',
        );
      }
    } on DioException catch (e) {
      print('DioException in getParkingLotDetail: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in getParkingLotDetail: $e');
      rethrow;
    }
  }

  // Get parking slots for a specific lot
  Future<List<Map<String, dynamic>>> getParkingSlots(int lotId) async {
    try {
      print('Fetching parking slots for lot ID: $lotId');
      
      final response = await _apiClient.get(ApiEndpoints.parkingSlots(lotId));

      print('Parking slots response status: ${response.statusCode}');
      print('Parking slots response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map<String, dynamic> && response.data['slots'] != null) {
          return List<Map<String, dynamic>>.from(response.data['slots']);
        } else {
          return [];
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch parking slots',
        );
      }
    } on DioException catch (e) {
      print('DioException in getParkingSlots: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in getParkingSlots: $e');
      rethrow;
    }
  }

  // Handle Dio errors
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      switch (statusCode) {
        case 400:
          return Exception('Dữ liệu không hợp lệ: ${data['message'] ?? 'Vui lòng kiểm tra lại thông tin'}');
        case 401:
          return Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại');
        case 403:
          return Exception('Bạn không có quyền thực hiện thao tác này');
        case 404:
          return Exception('Không tìm thấy bãi đỗ xe');
        case 422:
          return Exception('Dữ liệu không hợp lệ: ${data['message'] ?? 'Vui lòng kiểm tra lại thông tin'}');
        case 500:
          return Exception('Lỗi máy chủ. Vui lòng thử lại sau');
        default:
          return Exception('Lỗi không xác định: ${data['message'] ?? e.message}');
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout ||
               e.type == DioExceptionType.sendTimeout) {
      return Exception('Kết nối mạng chậm. Vui lòng thử lại');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng');
    } else {
      return Exception('Lỗi không xác định: ${e.message}');
    }
  }

  // Decode JSON leniently (tolerate BOM or stray whitespace)
  Map<String, dynamic> _safeJsonDecode(String source) {
    final String trimmed = source.trim();
    return (trimmed.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(trimmed) as Map).cast<String, dynamic>());
  }
}
