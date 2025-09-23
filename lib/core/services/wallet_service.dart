import 'package:dio/dio.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final ApiClient _apiClient = ApiClient();

  // Get wallet balance
  Future<double> getWalletBalance() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletBalance);
      
      if (response.statusCode == 200) {
        return (response.data['balance'] ?? 0).toDouble();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get wallet balance',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get wallet transactions with pagination
  Future<WalletTransactionResponse> getWalletTransactions({
    String? type,
    String? description,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      if (description != null && description.isNotEmpty) {
        queryParams['description'] = description;
      }

      final response = await _apiClient.get(
        ApiEndpoints.walletTransactions,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return WalletTransactionResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get wallet transactions',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Top up wallet
  Future<Map<String, dynamic>> topUpWallet({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.topUp,
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Top up failed',
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
