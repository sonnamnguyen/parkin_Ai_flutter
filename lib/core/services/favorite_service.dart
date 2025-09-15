import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/favorite_model.dart';

class FavoriteService {
  final ApiClient _api = ApiClient();

  Future<void> addFavorite({required int lotId}) async {
    final Response response = await _api.post(
      ApiEndpoints.favorites,
      data: { 'lot_id': lotId },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to add favorite',
      );
    }
  }

  Future<FavoriteListResponse> getFavorites({
    String? lotName,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Response response = await _api.get(
      ApiEndpoints.favorites,
      queryParameters: {
        if (lotName != null && lotName.isNotEmpty) 'lot_name': lotName,
        'page': page,
        'page_size': pageSize,
      },
    );
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        return FavoriteListResponse.fromJson(response.data as Map<String, dynamic>);
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to fetch favorites',
    );
  }

  Future<void> deleteFavorite(int id) async {
    final Response response = await _api.delete(
      ApiEndpoints.favoriteDetail(id),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to delete favorite',
      );
    }
  }
}


