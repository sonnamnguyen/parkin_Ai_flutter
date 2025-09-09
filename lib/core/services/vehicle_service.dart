import 'package:dio/dio.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/vehicle_request_model.dart';
import '../../data/models/vehicle_list_response_model.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  final ApiClient _apiClient = ApiClient();

  // Get vehicles with pagination
  Future<VehicleListResponse> getVehicles({
    String? type,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (type != null) {
        queryParameters['type'] = type;
      }

      final response = await _apiClient.get(
        ApiEndpoints.vehicles,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return VehicleListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch vehicles',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get vehicle detail
  Future<Vehicle> getVehicleDetail(int id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getVehicleDetail(id),
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch vehicle detail',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Add vehicle
  Future<Vehicle> addVehicle(VehicleRequest request) async {
    try {
      print('Adding vehicle with data: ${request.toJson()}');
      final response = await _apiClient.post(
        ApiEndpoints.addVehicle,
        data: request.toJson(),
      );

      print('Add response status: ${response.statusCode}');
      print('Add response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle different response formats
        if (response.data is Map<String, dynamic>) {
          return Vehicle.fromJson(response.data);
        } else if (response.data is String) {
          // If response is just a success message, we need to fetch the vehicle list
          // to get the newly created vehicle, but for now return a placeholder
          throw Exception('Add vehicle returned string response, need to implement fetch logic');
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to add vehicle',
        );
      }
    } on DioException catch (e) {
      print('DioException in addVehicle: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in addVehicle: $e');
      rethrow;
    }
  }

  // Update vehicle
  Future<Vehicle> updateVehicle(int id, VehicleRequest request) async {
    try {
      print('Updating vehicle $id with data: ${request.toJson()}');
      final response = await _apiClient.put(
        ApiEndpoints.updateVehicle(id),
        data: request.toJson(),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle different response formats
        if (response.data is Map<String, dynamic>) {
          return Vehicle.fromJson(response.data);
        } else if (response.data is String) {
          // If response is just a success message, fetch the updated vehicle
          return await getVehicleDetail(id);
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to update vehicle',
        );
      }
    } on DioException catch (e) {
      print('DioException in updateVehicle: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in updateVehicle: $e');
      rethrow;
    }
  }

  // Delete vehicle
  Future<void> deleteVehicle(int id) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteVehicle(id),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to delete vehicle',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle API errors
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['message'] ?? 'An error occurred';
      
      switch (statusCode) {
        case 400:
          return Exception('Bad Request: $message');
        case 401:
          return Exception('Unauthorized: $message');
        case 403:
          return Exception('Forbidden: $message');
        case 404:
          return Exception('Vehicle not found: $message');
        case 422:
          return Exception('Validation Error: $message');
        case 500:
          return Exception('Server Error: $message');
        default:
          return Exception('Error $statusCode: $message');
      }
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}
