import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

class PaymentLinkResponse {
  final String paymentLinkId;
  final String checkoutUrl;
  final String qrCode;
  final int amount;
  final int orderCode;

  PaymentLinkResponse({
    required this.paymentLinkId,
    required this.checkoutUrl,
    required this.qrCode,
    required this.amount,
    required this.orderCode,
  });

  factory PaymentLinkResponse.fromJson(Map<String, dynamic> json) {
    return PaymentLinkResponse(
      paymentLinkId: json['paymentLinkId']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentService {
  final ApiClient _api = ApiClient();

  Future<PaymentLinkResponse> createPaymentLink({
    required String orderType,
    required int orderId,
  }) async {
    print('=== CREATING PAYMENT LINK ===');
    print('Order Type: $orderType');
    print('Order ID: $orderId');
    
    final Response response = await _api.post(
      ApiEndpoints.createPaymentLink,
      data: {
        'order_type': orderType,
        'order_id': orderId,
      },
    );

    print('Payment link response status: ${response.statusCode}');
    print('Payment link response data: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Some backends wrap under data
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          final paymentData = data['data'] as Map<String, dynamic>;
          print('Payment data: $paymentData');
          return PaymentLinkResponse.fromJson(paymentData);
        }
        print('Direct payment data: $data');
        return PaymentLinkResponse.fromJson(data);
      }
      print('Raw response data: ${response.data}');
      return PaymentLinkResponse.fromJson(response.data as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to create payment link',
    );
  }
}


