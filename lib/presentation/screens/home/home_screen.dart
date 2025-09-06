import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/parking_hours_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isAnalyzing = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLocationPermissionGranted = false;
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _isLoadingLocation = true;

  // Ho Chi Minh City center coordinates
  static const LatLng _hcmCenter = LatLng(10.8231, 106.6297);
  
  // Mock data for nearby parking lots in HCMC area
  final List<ParkingLot> _nearbyParking = [
    ParkingLot(
      id: 1,
      name: 'Bãi xe Đại học Khoa học Tự nhiên',
      address: '227 Nguyễn Văn Cừ, Quận 5, TP.HCM',
      latitude: 10.7624,
      longitude: 106.6808,
      pricePerHour: 15000,
      totalSlots: 50,
      availableSlots: 12,
      rating: 4.1,
      reviewCount: 127,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ 24/7'],
      description: 'Bãi đậu xe an toàn gần đại học',
      operatingHours: ParkingHours(
        monday: '06:00 - 22:00',
        tuesday: '06:00 - 22:00',
        wednesday: '06:00 - 22:00',
        thursday: '06:00 - 22:00',
        friday: '06:00 - 22:00',
        saturday: '06:00 - 22:00',
        sunday: '06:00 - 22:00',
      ),
      isOpen: true,
      distance: 500,
    ),
    ParkingLot(
      id: 2,
      name: 'Bãi xe Nguyễn Đình Chiểu',
      address: '283 Nguyễn Đình Chiểu, Quận 3, TP.HCM',
      latitude: 10.7798,
      longitude: 106.6879,
      pricePerHour: 20000,
      totalSlots: 35,
      availableSlots: 8,
      rating: 4.3,
      reviewCount: 89,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ 24/7', 'Mái che'],
      description: 'Bãi đậu xe trung tâm quận 3',
      operatingHours: ParkingHours(
        monday: '06:00 - 23:00',
        tuesday: '06:00 - 23:00',
        wednesday: '06:00 - 23:00',
        thursday: '06:00 - 23:00',
        friday: '06:00 - 23:00',
        saturday: '06:00 - 23:00',
        sunday: '06:00 - 23:00',
      ),
      isOpen: true,
      distance: 300,
    ),
    ParkingLot(
      id: 3,
      name: 'Bãi xe Lotte Mart',
      address: '469 Nguyễn Hữu Thọ, Quận 7, TP.HCM',
      latitude: 10.7411,
      longitude: 106.7200,
      pricePerHour: 10000,
      totalSlots: 120,
      availableSlots: 45,
      rating: 4.5,
      reviewCount: 203,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ 24/7', 'Mái che', 'Thang máy'],
      description: 'Bãi đậu xe tại trung tâm thương mại',
      operatingHours: ParkingHours(
        monday: '07:00 - 22:00',
        tuesday: '07:00 - 22:00',
        wednesday: '07:00 - 22:00',
        thursday: '07:00 - 22:00',
        friday: '07:00 - 22:00',
        saturday: '07:00 - 23:00',
        sunday: '07:00 - 23:00',
      ),
      isOpen: true,
      distance: 1200,
    ),
    ParkingLot(
      id: 4,
      name: 'Bãi xe Thủ Đức',
      address: 'Đường Võ Văn Ngân, TP. Thủ Đức, TP.HCM',
      latitude: 10.8505,
      longitude: 106.7717,
      pricePerHour: 12000,
      totalSlots: 80,
      availableSlots: 23,
      rating: 4.0,
      reviewCount: 156,
      imageUrl: '',
      amenities: ['CCTV', 'Bảo vệ ban ngày'],
      description: 'Bãi đậu xe gần khu công nghệ cao',
      operatingHours: ParkingHours(
        monday: '06:30 - 21:30',
        tuesday: '06:30 - 21:30',
        wednesday: '06:30 - 21:30',
        thursday: '06:30 - 21:30',
        friday: '06:30 - 21:30',
        saturday: '07:00 - 21:00',
        sunday: '07:00 - 21:00',
      ),
      isOpen: true,
      distance: 2500,
    ),
  ];

  ParkingLot? _selectedParking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });
      
      await _checkLocationPermission();
      
      if (_isLocationPermissionGranted) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationPermissionGranted = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationPermissionGranted = false;
        });
        _showLocationPermissionDialog();
        return;
      }

      setState(() {
        _isLocationPermissionGranted = permission == LocationPermission.whileInUse || 
                                     permission == LocationPermission.always;
      });

      if (!_isLocationPermissionGranted) {
        _showLocationPermissionDialog();
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      setState(() {
        _isLocationPermissionGranted = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) return;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location timeout');
        },
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      if (_isMapReady) {
        _updateMapLocation();
        _createMarkersFromParkingLots();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Use default HCMC location if can't get current location
      if (_isMapReady) {
        _createMarkersFromParkingLots();
      }
    }
  }

  void _updateMapLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _showLocationPermissionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền truy cập vị trí'),
        content: const Text(
          'Ứng dụng cần quyền truy cập vị trí để hiển thị các bãi đậu xe gần bạn. Vui lòng cấp quyền trong cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Cài đặt'),
          ),
        ],
      ),
    );
  }

  Future<void> _createMarkersFromParkingLots() async {
    if (!mounted) return;
    
    final Set<Marker> markers = {};
    
    try {
      // Add current location marker if available
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          ),
        );
      }

      // Add parking lot markers
      for (final parking in _nearbyParking) {
        markers.add(
          Marker(
            markerId: MarkerId(parking.id.toString()),
            position: LatLng(parking.latitude, parking.longitude),
            icon: parking.hasAvailableSlots
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: parking.name,
              snippet: '${parking.availableSlots}/${parking.totalSlots} slots - ${parking.priceText}',
            ),
            onTap: () => _selectParking(parking),
          ),
        );
      }

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      debugPrint('Error creating markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header Section
          Container(
            decoration: AppThemes.gradientBackground,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Top Bar with User Info
                  _buildTopBar(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Google Maps Section
          Expanded(
            child: Stack(
              children: [
                // Loading indicator
                if (_isLoadingLocation)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải bản đồ...'),
                      ],
                    ),
                  )
                else
                  // Google Maps
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null 
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : _hcmCenter,
                      zoom: 14,
                    ),
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController = controller;
                      
                      // Add a small delay to ensure map is fully initialized
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      setState(() {
                        _isMapReady = true;
                      });
                      
                      await _createMarkersFromParkingLots();
                    },
                    markers: _markers,
                    myLocationEnabled: _isLocationPermissionGranted,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    onTap: (_) {
                      if (_selectedParking != null) {
                        setState(() {
                          _selectedParking = null;
                        });
                      }
                    },
                    mapType: MapType.normal,
                    // Add lite mode for better performance on some devices
                    liteModeEnabled: false,
                    // Disable traffic to reduce network requests
                    trafficEnabled: false,
                  ),

                // Vehicle Card Overlay
                if (_selectedParking != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildVehicleCard(parking: _selectedParking!),
                  ),

                // My Location Button
                if (!_isLoadingLocation)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppColors.white,
                      onPressed: _getCurrentLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                // Quick Actions at Bottom
                Positioned(
                  bottom: 80,
                  left: 16,
                  right: 16,
                  child: _buildQuickActions(),
                ),

                // Search Bar at Bottom
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildSearchBar(),
                ),

                // AI Analysis Button (animated)
                if (_isAnalyzing)
                  Positioned(
                    bottom: 160,
                    left: 0,
                    right: 0,
                    child: _buildAIAnalysisButton(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Row(
          children: [
            // Menu Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.white,
                  size: 20,
                ),
                onPressed: () {
                  final ScaffoldState? scaffoldState =
                      context.findAncestorStateOfType<ScaffoldState>();
                  scaffoldState?.openDrawer();
                },
              ),
            ),

            const SizedBox(width: 12),
            const Spacer(),

            // Map Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.map,
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),
            const SizedBox(width: 12),

            // User Avatar
            GestureDetector(
              onTap: () {
                // TODO: Navigate to profile
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.white.withOpacity(0.2),
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectParking(ParkingLot parking) {
    setState(() {
      _selectedParking = _selectedParking?.id == parking.id ? null : parking;
    });

    // Animate to selected parking location
    if (_selectedParking != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(parking.latitude, parking.longitude),
          16,
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchLocation,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: AppThemes.bodyMedium,
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/search');
              },
              readOnly: true,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement voice search
            },
            icon: const Icon(
              Icons.mic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({required ParkingLot parking}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/parking-detail',
          arguments: parking,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bãi đậu xe',
                    style: AppThemes.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    parking.name,
                    style: AppThemes.headingMedium.copyWith(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_parking,
                        color: AppColors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${parking.availableSlots}/${parking.totalSlots} slots',
                        style: AppThemes.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.monetization_on,
                        color: AppColors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        parking.priceText,
                        style: AppThemes.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: Icons.home,
          label: AppStrings.nearby,
          color: AppColors.primary,
          onTap: () {
            _triggerAIAnalysis();
          },
        ),
        _buildQuickActionButton(
          icon: Icons.directions_car,
          label: 'Chợ',
          color: AppColors.info,
          onTap: () => _filterParkingByType('market'),
        ),
        _buildQuickActionButton(
          icon: Icons.fitness_center,
          label: 'Gym',
          color: AppColors.warning,
          onTap: () => _filterParkingByType('gym'),
        ),
        _buildQuickActionButton(
          icon: Icons.account_balance,
          label: 'Bank',
          color: AppColors.success,
          onTap: () => _filterParkingByType('bank'),
        ),
      ],
    );
  }

  void _filterParkingByType(String type) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tìm kiếm bãi đậu xe gần $type'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppThemes.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisButton() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Đang phân tích vị trí của bạn...',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerAIAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });

    // Simulate AI analysis
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showAIResult();
      }
    });
  }

  void _showAIResult() {
    if (!mounted) return;
    
    final bestParking = _findBestParkingLot();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
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
                Icons.auto_awesome,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Kết quả phân tích AI',
              style: AppThemes.headingSmall,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đây là bãi đậu xe tốt nhất gần vị trí của bạn!',
              style: AppThemes.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (bestParking != null) ...[
              Text(
                'Đề xuất:',
                style:
                    AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bestParking.name,
                      style: AppThemes.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_parking,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bestParking.availableSlots} chỗ trống',
                          style: AppThemes.bodySmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bestParking.priceText,
                          style: AppThemes.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bestParking.distance}m',
                          style: AppThemes.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: AppThemes.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (bestParking != null) {
                _selectParking(bestParking);
                Navigator.of(context).pushNamed(
                  '/parking-detail',
                  arguments: bestParking,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xem chi tiết',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  ParkingLot? _findBestParkingLot() {
    if (_nearbyParking.isEmpty) return null;
    
    // Find best parking based on availability, price, and distance
    final availableParking = _nearbyParking.where((p) => p.hasAvailableSlots).toList();
    
    if (availableParking.isEmpty) return _nearbyParking.first;
    
    // Sort by a combination of factors (you can adjust the scoring algorithm)
    availableParking.sort((a, b) {
      final scoreA = _calculateParkingScore(a);
      final scoreB = _calculateParkingScore(b);
      return scoreB.compareTo(scoreA); // Higher score is better
    });
    
    return availableParking.first;
  }

  double _calculateParkingScore(ParkingLot parking) {
    // Simple scoring algorithm - can be made more sophisticated
    double score = 0;
    
    // Available slots factor (more slots = better)
    score += (parking.availableSlots / parking.totalSlots) * 40;
    
    // Distance factor (closer = better, max distance considered is 5000m)
    final maxDistance = 5000;
    score += ((maxDistance - parking.distance.clamp(0, maxDistance)) / maxDistance) * 30;
    
    // Price factor (lower price = better, max price considered is 50000)
    final maxPrice = 50000;
    score += ((maxPrice - parking.pricePerHour.clamp(0, maxPrice)) / maxPrice) * 20;
    
    // Rating factor
    score += (parking.rating / 5.0) * 10;
    
    return score;
  }
}