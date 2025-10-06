import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../home/home_screen.dart';
import '../profile/my_cars_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/order_history_screen.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();

  // Static variable to store pending lot ID
  static int? _pendingLotId;

  // Static method to set pending lot ID
  static void setPendingLotId(int lotId) {
    debugPrint('=== STATIC setPendingLotId called with lotId: $lotId ===');
    _pendingLotId = lotId;
  }

  // Static method to get and clear pending lot ID
  static int? getAndClearPendingLotId() {
    final lotId = _pendingLotId;
    _pendingLotId = null;
    debugPrint('=== STATIC getAndClearPendingLotId returning: $lotId ===');
    return lotId;
  }
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  static _MainScreenState? _instance;
  
  int _currentIndex = 0;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasUnreadNotifications = false;
  final GlobalKey _homeScreenKey = GlobalKey();
  bool _handledExternalNavigate = false;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _checkUnreadNotifications();
  }

  @override
  void dispose() {
    _instance = null;
    _animationController.dispose();
    super.dispose();
  }

  // Static method to open drawer
  static void openDrawer() {
    _instance?._scaffoldKey.currentState?.openDrawer();
  }

  // Instance method to open parking lot by ID
  void _openParkingLotById(int lotId) {
    debugPrint('=== INSTANCE _openParkingLotById called with lotId: $lotId ===');
    // Switch to home tab first
    if (_currentIndex != 0) {
      debugPrint('Switching to home tab');
      setState(() { _currentIndex = 0; });
    }
    
    // Wait for the home screen to be ready, then call openParkingById
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add extra delay to ensure home screen is fully loaded
      Future.delayed(const Duration(milliseconds: 1000), () {
        final dynamic homeState = _homeScreenKey.currentState;
        debugPrint('Home screen state: $homeState');
        if (homeState != null) {
          try {
            homeState.openParkingById(lotId);
            debugPrint('Successfully called homeState.openParkingById');
          } catch (e) {
            debugPrint('Error calling homeState.openParkingById: $e');
          }
        } else {
          debugPrint('Home screen state is null - retrying...');
          // Retry after another delay
          Future.delayed(const Duration(milliseconds: 1000), () {
            final dynamic homeState2 = _homeScreenKey.currentState;
            debugPrint('Home screen state (retry): $homeState2');
            if (homeState2 != null) {
              try {
                homeState2.openParkingById(lotId);
                debugPrint('Successfully called homeState.openParkingById (retry)');
              } catch (e) {
                debugPrint('Error calling homeState.openParkingById (retry): $e');
              }
            }
          });
        }
      });
    });
  }

  // Handle pending lot ID from static method
  void _handlePendingLotId(int lotId) {
    debugPrint('=== HANDLING PENDING LOT ID: $lotId ===');
    _openParkingLotById(lotId);
  }


  void _onNavigationTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
      Navigator.of(context).pop(); // Close drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for pending lot ID first
    final pendingLotId = MainScreen.getAndClearPendingLotId();
    if (pendingLotId != null) {
      debugPrint('=== MAIN SCREEN FOUND PENDING LOT ID: $pendingLotId ===');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePendingLotId(pendingLotId);
      });
    }

    // Handle incoming navigation arguments to draw route on HomeScreen (once)
    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint('=== MAIN SCREEN DEBUG ===');
    debugPrint('Arguments received: $args');
    debugPrint('Arguments type: ${args.runtimeType}');
    debugPrint('Handled external navigate: $_handledExternalNavigate');
    
    if (!_handledExternalNavigate && args is Map && (args['navigate_to'] is Map || args['open_lot_id'] != null)) {
      debugPrint('Processing navigation arguments...');
      _handledExternalNavigate = true;
      final Map? nav = args['navigate_to'] as Map?;
      final int? openLotId = args['open_lot_id'] as int?;
      final double? lat = (nav?['lat'] is num) ? (nav?['lat'] as num).toDouble() : null;
      final double? lng = (nav?['lng'] is num) ? (nav?['lng'] as num).toDouble() : null;
      final String? name = nav?['name']?.toString();
      
      debugPrint('openLotId: $openLotId');
      debugPrint('lat: $lat, lng: $lng, name: $name');
      
      if (openLotId != null) {
        debugPrint('Opening parking lot by ID: $openLotId');
        if (_currentIndex != 0) {
          debugPrint('Switching to home tab (index 0)');
          setState(() { _currentIndex = 0; });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final dynamic homeState = _homeScreenKey.currentState;
          debugPrint('Home screen state: $homeState');
          debugPrint('Home screen state type: ${homeState.runtimeType}');
          if (homeState != null) {
            debugPrint('Home screen state is not null, calling openParkingById...');
            try { 
              homeState.openParkingById(openLotId);
              debugPrint('Called openParkingById successfully');
            } catch (e) {
              debugPrint('Error calling openParkingById: $e');
              debugPrint('Error type: ${e.runtimeType}');
            }
          } else {
            debugPrint('Home screen state is null - retrying in 1 second...');
            Future.delayed(const Duration(seconds: 1), () {
              final dynamic homeState2 = _homeScreenKey.currentState;
              debugPrint('Home screen state (retry): $homeState2');
              if (homeState2 != null) {
                try {
                  homeState2.openParkingById(openLotId);
                  debugPrint('Called openParkingById successfully (retry)');
                } catch (e) {
                  debugPrint('Error calling openParkingById (retry): $e');
                }
              }
            });
          }
        });
      } else if (lat != null && lng != null) {
        debugPrint('Navigating to coordinates: $lat, $lng');
        if (_currentIndex != 0) {
          debugPrint('Switching to home tab (index 0)');
          setState(() { _currentIndex = 0; });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final dynamic homeState = _homeScreenKey.currentState;
          debugPrint('Home screen state: $homeState');
          try {
            homeState?.navigateToDestination(lat, lng, name);
            debugPrint('Called navigateToDestination successfully');
          } catch (e) {
            debugPrint('Error calling navigateToDestination: $e');
          }
        });
      }
    }
    debugPrint('=== MAIN SCREEN DEBUG END ===');

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getScreenForIndex(_currentIndex),
      ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return HomeScreen(key: _homeScreenKey);
      case 1:
        return const MyCarsScreen();
      case 2:
        return const NotificationsScreen();
      case 3:
        return const OrderHistoryScreen();
      default:
        return const HomeScreen();
    }
  }

  // GlobalKey to reach HomeScreen's state to call navigateToDestination
  // (use plain GlobalKey to avoid private state type coupling)

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              _buildDrawerHeader(),
              
              // Navigation Items
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          _buildNavigationItem(
                            Icons.home_outlined,
                            Icons.home,
                            AppStrings.home,
                            0,
                        
                          ),
                          _buildNavigationItem(
                            Icons.directions_car_outlined,
                            Icons.directions_car,
                            AppStrings.myCars,
                            1,
                         
                          ),
                          _buildNavigationItemWithBadge(
                            Icons.notifications_outlined,
                            Icons.notifications,
                            AppStrings.notifications,
                            2,
                          ),
                          // Favorites styled like others, inactive grey
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushNamed('/favorites');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.favorite_border,
                                        color: AppColors.textSecondary,
                                        size: 24,
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Yêu thích',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildNavigationItem(
                            Icons.receipt_long_outlined,
                            Icons.receipt_long,
                            'Lịch sử giao dịch',
                            3,
                          ),
                          const SizedBox(height: 24),
                          // Settings and Logout
                          _buildBottomActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer
                  Text(
                    'Menu',
                    style: AppThemes.headingMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
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
              
              const SizedBox(height: 20),
              
              // User Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 37,
                  backgroundColor: AppColors.white.withOpacity(0.2),
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // User Name
              Text(
                user?.fullName ?? 'User Name',
                style: AppThemes.headingSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // User Email
              Text(
                user?.email ?? 'user@example.com',
                style: AppThemes.bodyMedium.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    {Widget? customIcon, Widget? customActiveIcon}
  ) {
    final isActive = _currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onNavigationTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primary.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isActive 
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isActive
                      ? (customActiveIcon ?? Icon(
                          activeIcon,
                          key: const ValueKey('active'),
                          color: AppColors.primary,
                          size: 24,
                        ))
                      : (customIcon ?? Icon(
                          icon,
                          key: const ValueKey('inactive'),
                          color: AppColors.textSecondary,
                          size: 24,
                        )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                    ),
                    child: Text(label),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        // Divider
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 1,
          color: AppColors.lightGrey,
        ),
        
        const SizedBox(height: 20),
        
        // Profile
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/profile');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Thông tin cá nhân',
                      style: AppThemes.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.lightGrey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Settings
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to settings
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
                      style: AppThemes.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Logout
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).pop();
                _showLogoutDialog();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_outlined,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Logout',
                      style: AppThemes.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: AppThemes.headingSmall,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppThemes.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Implement logout
              await Provider.of<AuthProvider>(context, listen: false).logout();
              // Navigate to login screen
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (userId == null) return;
      
      final NotificationService notificationService = NotificationService();
      final notifications = await notificationService.getNotifications(
        userId: userId,
        page: 1,
        pageSize: 100, // Get more notifications to check read status
      );
      
      final hasUnread = notifications.any((notification) => !notification.isRead);
      
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (e) {
      // Handle error silently - don't show red dot if we can't check
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = false;
        });
      }
    }
  }

  Widget _buildNavigationItemWithBadge(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isActive = _currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onNavigationTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primary.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isActive 
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    if (_hasUnreadNotifications && index == 2) // Only for notifications
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppThemes.bodyLarge.copyWith(
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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