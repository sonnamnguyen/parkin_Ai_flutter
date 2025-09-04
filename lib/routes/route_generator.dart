import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/verification_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/profile/my_cars_screen.dart';
import '../presentation/screens/parking/parking_detail_screen.dart';
import '../presentation/screens/parking/slot_selection_screen.dart';
import '../presentation/screens/parking/order_detail_screen.dart';
import '../presentation/screens/parking/schedule_screen.dart';
import '../presentation/screens/parking/payment_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart' as notifications;
import '../data/models/parking_lot_model.dart';
import '../data/models/parking_slot_model.dart';
import '../main.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case AppRoutes.verification:
        return MaterialPageRoute(
          builder: (_) => const VerificationScreen(),
          settings: settings, // Pass arguments to screen
        );

      case AppRoutes.verificationSuccess:
        return MaterialPageRoute(
          builder: (_) => const VerificationSuccessScreen(),
        );

      case AppRoutes.main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );

      case AppRoutes.myCars:
        return MaterialPageRoute(
          builder: (_) => const MyCarsScreen(),
        );

      case AppRoutes.search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
        );

      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const notifications.NotificationsScreen(),
        );

      case AppRoutes.parkingDetail:
        if (args is ParkingLot) {
          return MaterialPageRoute(
            builder: (_) => ParkingDetailScreen(parkingLot: args),
          );
        }
        return _errorRoute();

      case AppRoutes.selectSlot:
        if (args is ParkingLot) {
          return MaterialPageRoute(
            builder: (_) => SlotSelectionScreen(parkingLot: args),
          );
        }
        return _errorRoute();

      case AppRoutes.orderDetail:
        if (args is Map<String, dynamic>) {
          final parkingLot = args['parkingLot'] as ParkingLot;
          final selectedSlot = args['selectedSlot'] as ParkingSlot;
          return MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              parkingLot: parkingLot,
              selectedSlot: selectedSlot,
            ),
          );
        }
        return _errorRoute();

      case AppRoutes.schedule:
        return MaterialPageRoute(
          builder: (_) => const ScheduleScreen(),
        );

      case AppRoutes.payment:
        return MaterialPageRoute(
          builder: (_) => const PaymentScreen(),
        );

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const ErrorScreen(),
    );
  }
}

// Verification Success Screen
class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Thành Công!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Chúc mừng, đã hoàn tất đặt vé đậu xe thành công',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.main,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Error Screen
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Page not found',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'The requested route does not exist.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}