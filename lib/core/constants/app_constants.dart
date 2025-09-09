class AppConstants {
  // API
  // For Android Emulator, use 10.0.2.2 instead of localhost
  // For iOS Simulator, use localhost
  // For physical devices, use your computer's IP address (e.g., 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:8000/backend/parkin/v1';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String isFirstLaunchKey = 'is_first_launch';
  
  // Map
  static const double defaultLatitude = 10.8231; // Ho Chi Minh City
  static const double defaultLongitude = 106.6297;
  static const double mapZoom = 14.0;
  
  // Booking
  static const int maxBookingHours = 24;
  static const int minBookingMinutes = 30;
  
  // Pagination
  static const int defaultPageSize = 20;

  static const double minTopUpAmount = 50000; // 50k VND
  static const double maxTopUpAmount = 5000000; // 5M VND
  
  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
}