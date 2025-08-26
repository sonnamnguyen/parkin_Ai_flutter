class AppConstants {
  // API
  static const String baseUrl = 'https://api.parkinai.com/v1';
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
  
  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
}