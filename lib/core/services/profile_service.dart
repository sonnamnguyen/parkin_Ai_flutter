import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/profile_response_model.dart';
import '../../data/models/profile_update_request_model.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  // Get user profile
  Future<ProfileResponse> getProfile() async {
    try {
      print('Fetching user profile...');
      final response = await _apiClient.get(ApiEndpoints.profile);
      
      print('Profile response status: ${response.statusCode}');
      print('Profile response data: ${response.data}');

      if (response.statusCode == 200) {
        return ProfileResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch profile',
        );
      }
    } on DioException catch (e) {
      print('DioException in getProfile: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in getProfile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<ProfileResponse> updateProfile(ProfileUpdateRequest request) async {
    try {
      print('Updating profile with data: ${request.toJson()}');
      final response = await _apiClient.put(
        ApiEndpoints.updateProfile,
        data: request.toJson(),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle different response formats
        if (response.data is Map<String, dynamic>) {
          return ProfileResponse.fromJson(response.data);
        } else if (response.data is String) {
          // If response is just a success message, fetch the updated profile
          return await getProfile();
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to update profile',
        );
      }
    } on DioException catch (e) {
      print('DioException in updateProfile: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in updateProfile: $e');
      rethrow;
    }
  }

  // Upload avatar
  Future<String> uploadAvatar(String imagePath) async {
    try {
      print('Uploading avatar: $imagePath');
      
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiClient.post(
        ApiEndpoints.uploadAvatar,
        data: formData,
      );

      print('Upload avatar response status: ${response.statusCode}');
      print('Upload avatar response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data['avatar_url']?.toString() ?? '';
        } else if (response.data is String) {
          return response.data;
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to upload avatar',
        );
      }
    } on DioException catch (e) {
      print('DioException in uploadAvatar: $e');
      throw _handleError(e);
    } catch (e) {
      print('General error in uploadAvatar: $e');
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
          return Exception('Không tìm thấy thông tin người dùng');
        case 409:
          return Exception('Email hoặc số điện thoại đã được sử dụng');
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
}
