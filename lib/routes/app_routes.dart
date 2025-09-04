class AppRoutes {
  // Authentication routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verification = '/verification';
  static const String verificationSuccess = '/verification-success';
  static const String forgotPassword = '/forgot-password';

  // Main app routes
  static const String main = '/main';
  static const String home = '/home';

  // Profile routes
  static const String myCars = '/my-cars';
  static const String addCar = '/add-car';
  static const String editCar = '/edit-car';

  // Parking routes
  static const String parkingMap = '/parking-map';
  static const String parkingDetail = '/parking-detail';
  static const String selectSlot = '/select-slot';
  static const String orderDetail = '/order-detail';
  static const String schedule = '/schedule';
  static const String payment = '/payment';
  static const String ticket = '/ticket';

  // Search routes
  static const String search = '/search';
  static const String searchResults = '/search-results';
  static const String categories = '/categories';

  // Wallet routes
  static const String wallet = '/wallet';
  static const String topUp = '/top-up';
  static const String transactions = '/transactions';

  // Services routes
  static const String services = '/services';
  static const String serviceDetail = '/service-detail';

  // Other routes
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String help = '/help';
}