class ApiEndpoints {
  // Base URL - update this when your backend is ready
  static const String baseUrl = 'https://api.parkinai.com/v1';
  
  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyCode = '/auth/verify-code';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  
  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String uploadAvatar = '/user/avatar';
  
  // Vehicle endpoints
  static const String vehicles = '/user/vehicles';
  static const String addVehicle = '/user/vehicles';
  static String updateVehicle(int id) => '/user/vehicles/$id';
  static String deleteVehicle(int id) => '/user/vehicles/$id';
  
  // Parking endpoints
  static const String nearbyParkingLots = '/parking/nearby';
  static const String searchParkingLots = '/parking/search';
  static String parkingLotDetail(int id) => '/parking/lots/$id';
  static String parkingSlots(int lotId) => '/parking/lots/$lotId/slots';
  
  // Booking endpoints
  static const String createBooking = '/bookings';
  static const String myBookings = '/bookings/my';
  static String bookingDetail(int id) => '/bookings/$id';
  static String cancelBooking(int id) => '/bookings/$id/cancel';
  
  // Wallet endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String topUp = '/wallet/top-up';
  
  // Services endpoints
  static const String services = '/services';
  static const String nearbyServices = '/services/nearby';
  static String serviceDetail(int id) => '/services/$id';
  static const String bookService = '/services/book';
  
  // Notification endpoints
  static const String notifications = '/notifications';
  static String markAsRead(int id) => '/notifications/$id/read';
  
  // Review endpoints
  static String addReview(int lotId) => '/parking/lots/$lotId/reviews';
  static String lotReviews(int lotId) => '/parking/lots/$lotId/reviews';
  
  // Favorites endpoints
  static const String favorites = '/user/favorites';
  static String addToFavorites(int lotId) => '/user/favorites/$lotId';
  static String removeFromFavorites(int lotId) => '/user/favorites/$lotId';
}

