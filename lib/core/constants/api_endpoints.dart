class ApiEndpoints {
  
  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyCode = '/auth/verify-code';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  
  // User endpoints
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String uploadAvatar = '/profile/avatar';
  
  // Vehicle endpoints
  static const String vehicles = '/vehicles';
  static const String addVehicle = '/vehicles';
  static String updateVehicle(int id) => '/vehicles/$id';
  static String deleteVehicle(int id) => '/vehicles/$id';
  static String getVehicleDetail(int id) => '/vehicles/$id';
  
  // Parking endpoints
  static const String parkingLots = '/parking-lots';
  static String parkingLotDetail(int id) => '/parking-lots/$id';
  static String parkingSlots(int lotId) => '/parking-lots/$lotId/slots';
  static const String searchParkingSlots = '/parking-slots';
  static const String nearbyParkingLots = '/parking/nearby';
  static const String searchParkingLots = '/parking/search';
  
  // Booking endpoints
  static const String createBooking = '/bookings';
  static const String myBookings = '/bookings/my';
  static String bookingDetail(int id) => '/bookings/$id';
  static String cancelBooking(int id) => '/bookings/$id/cancel';
  
  // Parking Order endpoints
  static const String parkingOrders = '/parking-orders';
  static String parkingOrderDetail(int id) => '/parking-orders/$id';
  
  // Wallet endpoints
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String topUp = '/wallet/top-up';
  
  // Services endpoints
  static const String services = '/services';
  static const String nearbyServices = '/services/nearby';
  static String serviceDetail(int id) => '/services/$id';
  static const String bookService = '/services/book';
  // Other services (per lot) and service orders
  static const String otherServices = '/others-services';
  static const String serviceOrders = '/service-orders';
  
  // Notification endpoints
  static const String notifications = '/notifications';
  static String notificationDetail(int id) => '/notifications/$id';
  static const String notificationsMarkRead = '/notifications/mark-read';
  
  // Review endpoints
  static const String parkingLotReviews = '/parking-lot-reviews';
  static String parkingLotReviewDetail(int id) => '/parking-lot-reviews/$id';
  
  // Favorites endpoints (backend: /favorites)
  static const String favorites = '/favorites';
  static String favoriteDetail(int id) => '/favorites/$id';

  // Payment endpoints
  static const String createPaymentLink = '/create-payment-link';
}

