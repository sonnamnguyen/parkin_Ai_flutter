import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/parking_order_model.dart';

class ParkingOrderService {
  final ApiClient _api = ApiClient();

  // Create parking order
  Future<ParkingOrder> createOrder(CreateOrderRequest request) async {
    try {
      print('=== CREATE PARKING ORDER ===');
      print('Request: ${request.toJson()}');
      
      final Response response = await _api.post(
        ApiEndpoints.parkingOrders,
        data: request.toJson(),
      );
      
      print('Create order response status: ${response.statusCode}');
      print('Create order response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Some backends wrap the object
        if (response.data is Map<String, dynamic>) {
          final Map<String, dynamic> body = response.data as Map<String, dynamic>;
          if (body['data'] is Map<String, dynamic>) {
            return ParkingOrder.fromJson(body['data'] as Map<String, dynamic>);
          }
          // Minimal response: { "id": number }
          if (body['id'] != null) {
            final int id = (body['id'] as num).toInt();
            // Fetch full order detail using returned id
            return await getOrderDetail(id);
          }
          return ParkingOrder.fromJson(body);
        }
        // Fallback attempt
        return ParkingOrder.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to create parking order: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in createOrder: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in createOrder: $e');
      rethrow;
    }
  }

  // Get order history with filters
  Future<OrderListResponse> getOrderHistory({
    int? userId,
    int? lotId,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('=== GET ORDER HISTORY ===');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (userId != null) queryParams['user_id'] = userId;
      if (lotId != null) queryParams['lot_id'] = lotId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      
      print('Query params: $queryParams');
      
      final Response response = await _api.get(
        ApiEndpoints.parkingOrders,
        queryParameters: queryParams,
      );
      
      print('Order history response status: ${response.statusCode}');
      print('Order history response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return OrderListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get order history: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in getOrderHistory: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in getOrderHistory: $e');
      rethrow;
    }
  }

  // Get order detail
  Future<ParkingOrder> getOrderDetail(int orderId) async {
    try {
      print('=== GET ORDER DETAIL ===');
      print('Order ID: $orderId');
      
      final Response response = await _api.get(
        ApiEndpoints.parkingOrderDetail(orderId),
      );
      
      print('Order detail response status: ${response.statusCode}');
      print('Order detail response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['order'] is Map<String, dynamic>) {
            return ParkingOrder.fromJson(data['order'] as Map<String, dynamic>);
          }
          if (data['data'] is Map<String, dynamic>) {
            final inner = data['data'] as Map<String, dynamic>;
            if (inner['order'] is Map<String, dynamic>) {
              return ParkingOrder.fromJson(inner['order'] as Map<String, dynamic>);
            }
            return ParkingOrder.fromJson(inner);
          }
          return ParkingOrder.fromJson(data);
        }
        return ParkingOrder.fromJson({'id': orderId});
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get order detail: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in getOrderDetail: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in getOrderDetail: $e');
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(int orderId) async {
    try {
      print('=== CANCEL ORDER ===');
      print('Order ID: $orderId');
      
      final Response response = await _api.put(
        ApiEndpoints.parkingOrderDetail(orderId),
        data: {'status': 'cancelled'},
      );
      
      print('Cancel order response status: ${response.statusCode}');
      print('Cancel order response data: ${response.data}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to cancel order: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in cancelOrder: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in cancelOrder: $e');
      rethrow;
    }
  }
}
