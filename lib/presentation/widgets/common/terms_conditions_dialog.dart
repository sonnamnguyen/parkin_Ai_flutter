import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';

class TermsConditionsDialog extends StatelessWidget {
  const TermsConditionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Điều khoản & Điều kiện Sử dụng',
                      style: AppThemes.headingSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '1. Chấp nhận Điều khoản',
                      'Khi cài đặt và sử dụng ứng dụng, bạn đồng ý với các Điều khoản & Điều kiện này. Nếu bạn không đồng ý, vui lòng ngừng sử dụng ứng dụng.',
                    ),
                    
                    _buildSection(
                      '2. Quyền truy cập vị trí',
                      'Ứng dụng có thể yêu cầu quyền truy cập vào vị trí thiết bị của bạn để cung cấp các tính năng như tìm kiếm bãi đỗ xe, dẫn đường hoặc hiển thị thông tin liên quan.\n\nVị trí của bạn chỉ được sử dụng cho mục đích nâng cao trải nghiệm trong ứng dụng, không được chia sẻ cho bên thứ ba khi chưa có sự đồng ý của bạn.\n\nBạn có thể thay đổi quyền truy cập vị trí trong phần Cài đặt của thiết bị.',
                    ),
                    
                    _buildSection(
                      '3. Quyền gửi thông báo',
                      'Ứng dụng có thể gửi thông báo (push notification) để cập nhật thông tin quan trọng, nhắc nhở, khuyến mãi hoặc cảnh báo liên quan đến dịch vụ.\n\nBạn có thể bật/tắt quyền nhận thông báo trong phần Cài đặt của thiết bị bất kỳ lúc nào.',
                    ),
                    
                    _buildSection(
                      '4. Trách nhiệm của người dùng',
                      'Bạn cam kết cung cấp thông tin chính xác khi sử dụng ứng dụng.\n\nKhông sử dụng ứng dụng vào các mục đích trái pháp luật hoặc gây ảnh hưởng đến người khác.',
                    ),
                    
                    _buildSection(
                      '5. Giới hạn trách nhiệm',
                      'Ứng dụng nỗ lực đảm bảo dữ liệu vị trí và thông báo chính xác, nhưng không cam kết tuyệt đối về độ chính xác 100%.\n\nNhà phát triển không chịu trách nhiệm với các thiệt hại phát sinh do việc sử dụng sai cách hoặc lỗi kỹ thuật ngoài tầm kiểm soát.',
                    ),
                    
                    _buildSection(
                      '6. Thay đổi Điều khoản',
                      'Chúng tôi có thể cập nhật Điều khoản này bất kỳ lúc nào. Phiên bản mới sẽ được công bố trong ứng dụng và có hiệu lực ngay khi đăng tải.',
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Không đồng ý',
                        style: AppThemes.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Đồng ý',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppThemes.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppThemes.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TermsConditionsDialog(),
    );
  }
}
