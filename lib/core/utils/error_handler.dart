import 'package:flutter/material.dart';

class ErrorHandler {
  // Login/Authentication Errors
  static const String loginError = "Email hoặc mật khẩu không đúng";
  static const String signupEmailExistsError = "Email của bạn đã được sử dụng";
  
  // Rating/Comment Errors
  static const String ratingRequiresBookingError = "Bạn cần đặt chỗ trước khi comment";
  
  // Booking Errors
  static const String slotAlreadyBookedError = "Đã có người đặt trước trong khoảng thời gian này";
  
  // Generic Errors
  static const String networkError = "Lỗi kết nối mạng";
  static const String unknownError = "Đã xảy ra lỗi không xác định";

  /// Show error notification with custom message
  static void showErrorNotification(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show login error
  static void showLoginError(BuildContext context) {
    showErrorNotification(context, loginError);
  }

  /// Show signup email exists error
  static void showSignupEmailExistsError(BuildContext context) {
    showErrorNotification(context, signupEmailExistsError);
  }

  /// Show rating requires booking error
  static void showRatingRequiresBookingError(BuildContext context) {
    showErrorNotification(context, ratingRequiresBookingError);
  }

  /// Show slot already booked error
  static void showSlotAlreadyBookedError(BuildContext context) {
    showErrorNotification(context, slotAlreadyBookedError);
  }

  /// Parse API error response and show appropriate message
  static void handleApiError(BuildContext context, dynamic error, {String? fallbackMessage}) {
    String message = fallbackMessage ?? unknownError;
    
    // Try to extract error message from different response formats
    if (error is Map<String, dynamic>) {
      // Check common error message fields
      if (error['message'] != null) {
        message = _mapErrorMessage(error['message'].toString());
      } else if (error['error'] != null) {
        message = _mapErrorMessage(error['error'].toString());
      } else if (error['detail'] != null) {
        message = _mapErrorMessage(error['detail'].toString());
      }
    } else if (error is String) {
      message = _mapErrorMessage(error);
    }
    
    showErrorNotification(context, message);
  }

  /// Map common API error messages to Vietnamese messages
  static String _mapErrorMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    
    // Login errors
    if (lowerError.contains('invalid credentials') || 
        lowerError.contains('wrong password') ||
        lowerError.contains('incorrect email') ||
        lowerError.contains('authentication failed') ||
        lowerError.contains('login failed')) {
      return loginError;
    }
    
    // Signup errors
    if (lowerError.contains('email already exists') ||
        lowerError.contains('email is already taken') ||
        lowerError.contains('user already exists') ||
        lowerError.contains('duplicate email')) {
      return signupEmailExistsError;
    }
    
    // Booking errors
    if (lowerError.contains('slot already booked') ||
        lowerError.contains('time slot unavailable') ||
        lowerError.contains('already reserved') ||
        lowerError.contains('booking conflict') ||
        lowerError.contains('time conflict')) {
      return slotAlreadyBookedError;
    }
    
    // Rating errors
    if (lowerError.contains('no booking found') ||
        lowerError.contains('must book first') ||
        lowerError.contains('booking required') ||
        lowerError.contains('cannot rate without booking')) {
      return ratingRequiresBookingError;
    }
    
    // Network errors
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('no internet')) {
      return networkError;
    }
    
    // Return original message if no mapping found
    return errorMessage;
  }
}
