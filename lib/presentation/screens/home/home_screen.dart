import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_lot_list_response_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/parking_hours_model.dart';
import '../../../core/services/parking_lot_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ParkingLotService _parkingLotService = ParkingLotService();
  bool _isAnalyzing = false;
  MapboxMapController? _mapController;
  Position? _currentPosition;
  bool _isLocationPermissionGranted = false;
  List<Symbol> _markers = [];
  List<Circle> _circles = [];
  final Map<String, ParkingLot> _symbolIdToParking = {};
  final Map<String, ParkingLot> _circleIdToParking = {};
  bool _isMapReady = false;
  bool _isLoadingLocation = true;
  bool _isLoadingParkingLots = false;
  List<ParkingLot> _nearbyParking = [];
  String? _error;
  bool _goongTilesAdded = false;
  Symbol? _userLocationSymbol;
  static const bool _enableGoongOverlay = false;

  // Ho Chi Minh City center coordinates
  static const LatLng _hcmCenter = LatLng(10.8231, 106.6297);
  
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
    _isMapReady = false;
    _symbolIdToParking.clear();
    _mapController = null;
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      await _requestLocationPermission();
      if (_isLocationPermissionGranted) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Init location error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      debugPrint('Current position: ${position.latitude}, ${position.longitude}');

      if (_isMapReady && _mapController != null) {
        _updateMapLocation();
        await _renderUserLocationSymbol();
        await _loadNearbyParkingLots();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
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

  Future<void> _loadNearbyParkingLots() async {
    final double targetLat = _currentPosition?.latitude ?? _hcmCenter.latitude;
    final double targetLng = _currentPosition?.longitude ?? _hcmCenter.longitude;

    debugPrint('Home: requesting lots at lat=$targetLat, lng=$targetLng');

    setState(() {
      _isLoadingParkingLots = true;
      _error = null;
    });

    try {
      final response = await _parkingLotService.getNearbyParkingLots(
        latitude: targetLat,
        longitude: targetLng,
        radius: 5.0,
        page: 1,
        pageSize: 20,
      );

      setState(() {
        _nearbyParking = response.list;
        _isLoadingParkingLots = false;
      });

      debugPrint('Home: received ${response.list.length} lots');
      if (!mounted || !_isMapReady || _mapController == null) return;
      
      // Clear existing parking markers before adding new ones
      await _clearParkingMarkers();
      await _createMarkersFromParkingLots();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingParkingLots = false;
      });
      debugPrint('Error loading parking lots: $e');
    }
  }

  Future<void> _clearParkingMarkers() async {
    if (_mapController == null) return;
    
    try {
      // Clear existing parking markers (not user location)
      for (final symbolId in _symbolIdToParking.keys) {
        final symbol = _markers.firstWhere((s) => s.id == symbolId, orElse: () => Symbol('', SymbolOptions()));
        if (symbol.id.isNotEmpty) {
          await _mapController!.removeSymbol(symbol);
        }
      }
      // Clear circles
      for (final circle in _circles) {
        await _mapController!.removeCircle(circle);
      }
      _symbolIdToParking.clear();
      _circleIdToParking.clear();
      _markers.clear();
      _circles.clear();
    } catch (e) {
      debugPrint('Error clearing markers: $e');
    }
  }

  Future<void> _createMarkersFromParkingLots() async {
    if (!_isMapReady || _mapController == null) return;

    debugPrint('Creating markers for ${_nearbyParking.length} parking lots');
    
    // Wait a bit to ensure map is fully ready
    await Future.delayed(const Duration(milliseconds: 300));
    
    for (int i = 0; i < _nearbyParking.length; i++) {
      final parking = _nearbyParking[i];
      
      try {
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(parking.latitude, parking.longitude),
            // Render a pink "P" label at the location
            textField: 'P',
            textSize: 16.0,
            textColor: '#FF2D87',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2.0,
            textOffset: const Offset(0, 0),
            textAnchor: 'center',
          ),
        );
        
        _markers.add(symbol);
        _symbolIdToParking[symbol.id] = parking;
        debugPrint('Added marker for ${parking.name} at ${parking.latitude}, ${parking.longitude}');
        // Add a visible circle so the location is always shown even if sprite icons are missing
        try {
          final circle = await _mapController!.addCircle(
            CircleOptions(
              geometry: LatLng(parking.latitude, parking.longitude),
              circleRadius: 8.0,
              circleColor: '#FFE0EC',
              circleStrokeColor: '#FF2D87',
              circleStrokeWidth: 1.0,
            ),
          );
          _circles.add(circle);
          _circleIdToParking[circle.id] = parking;
        } catch (circleAddError) {
          debugPrint('Non-fatal: could not add circle for ${parking.name}: $circleAddError');
        }
        
      } catch (e) {
        debugPrint('Error adding symbol for ${parking.name}: $e');
        
        // Fallback 1: try with default marker only
        try {
          final symbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: LatLng(parking.latitude, parking.longitude),
              textField: 'P',
              textSize: 16.0,
              textColor: '#FF2D87',
              textHaloColor: '#FFFFFF',
              textHaloWidth: 2.0,
              textOffset: const Offset(0, 0),
              textAnchor: 'center',
            ),
          );
          _markers.add(symbol);
          _symbolIdToParking[symbol.id] = parking;
          debugPrint('Added fallback marker for ${parking.name}');
        } catch (fallbackError) {
          debugPrint('Fallback marker also failed for ${parking.name}: $fallbackError');
          // Fallback 2: draw a circle so something is visible
          try {
            final circle = await _mapController!.addCircle(
              CircleOptions(
                geometry: LatLng(parking.latitude, parking.longitude),
                circleRadius: 8.0,
                circleColor: '#FFE0EC',
                circleStrokeColor: '#FF2D87',
                circleStrokeWidth: 1.0,
              ),
            );
            _circles.add(circle);
            _circleIdToParking[circle.id] = parking;
            debugPrint('Added circle marker for ${parking.name}');
          } catch (circleError) {
            debugPrint('Circle marker also failed for ${parking.name}: $circleError');
          }
        }
      }
    }
    debugPrint('Total markers added: ${_symbolIdToParking.length}');
    await _fitCameraToAllPoints();
  }

  Future<void> _renderUserLocationSymbol() async {
    if (!_isMapReady || _mapController == null || _currentPosition == null) {
      debugPrint('Cannot render user location: isMapReady=$_isMapReady, hasController=${_mapController != null}, hasPosition=${_currentPosition != null}');
      return;
    }
    
    final LatLng userLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    debugPrint('Rendering user location symbol at: ${userLocation.latitude}, ${userLocation.longitude}');
    
    try {
      // Remove existing user location symbol if it exists
      if (_userLocationSymbol != null) {
        await _mapController!.removeSymbol(_userLocationSymbol!);
        _userLocationSymbol = null;
      }

      // Add new user location symbol
      _userLocationSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: userLocation,
          iconImage: 'marker-15',
          iconColor: '#1E88E5',
          iconSize: 1.5,
        ),
      );
      
      debugPrint('User location symbol added successfully');
      
    } catch (e) {
      debugPrint('Error rendering user location symbol: $e');
      
      // Try alternative approach with different styling
      try {
        _userLocationSymbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: userLocation,
            iconImage: 'marker-blue-15',
            iconSize: 1.5,
          ),
        );
        debugPrint('User location symbol added with fallback styling');
      } catch (fallbackError) {
        debugPrint('Fallback user location symbol also failed: $fallbackError');
      }
    }
  }

  Future<void> _fitCameraToAllPoints() async {
    if (_mapController == null) return;
    final List<LatLng> points = [];
    for (final symbol in _markers) {
      if (symbol.options.geometry != null) {
        points.add(symbol.options.geometry!);
      }
    }
    if (_userLocationSymbol?.options.geometry != null) {
      points.add(_userLocationSymbol!.options.geometry!);
    }
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds,
            top: 80, right: 80, bottom: 80, left: 80),
      );
    } catch (e) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds),
        );
      } catch (_) {}
    }
  }

  ParkingLot? _selectedParking;

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service not enabled');
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
        debugPrint('Location permission denied forever');
        setState(() {
          _isLocationPermissionGranted = false;
        });
        return;
      }

      final isGranted = permission == LocationPermission.whileInUse || 
                                     permission == LocationPermission.always;
      
      debugPrint('Location permission granted: $isGranted');
      setState(() {
        _isLocationPermissionGranted = isGranted;
      });
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      setState(() {
        _isLocationPermissionGranted = false;
      });
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
                // Loading indicator for map readiness only
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
                // Error indicator
                else if (_error != null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi tải dữ liệu',
                          style: AppThemes.headingMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: AppThemes.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPosition != null) {
                              _loadNearbyParkingLots();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else
                  // Mapbox GL Map
                  MapboxMap(
                    accessToken: ApiConfig.mapboxAccessToken,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null 
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : _hcmCenter,
                      zoom: 14,
                    ),
                    onMapCreated: (MapboxMapController controller) async {
                      debugPrint('Map created, initializing controller...');
                      _mapController = controller;
                      
                      // Handle marker taps
                      _mapController!.onSymbolTapped.add((Symbol symbol) {
                        debugPrint('Symbol tapped: ${symbol.id}');
                        final parking = _symbolIdToParking[symbol.id];
                        if (parking != null) {
                          _selectParking(parking);
                        }
                      });
                      // Handle circle taps
                      _mapController!.onCircleTapped.add((Circle circle) {
                        debugPrint('Circle tapped: ${circle.id}');
                        final parking = _circleIdToParking[circle.id];
                        if (parking != null) {
                          _selectParking(parking);
                        }
                      });
                    },
                    onStyleLoadedCallback: () async {
                      debugPrint('Map style loaded');
                      
                      try {
                        // Add custom tile source if needed
                        if (_enableGoongOverlay && !_goongTilesAdded && _mapController != null) {
                          final tilesUrl = 'https://tile.goong.io/maps/{z}/{x}/{y}.png?api_key=${ApiConfig.goongMapsApiKey}';
                          await _mapController!.addSource(
                            'goong-tiles',
                            RasterSourceProperties(
                              tiles: [tilesUrl],
                              tileSize: 256,
                            ),
                          );
                          await _mapController!.addLayer(
                            'goong-tiles',
                            'goong-layer',
                            const RasterLayerProperties(),
                            belowLayerId: 'settlement-label',
                          );
                          _goongTilesAdded = true;
                          debugPrint('Goong tiles added successfully');
                        }
                      } catch (e) {
                        debugPrint('Error adding Goong raster layer: $e');
                      }
                      
                      setState(() {
                        _isMapReady = true;
                      });
                      
                      debugPrint('Map ready, current position: $_currentPosition');
                      
                      // Add markers when map is ready
                      if (_currentPosition != null && mounted) {
                        await _renderUserLocationSymbol();
                        await _loadNearbyParkingLots();
                      } else {
                        // Load parking lots for HCM center if no current position
                        await _loadNearbyParkingLots();
                      }
                    },
                    onMapClick: (point, coordinates) {
                      if (_selectedParking != null) {
                        setState(() {
                          _selectedParking = null;
                        });
                      }
                    },
                    styleString: 'mapbox://styles/mapbox/streets-v12',
                    myLocationEnabled: false,
                    myLocationTrackingMode: MyLocationTrackingMode.None,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    tiltGesturesEnabled: true,
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
                    bottom: 80,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('My location button tapped');
                        _getCurrentLocation();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // Thunder Icon
                Positioned(
                  bottom: 80,
                  left: 16,
                  child: _buildThunderButton(),
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

                // Loading overlay for parking lots
                if (!_isLoadingLocation && _isLoadingParkingLots)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 8),
                        Text('Đang tải bãi đậu xe...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... rest of your widget methods remain the same ...

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
                backgroundImage: (user?.avatarUrl != null && (user!.avatarUrl!.trim().isNotEmpty) && (user.avatarUrl!.startsWith('http')))
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: (user?.avatarUrl == null || user!.avatarUrl!.trim().isEmpty)
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

    if (_selectedParking != null && _mapController != null) {
      _mapController!.animateCamera(
    CameraUpdate.newLatLngZoom(  // ✅ Correct API
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
          AppRoutes.parkingDetail,
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

  Widget _buildThunderButton() {
    return GestureDetector(
          onTap: () {
            _triggerAIAnalysis();
          },
      child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
          color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
        child: const Icon(
          Icons.flash_on, // Thunder/lightning icon
              color: AppColors.white,
              size: 24,
            ),
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
                  AppRoutes.parkingDetail,
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