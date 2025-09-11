import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  final List<NotificationModel> _notifications = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      final items = await _service.getNotifications(userId: userId, page: 1, pageSize: 20);
      debugPrint('[NotificationsScreen] Applying ${items.length} items to state');
      setState(() {
        _notifications
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      setState(() {
        _error = 'Không tải được thông báo';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
         leading: IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/main'),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkGrey),
        ),
        title: Text(
          'Thông báo',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Đánh dấu tất cả',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? Center(child: Text(_error!))
                : (_notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo',
            style: AppThemes.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo mới sẽ xuất hiện tại đây',
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Always darker-than-background card color
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        // Highlight unread with a subtle border
        border: notification.isRead
            ? Border.all(color: AppColors.textSecondary.withOpacity(0.06))
            : Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildNotificationIcon(notification.type),
        title: Text(
          notification.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppThemes.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: notification.isRead ? AppColors.textSecondary : AppColors.darkGrey,
          ),
        ),
        subtitle: Text(
          notification.timeAgo,
          style: AppThemes.caption.copyWith(
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _onTapNotification(notification),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case NotificationType.booking:
        icon = Icons.local_parking;
        color = AppColors.primary;
        break;
      case NotificationType.payment:
        icon = Icons.account_balance_wallet;
        color = AppColors.success;
        break;
      case NotificationType.system:
        icon = Icons.info;
        color = AppColors.info;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer;
        color = AppColors.warning;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Future<void> _onTapNotification(NotificationModel notification) async {
    try {
      final detail = await _service.getNotificationDetail(notification.id);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chi tiết thông báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('type: ${detail.type.name}'),
              const SizedBox(height: 8),
              Text('content:'),
              const SizedBox(height: 4),
              Text(detail.message),
              const SizedBox(height: 8),
              Text('created_at: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(detail.createdAt)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      // Mark read after viewing
      await _service.markRead(ids: [notification.id]);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            title: detail.title,
            message: detail.message,
            type: detail.type,
            isRead: true,
            createdAt: detail.createdAt,
            data: detail.data,
          );
        }
      });
    } catch (_) {
      // ignore for now
    }
  }

  Future<void> _markAllAsRead() async {
    final ids = _notifications.where((n) => !n.isRead).map((e) => e.id).toList();
    if (ids.isEmpty) return;
    try {
      await _service.markRead(ids: ids);
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          final n = _notifications[i];
          _notifications[i] = NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            data: n.data,
          );
        }
      });
    } catch (_) {}
  }
}