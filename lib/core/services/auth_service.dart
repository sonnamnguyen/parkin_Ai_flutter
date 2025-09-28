import 'package:dio/dio.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  // Login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Save token and user data
        await _storageService.saveToken(authResponse.accessToken);
        await _storageService.saveUserData(authResponse.toJson().toString());
        
        return authResponse;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Login failed',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Register
  Future<void> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful - no tokens returned, just user data
        // User needs to login separately to get tokens
        return;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Registration failed',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // Clear local storage
      await _storageService.removeToken();
      await _storageService.removeUserData();
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _storageService.getToken() != null;
  }

  // Get stored token
  String? getToken() {
    return _storageService.getToken();
  }

  // Get stored user data
  String? getUserData() {
    return _storageService.getUserData();
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
          // Wrong credentials or unauthorized
          final lower = message.toString().toLowerCase();
          final isWrongCreds = lower.contains('invalid') || lower.contains('wrong') || lower.contains('unauthorized') || lower.contains('sai') || lower.contains('không đúng');
          return Exception(isWrongCreds
              ? 'Email hoặc mật khẩu không đúng.'
              : 'Không có quyền truy cập: $message');
        case 403:
          return Exception('Forbidden: $message');
        case 404:
          return Exception('Not Found: $message');
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
