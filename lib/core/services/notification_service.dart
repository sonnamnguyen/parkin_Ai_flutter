import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../../data/models/notification_model.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  Future<List<NotificationModel>> getNotifications({
    int? userId,
    int? lotId,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _api.get(ApiEndpoints.notifications, queryParameters: {
        if (userId != null) 'user_id': userId,
        if (lotId != null) 'lot_id': lotId,
        if (status != null) 'status': status,
        'page': page,
        'page_size': pageSize,
      });
      if (response.statusCode == 200) {
        print('[NotificationService] GET ${ApiEndpoints.notifications} status=${response.statusCode}');
        print('[NotificationService] Raw response: ${response.data}');
        final list1 = _extractList(response.data);
        print('[NotificationService] Extracted list length: ${list1.length}');
        if (list1.isNotEmpty) {
          return list1
              .map((e) => _mapBackendNotification(e as Map<String, dynamic>))
              .toList();
        }

        // Fallback: some backends serve list via /parking-orders
        final response2 = await _api.get(ApiEndpoints.parkingOrders, queryParameters: {
          if (userId != null) 'user_id': userId,
          if (lotId != null) 'lot_id': lotId,
          if (status != null) 'status': status,
          'page': page,
          'page_size': pageSize,
        });
        if (response2.statusCode == 200) {
          print('[NotificationService] Fallback GET ${ApiEndpoints.parkingOrders} status=${response2.statusCode}');
          print('[NotificationService] Fallback raw response: ${response2.data}');
          final list2 = _extractList(response2.data);
          print('[NotificationService] Fallback extracted list length: ${list2.length}');
          return list2
              .map((e) => _mapBackendNotification(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to fetch notifications',
      );
    } on DioException {
      rethrow;
    }
  }

  Future<NotificationModel> getNotificationDetail(int id) async {
    final response = await _api.get(ApiEndpoints.notificationDetail(id));
    if (response.statusCode == 200) {
      final raw = response.data;
      Map<String, dynamic>? payload;
      if (raw is Map<String, dynamic>) {
        if (raw['notification'] is Map<String, dynamic>) {
          payload = raw['notification'] as Map<String, dynamic>;
        } else if (raw['data'] is Map && (raw['data']['notification'] is Map)) {
          payload = (raw['data']['notification'] as Map).cast<String, dynamic>();
        } else {
          payload = raw;
        }
      }
      if (payload != null) {
        return _mapBackendNotification(payload);
      }
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to fetch notification detail',
    );
  }

  Future<bool> markRead({required List<int> ids}) async {
    final response = await _api.post(
      ApiEndpoints.notificationsMarkRead,
      data: { 'ids': ids },
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to mark notifications as read',
    );
  }

  Future<bool> deleteNotification(int id) async {
    final response = await _api.delete(ApiEndpoints.notificationDetail(id));
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to delete notification',
    );
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['list'] is List) return data['list'] as List;
      if (data['data'] is List) return data['data'] as List;
      if (data['data'] is Map && data['data']['list'] is List) return data['data']['list'] as List;
      if (data['results'] is List) return data['results'] as List;
    }
    return const [];
  }

  NotificationModel _mapBackendNotification(Map<String, dynamic> json) {
    // Backend fields: id, user_id, type, content, related_order_id, is_read, created_at, related_info
    final String rawType = (json['type'] as String?)?.toLowerCase() ?? 'system';
    final NotificationType type = _mapType(rawType);
    final String title = _buildTitle(type, json);
    final String message = (json['content'] as String?) ?? '';
    final String createdAtRaw =
        (json['notification_date'] as String?) ??
        (json['created_at'] as String?) ??
        (json['createdAt'] as String?) ??
        '';
    DateTime createdAt = _parseBackendDate(createdAtRaw);
    // Safeguard: some backends send placeholder 2006-01-02 15:04:05
    if (createdAt.year == 2006) {
      final String? alt = (json['updated_at'] as String?) ?? (json['updatedAt'] as String?);
      if (alt != null && alt.isNotEmpty) {
        final parsedAlt = _parseBackendDate(alt);
        if (parsedAlt.year != 2006) {
          createdAt = parsedAlt;
        }
      }
    }

    return NotificationModel(
      id: (json['id'] as num).toInt(),
      title: title,
      message: message,
      type: type,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: createdAt,
      data: json,
    );
  }

  NotificationType _mapType(String raw) {
    switch (raw) {
      case 'order_created':
      case 'order_updated':
      case 'order_confirmed':
      case 'order_cancelled':
        return NotificationType.booking;
      case 'payment_succeeded':
      case 'payment_failed':
        return NotificationType.payment;
      case 'promotion':
        return NotificationType.promotion;
      default:
        return NotificationType.system;
    }
  }

  String _buildTitle(NotificationType type, Map<String, dynamic> json) {
    final String content = (json['content'] as String?) ?? '';
    if (content.isNotEmpty) return content; // use backend content as title
    switch (type) {
      case NotificationType.booking:
        return 'Cập nhật đơn đặt chỗ';
      case NotificationType.payment:
        return 'Cập nhật thanh toán';
      case NotificationType.promotion:
        return 'Khuyến mãi';
      case NotificationType.system:
        return 'Thông báo hệ thống';
    }
  }

  DateTime _parseBackendDate(String raw) {
    // Treat plain timestamps (no timezone) as local time.
    // Support fractional seconds like: 2025-09-07 01:18:59.769184
    try {
      final tzRegex = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');
      final hasTimezone = tzRegex.hasMatch(raw);

      // Try explicit formats without timezone (local time)
      final formats = <DateFormat>[
        DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS'),
        DateFormat('yyyy-MM-dd HH:mm:ss.SSS'),
        DateFormat('yyyy-MM-dd HH:mm:ss'),
      ];
      for (final f in formats) {
        try {
          return f.parse(raw); // parse as local
        } catch (_) {}
      }

      // Fallback to DateTime.parse for ISO strings; convert to local only if tz present
      final dt = DateTime.parse(raw);
      return hasTimezone ? dt.toLocal() : dt;
    } catch (_) {
      return DateTime.now();
    }
  }
}


