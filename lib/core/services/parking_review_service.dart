import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/parking_review_model.dart';

class ParkingReviewService {
  final ApiClient _api = ApiClient();

  // Create review
  Future<ParkingReview> createReview(CreateReviewRequest request) async {
    try {
      print('=== CREATE PARKING REVIEW ===');
      print('Request: ${request.toJson()}');
      
      final Response response = await _api.post(
        ApiEndpoints.parkingLotReviews,
        data: request.toJson(),
      );
      
      print('Create review response status: ${response.statusCode}');
      print('Create review response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ParkingReview.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to create review: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in createReview: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in createReview: $e');
      rethrow;
    }
  }

  // Get reviews list
  Future<ReviewListResponse> getReviews({
    int? lotId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('=== GET REVIEWS LIST ===');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (lotId != null) queryParams['lot_id'] = lotId;
      
      print('Query params: $queryParams');
      
      final Response response = await _api.get(
        ApiEndpoints.parkingLotReviews,
        queryParameters: queryParams,
      );
      
      print('Reviews list response status: ${response.statusCode}');
      print('Reviews list response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return ReviewListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get reviews: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in getReviews: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in getReviews: $e');
      rethrow;
    }
  }

  // Get review detail
  Future<ParkingReview> getReviewDetail(int reviewId) async {
    try {
      print('=== GET REVIEW DETAIL ===');
      print('Review ID: $reviewId');
      
      final Response response = await _api.get(
        ApiEndpoints.parkingLotReviewDetail(reviewId),
      );
      
      print('Review detail response status: ${response.statusCode}');
      print('Review detail response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return ParkingReview.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get review detail: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in getReviewDetail: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in getReviewDetail: $e');
      rethrow;
    }
  }

  // Update review
  Future<ParkingReview> updateReview(UpdateReviewRequest request) async {
    try {
      print('=== UPDATE REVIEW ===');
      print('Request: ${request.toJson()}');
      
      final Response response = await _api.put(
        ApiEndpoints.parkingLotReviewDetail(request.id),
        data: request.toJson(),
      );
      
      print('Update review response status: ${response.statusCode}');
      print('Update review response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return ParkingReview.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to update review: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in updateReview: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in updateReview: $e');
      rethrow;
    }
  }

  // Delete review
  Future<void> deleteReview(int reviewId) async {
    try {
      print('=== DELETE REVIEW ===');
      print('Review ID: $reviewId');
      
      final Response response = await _api.delete(
        ApiEndpoints.parkingLotReviewDetail(reviewId),
      );
      
      print('Delete review response status: ${response.statusCode}');
      print('Delete review response data: ${response.data}');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to delete review: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException in deleteReview: $e');
      print('Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in deleteReview: $e');
      rethrow;
    }
  }
}
