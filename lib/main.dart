import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_themes.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

// Add a basic app state provider
class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // We'll add providers here later
                ChangeNotifierProvider(create: (_) => AppState()),

      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppThemes.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Beautiful splash screen matching your Figma design
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppThemes.gradientBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Top section with geometric lines (simplified version)
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Geometric decoration
                      Positioned(
                        top: 50,
                        right: 20,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 100,
                        left: -50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Central parking illustration area
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Parking icon placeholder (you can replace with your car illustration)
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                size: 60,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Multiple small cars illustration placeholder
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(3, (index) => Container(
                                width: 40,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  size: 20,
                                  color: AppColors.white,
                                ),
                              )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom section with app info
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo and name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_parking,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppStrings.appName,
                              style: AppThemes.headingMedium.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.appSlogan,
                          style: AppThemes.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        
                        // Start button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to onboarding/login
                              final appState = Provider.of<AppState>(context, listen: false);
                              appState.login(); // Update the login state
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Navigation will be implemented next!'),
                                ),
                              );
                            },
                            child: const Text('Bắt đầu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}