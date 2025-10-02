import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/parking_lot_list_response_model.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/parking_hours_model.dart';
import '../../../core/services/parking_lot_service.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/services/distance_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/api_config.dart';
// Using PNG raster for car icon; if you add assets/images/car.png it will be used

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ParkingLotService _parkingLotService = ParkingLotService();
  final DirectionsService _directionsService = const DirectionsService();
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
  Circle? _userLocationCircle;
  static const bool _enableGoongOverlay = false;
  bool _customIconsLoaded = false; // pins loaded
  bool _carIconLoaded = false;
  // Search state
  Symbol? _searchedLocationSymbol;
  LatLng? _searchedLocation;
  bool _isSearchActive = false;
  // Route state
  Line? _routeLine;
  LatLng? _lastRouteTarget;
  String? _routeDurationText;
  String? _routeDistanceText;
  bool _directionsMode = false; // when true, search bar sets origin/destination
  LatLng? _directionsOrigin;
  LatLng? _directionsDestination;
  String? _directionsOriginName;
  String? _directionsDestinationName;
  // Session state
  bool _showLogoutButton = false;
  bool _hasUnreadNotifications = false;
  // Navigation mode state
  bool _isInNavigationMode = false;
  bool _isNavigating = false;
  LatLng? _navigationDestination;
  String? _navigationDestinationName;
  String? _remainingTime;
  String? _remainingDistance;
  Timer? _navigationTimer;
  bool _hasArrived = false;
  
  // Step-by-step navigation
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  String? _currentInstruction;
  bool _isFollowingCamera = false;
  StreamSubscription<Position>? _locationSubscription;
  
  // Real-time navigation tracking
  bool _isRealTimeTracking = false;
  Timer? _realTimeTrackingTimer;
  static const double _arrivalThresholdMeters = 50.0;
  Position? _lastRouteUpdatePosition;
  bool _preserveRouteLineOnUpdate = false;
  bool _hasTriggeredArrival = false; // Prevent multiple arrival notifications
  
  // Real-time route drawing
  List<LatLng> _traveledPath = [];
  Line? _traveledRouteLine;
  List<LatLng> _fullRoutePoints = [];
  bool _drawRouteRealTime = false;
  int _currentRoutePointIndex = 0;
  Timer? _routeProgressTimer;
  
  // Instruction preview mode
  bool _isPreviewMode = false;
  int _previewStepIndex = 0;
  
  // Route markers
  Symbol? _routeStartSymbol;
  Symbol? _routeEndSymbol;

  // Ho Chi Minh City center coordinates
  static const LatLng _hcmCenter = LatLng(10.8231, 106.6297);
  
  // Live location subscription
  StreamSubscription<Position>? _positionSub;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
    _checkUnreadNotifications();
    
    // Set up periodic refresh of notification status
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _checkUnreadNotifications();
      } else {
        timer.cancel();
      }
    });
    
    // Add listener to search controller to update UI and clear visuals when empty
    _searchController.addListener(() {
      final hasText = _searchController.text.trim().isNotEmpty;
      if (!hasText) {
        _clearSearchVisuals();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(() {});
    _searchController.dispose();
    _navigationTimer?.cancel();
    _positionSub?.cancel();
    _locationSubscription?.cancel();
    _realTimeTrackingTimer?.cancel();
    _routeProgressTimer?.cancel();
    _traveledPath.clear();
    _fullRoutePoints.clear();
    _currentRoutePointIndex = 0;
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

  void _startNavigationMode() {
    setState(() {
      _isInNavigationMode = true;
      _hasArrived = false;
    });
  }

  void _exitNavigationMode() async {
    setState(() {
      _isInNavigationMode = false;
      _isNavigating = false;
      _isPreviewMode = false;
      _remainingTime = null;
      _remainingDistance = null;
      _navigationDestination = null;
      _navigationDestinationName = null;
      _directionsOrigin = null;
      _directionsDestination = null;
      _directionsOriginName = null;
      _directionsDestinationName = null;
      _routeDurationText = null;
      _routeDistanceText = null;
      _currentInstruction = null;
      _navigationSteps.clear();
      _currentStepIndex = 0;
      _previewStepIndex = 0;
      _drawRouteRealTime = false;
      _hasTriggeredArrival = false; // Reset arrival flag when exiting navigation
    });
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _stopRealTimeTracking();
    _locationSubscription?.cancel();
    if (_routeLine != null && _mapController != null) {
      try { await _mapController!.removeLine(_routeLine!); } catch (_) {}
      _routeLine = null;
    }
    // Remove traveled route line
    if (_traveledRouteLine != null && _mapController != null) {
      try { await _mapController!.removeLine(_traveledRouteLine!); } catch (_) {}
      _traveledRouteLine = null;
    }
    // Clear traveled path and stop progressive drawing
    _traveledPath.clear();
    _fullRoutePoints.clear();
    _stopProgressiveRouteDrawing();
    // Remove route markers
    await _removeRouteMarkers();
  }

  void _startLiveNavigation() {
    if (_directionsDestination == null || _currentPosition == null) return;
    setState(() {
      _isNavigating = true;
    });
    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Update camera
      try {
        if (_currentPosition != null && _mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              18,
            ),
          );
        }
      } catch (_) {}

      // Update remaining time/distance
      final origins = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destinations = '${_directionsDestination!.latitude},${_directionsDestination!.longitude}';
      final dm = await DistanceMatrixService.getDurations(
        origins: origins,
        destinations: destinations,
        mode: 'motorcycle',
      );
      if (!mounted) return;
      if (dm != null && dm.rows.isNotEmpty && dm.rows.first.isNotEmpty) {
        final el = dm.rows.first.first;
        setState(() {
          _remainingTime = el.duration.text;
          _remainingDistance = el.distance.text;
          _routeDurationText = _remainingTime;
          _routeDistanceText = _remainingDistance;
        });
      }

      // Arrival check
      final double dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _directionsDestination!.latitude,
        _directionsDestination!.longitude,
      );
      if (dist <= 50 && !_hasArrived) {
        _hasArrived = true;
        _showArrivedDialog();
      }
    });
  }

  void _startStepByStepNavigation() {
    if (_navigationSteps.isEmpty) return;
    
    setState(() {
      _isNavigating = true;
      _isFollowingCamera = true;
      _currentStepIndex = 0;
      _currentInstruction = _navigationSteps[0]['instruction'];
      _drawRouteRealTime = true;
      _hasTriggeredArrival = false; // Reset arrival flag for new navigation
    });
    
    // Remove existing route line immediately to prepare for progressive drawing
    _removeExistingRouteForProgressiveDrawing();
    
    // Focus camera to current location immediately
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          18,
        ),
      );
    }
    
    // Start real-time tracking
    _startRealTimeTracking();
    
    // Initialize progressive route drawing with stored route points
    if (_fullRoutePoints.isNotEmpty) {
      debugPrint('[Navigation] Using stored route points for progressive drawing: ${_fullRoutePoints.length} points');
      _initializeRealTimeRouteDrawing();
    } else {
      debugPrint('[Navigation] No stored route points available - will wait for route API call');
    }
    
    // Start real-time route updates via Goong API (only when navigation instructions begin)
    _startRealTimeRouteUpdates();
    
    // Start location tracking for step-by-step navigation (legacy support)
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_isNavigating && mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        // Note: Arrival detection now handled by Goong API in _updateRouteFromCurrentPosition
        // _checkArrival(position); // Disabled - using Goong API route distance instead
        
        // Update camera to follow user
        if (_mapController != null && _isFollowingCamera) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              18,
            ),
          );
        }
        
        // Check if we need to move to next step
        _checkForNextStep(position);
      }
    });
  }

  void _checkForNextStep(Position currentPosition) {
    if (_currentStepIndex >= _navigationSteps.length - 1) return;
    
    final nextStep = _navigationSteps[_currentStepIndex + 1];
    final nextStepLocation = nextStep['start_location'] as LatLng?;
    
    if (nextStepLocation != null) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        nextStepLocation.latitude,
        nextStepLocation.longitude,
      );
      
      if (distance < 30) { // Within 30 meters of next step
        setState(() {
          _currentStepIndex++;
          _currentInstruction = _navigationSteps[_currentStepIndex]['instruction'];
        });
        debugPrint('Moved to step ${_currentStepIndex + 1}: $_currentInstruction');
      }
    }
  }

  void _startPreviewMode() {
    if (_navigationSteps.isEmpty) return;
    
    setState(() {
      _isPreviewMode = true;
      _previewStepIndex = 0;
    });
    
    // Focus camera on begin place first
    if (_directionsOrigin != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_directionsOrigin!, 12),
      );
    }
    
    _focusOnPreviewStep();
  }

  void _focusOnPreviewStep() {
    if (_previewStepIndex < _navigationSteps.length) {
      final step = _navigationSteps[_previewStepIndex];
      final stepLocation = step['start_location'] as LatLng?;
      
      if (stepLocation != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            stepLocation,
            18,
          ),
        );
      }
    }
  }

  void _navigatePreviewStep(int direction) {
    if (_navigationSteps.isEmpty) return;
    
    setState(() {
      _previewStepIndex = (_previewStepIndex + direction).clamp(0, _navigationSteps.length - 1);
    });
    
    _focusOnPreviewStep();
  }

  void _exitPreviewMode() {
    setState(() {
      _isPreviewMode = false;
      _previewStepIndex = 0;
    });
    
    // Zoom out to the begin place
    if (_directionsOrigin != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_directionsOrigin!, 12),
      );
    } else if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          12,
        ),
      );
    }
  }

  bool _isCurrentLocationAtStart() {
    if (_currentPosition == null || _directionsOrigin == null) return false;
    
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _directionsOrigin!.latitude,
      _directionsOrigin!.longitude,
    );
    
    return distance < 50; // Within 50 meters of start point
  }

  Future<void> _addRouteMarkers() async {
    if (_mapController == null) return;
    
    // Remove existing route markers
    await _removeRouteMarkers();
    
    // Small delay to ensure map is ready
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Add start marker (pin.png) - RED for origin
    if (_directionsOrigin != null) {
      // Check if origin is at current location or parking lot (priority)
      final isAtCurrentLocation = _currentPosition != null && 
        Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude,
          _directionsOrigin!.latitude, _directionsOrigin!.longitude,
        ) < 50;
      
      final isAtParkingLot = _nearbyParking.any((parking) => 
        Geolocator.distanceBetween(
          parking.latitude, parking.longitude,
          _directionsOrigin!.latitude, _directionsOrigin!.longitude,
        ) < 50);
      
      // Only add route marker if not at current location or parking lot
      if (!isAtCurrentLocation && !isAtParkingLot) {
        try {
          debugPrint('Loading pin.png for start marker...');
          final startData = await rootBundle.load('assets/images/pin.png');
          debugPrint('pin.png loaded successfully, size: ${startData.lengthInBytes} bytes');
          await _mapController!.addImage('route-start', startData.buffer.asUint8List(), false);
          debugPrint('route-start image added to map');
          _routeStartSymbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: _directionsOrigin!,
              iconImage: 'route-start',
              iconSize: 0.1,
            ),
          );
          debugPrint('Start marker symbol added successfully');
        } catch (e) {
          debugPrint('Failed to load start pin: $e');
          // Fallback to built-in marker
          debugPrint('Using fallback marker-15 for start');
          _routeStartSymbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: _directionsOrigin!,
              iconImage: 'marker-15',
              iconColor: '#FF0000',
              iconSize: 1.0,
            ),
          );
        }
      } else {
        debugPrint('Start location is at current location or parking lot - skipping route marker');
      }
    }
    
    // Add end marker (pin_blue.png) - BLUE for destination
    if (_directionsDestination != null) {
      // Check if destination is at current location or parking lot (priority)
      final isAtCurrentLocation = _currentPosition != null && 
        Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude,
          _directionsDestination!.latitude, _directionsDestination!.longitude,
        ) < 50;
      
      final isAtParkingLot = _nearbyParking.any((parking) => 
        Geolocator.distanceBetween(
          parking.latitude, parking.longitude,
          _directionsDestination!.latitude, _directionsDestination!.longitude,
        ) < 50);
      
      // Only add route marker if not at current location or parking lot
      if (!isAtCurrentLocation && !isAtParkingLot) {
        try {
          debugPrint('Loading pin_blue.png for end marker...');
          final endData = await rootBundle.load('assets/images/pin_blue.png');
          debugPrint('pin_blue.png loaded successfully, size: ${endData.lengthInBytes} bytes');
          await _mapController!.addImage('route-end', endData.buffer.asUint8List(), false);
          debugPrint('route-end image added to map');
          _routeEndSymbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: _directionsDestination!,
              iconImage: 'route-end',
              iconSize: 1.0,
            ),
          );
          debugPrint('End marker symbol added successfully');
        } catch (e) {
          debugPrint('Failed to load end pin: $e');
          // Fallback to built-in marker
          debugPrint('Using fallback marker-15 for end');
          _routeEndSymbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: _directionsDestination!,
              iconImage: 'marker-15',
              iconColor: '#0000FF',
              iconSize: 1.0,
            ),
          );
        }
      } else {
        debugPrint('End location is at current location or parking lot - skipping route marker');
      }
    }
  }

  Future<void> _removeRouteMarkers() async {
    if (_mapController == null) return;
    
    try {
      // Remove start marker
      if (_routeStartSymbol != null) {
        await _mapController!.removeSymbol(_routeStartSymbol!);
        _routeStartSymbol = null;
      }
      // Remove end marker
      if (_routeEndSymbol != null) {
        await _mapController!.removeSymbol(_routeEndSymbol!);
        _routeEndSymbol = null;
      }
    } catch (e) {
      debugPrint('Error removing route markers: $e');
    }
  }

  Future<void> _showArrivedDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đã đến nơi!'),
          content: Text('Bạn đã đến ${_navigationDestinationName ?? 'điểm đến'}.')
        );
      },
    );
    _exitNavigationMode();
  }

  void _swapOriginDestination() async {
    final oldOrigin = _directionsOrigin;
    final oldOriginName = _directionsOriginName;
    setState(() {
      _directionsOrigin = _directionsDestination;
      _directionsOriginName = _directionsDestinationName;
      _directionsDestination = oldOrigin;
      _directionsDestinationName = oldOriginName;
    });
    await _drawRouteBetween();
    // Update markers to reflect the swap
    await _addRouteMarkers();
  }

  Future<void> _toggleNavigationTo(LatLng destination, String? name) async {
    // If already navigating to same destination, exit navigation mode
    if (_isInNavigationMode && _directionsDestination != null) {
      final same = (destination.latitude - _directionsDestination!.latitude).abs() < 1e-6 &&
                   (destination.longitude - _directionsDestination!.longitude).abs() < 1e-6;
      if (same) {
        _exitNavigationMode();
        return;
      }
    }

    setState(() {
      _isInNavigationMode = true;
      _directionsMode = true;
      _navigationDestination = destination;
      _navigationDestinationName = name ?? 'Điểm đến';
      if (_currentPosition != null) {
        _directionsOrigin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        _directionsOriginName = 'Vị trí của tôi';
      } else {
        _directionsOrigin = null;
        _directionsOriginName = 'Chọn điểm bắt đầu';
      }
      _directionsDestination = destination;
      _directionsDestinationName = name ?? 'Điểm đến';
    });
    await _drawRouteBetween();
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
        // Do not override camera if a search result is being shown
        if (!_isSearchActive) {
        _updateMapLocation();
        }
        await _renderUserLocation();
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

  Future<void> _clearSearchVisuals() async {
    // Remove searched marker and route when search is cleared
    if (_mapController != null && _searchedLocationSymbol != null) {
      try {
        await _mapController!.removeSymbol(_searchedLocationSymbol!);
      } catch (_) {}
      _searchedLocationSymbol = null;
    }
    _searchedLocation = null;
    _isSearchActive = false;
    if (_mapController != null && _routeLine != null) {
      try {
        await _mapController!.removeLine(_routeLine!);
      } catch (_) {}
      _routeLine = null;
      _lastRouteTarget = null;
    }
  }

  bool _isSessionError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('401') || 
           errorLower.contains('403') || 
           errorLower.contains('unauthorized') ||
           errorLower.contains('phiên đăng nhập đã hết hạn') ||
           errorLower.contains('session') ||
           errorLower.contains('expired') ||
           errorLower.contains('token') ||
           errorLower.contains('hết hạn');
  }

  void _handleLogout() {
    // Clear session state
    setState(() {
      _showLogoutButton = false;
    });
    
    // Navigate to login screen or clear auth state
    // You can customize this based on your auth flow
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _ensurePositionStream() {
    _positionSub ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((pos) async {
      _currentPosition = pos;
      if (_isMapReady && _mapController != null) {
        try {
          if (_userLocationSymbol != null) {
            await _mapController!.updateSymbol(
              _userLocationSymbol!,
              SymbolOptions(
                geometry: LatLng(pos.latitude, pos.longitude),
                iconRotate: pos.heading,
              ),
            );
          } else {
            await _renderUserLocation();
          }
        } catch (_) {}
      }
    }, onError: (e) {
      debugPrint('Position stream error: $e');
    });
  }

  Future<void> _drawRouteTo(LatLng destination, [String? destinationName, bool updateFromCurrentLocation = false]) async {
    debugPrint('[Navigation] _drawRouteTo called - drawRouteRealTime: $_drawRouteRealTime, updateFromCurrentLocation: $updateFromCurrentLocation, isNavigating: $_isNavigating');
    
    if (_mapController == null) return;
    final origin = _directionsOrigin ?? (_currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null);
    if (origin == null) return;
    
    // Set navigation destination for arrival detection
    if (!updateFromCurrentLocation) {
      _navigationDestination = destination;
      _navigationDestinationName = destinationName;
    }
    try {
      final points = await _directionsService.getDrivingRoute(origin: origin, destination: destination);
      if (points.isEmpty) return;
      
      // Always store route points for potential progressive drawing
      if (!updateFromCurrentLocation) {
        _fullRoutePoints = List.from(points);
        debugPrint('[Navigation] Stored ${_fullRoutePoints.length} route points for future use');
      }
      
      // If in real-time drawing mode, handle progressive drawing
      if (_drawRouteRealTime && !updateFromCurrentLocation) {
        _currentRoutePointIndex = 0;
        debugPrint('[Navigation] Preparing for progressive drawing with ${_fullRoutePoints.length} points');
        
        // Remove any existing route lines
        if (_routeLine != null) {
          try { await _mapController!.removeLine(_routeLine!); } catch (_) {}
          _routeLine = null;
        }
        if (_traveledRouteLine != null) {
          try { await _mapController!.removeLine(_traveledRouteLine!); } catch (_) {}
          _traveledRouteLine = null;
        }
        
        // Initialize progressive route drawing now that we have the points
        _initializeRealTimeRouteDrawing();
        
        // Don't draw the full route initially - will be revealed progressively
        return;
      }
      
      // Only remove and redraw route line if this is not a real-time update during navigation
      // or if we don't have a route line yet
      if (_routeLine == null || !updateFromCurrentLocation || !_isNavigating) {
        // Remove previous route line
        if (_routeLine != null) {
          try { await _mapController!.removeLine(_routeLine!); } catch (_) {}
          _routeLine = null;
        }
        
        // Add new route line (only if not in real-time drawing mode)
        if (!_drawRouteRealTime) {
          _routeLine = await _mapController!.addLine(LineOptions(
            geometry: points,
            lineColor: '#1E88E5',
            lineWidth: 4.0,
          ));
          debugPrint('[Navigation] Route line drawn/updated');
        } else {
          debugPrint('[Navigation] Skipping blue route line - real-time drawing mode enabled');
        }
      } else {
        debugPrint('[Navigation] Skipping route line redraw to preserve visibility during navigation');
      }
      // Fetch time & distance using Goong Directions API
      final origins = '${origin.latitude},${origin.longitude}';
      final destinations = '${destination.latitude},${destination.longitude}';
      debugPrint('Fetching route info: origins=$origins, destinations=$destinations');
      debugPrint('API Key loaded: ${ApiConfig.isMapsApiKeyLoaded}');
      
      try {
        // Try to get duration and distance from Goong Directions API
        final directionsUrl = 'https://rsapi.goong.io/Direction';
        final directionsUri = Uri.parse(directionsUrl).replace(queryParameters: {
          'origin': origins,
          'destination': destinations,
          'vehicle': 'car',
          'api_key': ApiConfig.goongPlacesApiKey,
        });
        
        debugPrint('Directions API URL: $directionsUri');
        final directionsResp = await http.get(directionsUri);
        debugPrint('Directions API response status: ${directionsResp.statusCode}');
        debugPrint('Directions API response body: ${directionsResp.body}');
        
        if (directionsResp.statusCode == 200) {
          final directionsData = json.decode(directionsResp.body) as Map<String, dynamic>;
          final routes = directionsData['routes'] as List?;
          if (routes != null && routes.isNotEmpty) {
            final route = routes.first as Map<String, dynamic>;
            final legs = route['legs'] as List?;
            if (legs != null && legs.isNotEmpty) {
              final leg = legs.first as Map<String, dynamic>;
              final duration = leg['duration'] as Map<String, dynamic>?;
              final distance = leg['distance'] as Map<String, dynamic>?;
              
              if (duration != null && distance != null) {
                final durationText = duration['text'] as String? ?? 'N/A';
                final distanceText = distance['text'] as String? ?? 'N/A';
                
                debugPrint('Route info: duration=$durationText, distance=$distanceText');
                setState(() {
                  _routeDurationText = durationText;
                  _routeDistanceText = distanceText;
                  _directionsMode = true;
                  _remainingTime = durationText;
                  _remainingDistance = distanceText;
                });
                debugPrint('Set route duration: $_routeDurationText, distance: $_routeDistanceText');
                
                // Extract step-by-step instructions if available
                final steps = leg['steps'] as List?;
                if (steps != null && steps.isNotEmpty) {
                  debugPrint('Found ${steps.length} navigation steps from Goong Directions API');
                  _navigationSteps.clear();
                  for (int i = 0; i < steps.length; i++) {
                    final step = steps[i] as Map<String, dynamic>;
                    final instruction = step['html_instructions'] as String? ?? 
                                     step['maneuver'] as String? ?? 
                                     'Step ${i + 1}';
                    final stepDistance = step['distance'] as Map<String, dynamic>?;
                    final stepDuration = step['duration'] as Map<String, dynamic>?;
                    final startLocation = step['start_location'] as Map<String, dynamic>?;
                    
                    _navigationSteps.add({
                      'instruction': instruction,
                      'distance': stepDistance?['text'] ?? '',
                      'duration': stepDuration?['text'] ?? '',
                      'start_location': startLocation != null 
                        ? LatLng(startLocation['lat'] as double, startLocation['lng'] as double)
                        : null,
                    });
                    debugPrint('Step ${i + 1}: $instruction at ${startLocation?['lat']}, ${startLocation?['lng']}');
                  }
                  _currentStepIndex = 0;
                  _currentInstruction = _navigationSteps.isNotEmpty ? _navigationSteps[0]['instruction'] : null;
                } else {
                  debugPrint('No steps found in Goong Directions API response');
                  // Fallback: Create steps from route points
                  _createStepsFromRoutePoints(points);
                }
                return; // Success, exit early
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Directions API error: $e');
      }
      
      // Fallback: Try DistanceMatrix API
      try {
        final dm = await DistanceMatrixService.getDurations(
          origins: origins,
          destinations: destinations,
          mode: 'motorcycle',
        );
        
        debugPrint('Distance matrix result: $dm');
        
        if (dm != null && dm.rows.isNotEmpty && dm.rows.first.isNotEmpty) {
          final el = dm.rows.first.first;
          debugPrint('Distance element: status=${el.status}, duration=${el.duration.text}, distance=${el.distance.text}');
          setState(() {
            _routeDurationText = el.duration.text;
            _routeDistanceText = el.distance.text;
            _directionsMode = true;
            _remainingTime = el.duration.text;
            _remainingDistance = el.distance.text;
          });
          debugPrint('Set route duration: $_routeDurationText, distance: $_routeDistanceText');
          return; // Success, exit early
        }
      } catch (e) {
        debugPrint('DistanceMatrix API error: $e');
      }
      
      // Final fallback: Set default values
      debugPrint('All APIs failed - setting fallback values');
      setState(() {
        _routeDurationText = 'Đang tính toán...';
        _routeDistanceText = 'Đang tính toán...';
        _directionsMode = true;
        _remainingTime = 'Đang tính toán...';
        _remainingDistance = 'Đang tính toán...';
      });
      _lastRouteTarget = destination;
      
      // Add route markers
      await _addRouteMarkers();
      
      // Focus camera on both start and end spots
      if (origin != null && destination != null) {
        try {
          final bounds = LatLngBounds(
            southwest: LatLng(
              math.min(origin.latitude, destination.latitude) - 0.01,
              math.min(origin.longitude, destination.longitude) - 0.01,
            ),
            northeast: LatLng(
              math.max(origin.latitude, destination.latitude) + 0.01,
              math.max(origin.longitude, destination.longitude) + 0.01,
            ),
          );
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds),
          );
        } catch (_) {
          // Fallback to begin place if bounds fail
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(origin, 12),
          );
        }
      } else if (origin != null) {
        try {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(origin, 12),
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Failed to draw route: $e');
    }
  }

  Future<void> _drawRouteBetween() async {
    if (_directionsDestination == null) return;
    
    // If we have both origin and destination, focus camera on the road between them
    if (_directionsOrigin != null && _directionsDestination != null) {
      try {
        final bounds = LatLngBounds(
          southwest: LatLng(
            math.min(_directionsOrigin!.latitude, _directionsDestination!.latitude) - 0.01,
            math.min(_directionsOrigin!.longitude, _directionsDestination!.longitude) - 0.01,
          ),
          northeast: LatLng(
            math.max(_directionsOrigin!.latitude, _directionsDestination!.latitude) + 0.01,
            math.max(_directionsOrigin!.longitude, _directionsDestination!.longitude) + 0.01,
          ),
        );
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds),
        );
      } catch (_) {
        // Fallback to destination if bounds fail
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_directionsDestination!, 12),
        );
      }
    }
    
    await _drawRouteTo(_directionsDestination!, _directionsDestinationName);
  }

  void _createStepsFromRoutePoints(List<LatLng> points) {
    debugPrint('Creating steps from route points: ${points.length} points');
    _navigationSteps.clear();
    
    if (points.length < 2) return;
    
    // Create steps every 5 points to avoid too many steps
    final stepInterval = math.max(1, points.length ~/ 10);
    
    for (int i = 0; i < points.length; i += stepInterval) {
      final point = points[i];
      final stepNumber = (i ~/ stepInterval) + 1;
      
      _navigationSteps.add({
        'instruction': 'Step $stepNumber',
        'distance': '',
        'duration': '',
        'start_location': point,
      });
    }
    
    // Always add the last point as the final step
    if (points.isNotEmpty) {
      _navigationSteps.add({
        'instruction': 'Arrive at destination',
        'distance': '',
        'duration': '',
        'start_location': points.last,
      });
    }
    
    _currentStepIndex = 0;
    _currentInstruction = _navigationSteps.isNotEmpty ? _navigationSteps[0]['instruction'] : null;
    debugPrint('Created ${_navigationSteps.length} steps from route points');
  }

  Future<void> _toggleRouteTo(LatLng destination) async {
    // If a route exists to the same destination, remove it (toggle off)
    if (_routeLine != null && _lastRouteTarget != null) {
      final same = (destination.latitude - _lastRouteTarget!.latitude).abs() < 1e-6 &&
                   (destination.longitude - _lastRouteTarget!.longitude).abs() < 1e-6;
      if (same) {
        try {
          await _mapController!.removeLine(_routeLine!);
        } catch (_) {}
        _routeLine = null;
        _lastRouteTarget = null;
        return;
      }
    }
    await _drawRouteTo(destination, "Điểm đến");
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
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
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
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
        // Check if it's a session/token error
        if (_isSessionError(e.toString())) {
          _showLogoutButton = true;
        }
      });
      debugPrint('Error loading parking lots: $e');
    }
  }

  Future<void> _loadParkingLotsAtLocation(LatLng location) async {
    debugPrint('Home: loading parking lots at selected location lat=${location.latitude}, lng=${location.longitude}');

    setState(() {
      _isLoadingParkingLots = true;
      _error = null;
    });

    try {
      final response = await _parkingLotService.getNearbyParkingLots(
        latitude: location.latitude,
        longitude: location.longitude,
        radius: 5.0,
        page: 1,
        pageSize: 20,
      );

      setState(() {
        _nearbyParking = response.list;
        _isLoadingParkingLots = false;
      });

      debugPrint('Home: received ${response.list.length} lots for selected location');
      if (!mounted || !_isMapReady || _mapController == null) return;
      
      // Clear existing parking markers before adding new ones
      await _clearParkingMarkers();
      await _createMarkersFromParkingLots();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingParkingLots = false;
        // Check if it's a session/token error
        if (_isSessionError(e.toString())) {
          _showLogoutButton = true;
        }
      });
      debugPrint('Error loading parking lots at selected location: $e');
    }
  }

  Future<void> _addSearchedLocationMarker(LatLng location, String name) async {
    if (_mapController == null) return;
    
    try {
      // Remove previous searched symbol if any
      if (_searchedLocationSymbol != null) {
        await _mapController!.removeSymbol(_searchedLocationSymbol!);
        _searchedLocationSymbol = null;
      }

      // Add a distinctive marker for the searched location
      _searchedLocationSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: location,
          iconImage: _customIconsLoaded ? 'pin-blue' : 'marker-15',
          iconSize: _customIconsLoaded ? 1.2 : 1.6,
          iconColor: _customIconsLoaded ? null : '#1E88E5',
          
        ),
      );

      _searchedLocation = location;
      _isSearchActive = true;
      debugPrint('Added searched location marker: $name at ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('Error adding searched location marker: $e');
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
      // Do NOT remove searched location symbol here
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
        // First add subtle halo circle
        // Removed halo circle for cleaner look

        // Then add the green pin on top
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(parking.latitude, parking.longitude),
            iconImage: _customIconsLoaded ? 'pin-green' : 'marker-15',
            iconColor: _customIconsLoaded ? null : '#2E7D32', // Green tint only when default sprite
            iconSize: _customIconsLoaded ? 0.9 : 1.3,
          ),
        );

        _markers.add(symbol);
        _symbolIdToParking[symbol.id] = parking;
        debugPrint('Added marker for ${parking.name} at ${parking.latitude}, ${parking.longitude}');

      } catch (e) {
        debugPrint('Error adding symbol for ${parking.name}: $e');
        
        // Fallback 1: try with default marker only
        try {
          final symbol = await _mapController!.addSymbol(
            SymbolOptions(
              geometry: LatLng(parking.latitude, parking.longitude),
              iconImage: _customIconsLoaded ? 'pin-green' : 'marker-15',
              iconColor: _customIconsLoaded ? null : '#2E7D32',
              iconSize: _customIconsLoaded ? 1.0 : 1.6,
            ),
          );
          _markers.add(symbol);
          _symbolIdToParking[symbol.id] = parking;
          debugPrint('Added fallback marker for ${parking.name}');
        } catch (fallbackError) {
          debugPrint('Fallback marker also failed for ${parking.name}: $fallbackError');
          // No circle fallback; skip if symbol fails
        }
      }
    }
    debugPrint('Total markers added: ${_symbolIdToParking.length}');
    // When a search is active, keep the camera focused on the searched point
    if (!_isSearchActive) {
      await _fitCameraToAllPoints();
    }
  }

  Future<void> _renderUserLocation() async {
    if (!_isMapReady || _mapController == null || _currentPosition == null) {
      debugPrint('Cannot render user location: isMapReady=$_isMapReady, hasController=${_mapController != null}, hasPosition=${_currentPosition != null}');
      return;
    }
    
    final LatLng userLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    debugPrint('Rendering user car at: ${userLocation.latitude}, ${userLocation.longitude}');
    
    try {
      // Remove existing user location symbol if it exists
      if (_userLocationSymbol != null) {
        await _mapController!.removeSymbol(_userLocationSymbol!);
        _userLocationSymbol = null;
      }
      if (_userLocationCircle != null) {
        await _mapController!.removeCircle(_userLocationCircle!);
        _userLocationCircle = null;
      }

      // Check if current location is at start or end point
      bool isAtStart = _isCurrentLocationAtStart();
      bool isAtEnd = _directionsDestination != null && 
        Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _directionsDestination!.latitude,
          _directionsDestination!.longitude,
        ) < 50;
      
      // Add car symbol at current location, rotated by heading
      final double heading = (_currentPosition?.heading ?? 0.0).toDouble();
      _userLocationSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: userLocation,
          iconImage: _carIconLoaded ? 'car-icon' : 'marker-15',
          iconSize: _carIconLoaded ? (isAtStart || isAtEnd ? 1.2 : 1.0) : 1.2,
          iconRotate: heading,
        ),
      );
      _ensurePositionStream();
      debugPrint('User car added successfully');
      
    } catch (e) {
      debugPrint('Error rendering user location: $e');
      
      // Try alternative approach with different styling
      try {
        _userLocationSymbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: userLocation,
            iconImage: 'marker-15',
            iconColor: '#1E88E5',
            iconSize: 1.2,
          ),
        );
        debugPrint('User location added with fallback styling');
      } catch (fallbackError) {
        debugPrint('Fallback user location symbol also failed: $fallbackError');
      }
    }

    // Removed blue halo circle
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
                            if (_isSessionError(_error!)) {
                              _handleLogout();
                            } else {
                            if (_currentPosition != null) {
                              _loadNearbyParkingLots();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          child: Text(_isSessionError(_error!) ? 'Đăng xuất' : 'Thử lại'),
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
                        // Load custom teardrop icons if available in assets
                        // Load pin images
                        try {
                          final greenData = await rootBundle.load('assets/images/pin_green.png');
                          final blueData = await rootBundle.load('assets/images/pin_blue.png');
                          await _mapController!.addImage('pin-green', greenData.buffer.asUint8List(), false);
                          await _mapController!.addImage('pin-blue', blueData.buffer.asUint8List(), false);
                          _customIconsLoaded = true;
                          debugPrint('Pin icons loaded');
                        } catch (e) {
                          _customIconsLoaded = false;
                          debugPrint('Pin icons failed to load: $e');
                        }

                        // Load car icon separately (do not fail pins if car missing)
                        try {
                          final carPng = await rootBundle.load('assets/images/car.png');
                          await _mapController!.addImage('car-icon', carPng.buffer.asUint8List(), false);
                          _carIconLoaded = true;
                          debugPrint('Car icon loaded');
                        } catch (e) {
                          _carIconLoaded = false;
                          debugPrint('Car icon failed to load: $e');
                        }
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
                        await _renderUserLocation();
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

                // Vehicle Card Overlay - positioned under search panel in navigation mode, or in original position
                if (_selectedParking != null)
                  Positioned(
                    top: _isInNavigationMode ? 95 : 16, // Move down when in navigation mode to appear under search
                    left: 16,
                    right: 16,
                    child: _buildVehicleCard(parking: _selectedParking!),
                  ),

                

                // My Location Button (hidden during navigation and preview)
                if (!_isLoadingLocation && !_isNavigating && !_isPreviewMode)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('My location button tapped');
                        _isSearchActive = false;
                        if (_currentPosition != null && _mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              16,
                            ),
                          );
                        } else {
                          _getCurrentLocation();
                        }
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

                // Thunder Icon (hidden during navigation and preview)
                if (!_isNavigating && !_isPreviewMode)
                Positioned(
                  bottom: 80,
                  left: 16,
                    child: _buildThunderButton(),
                  ),

                // Directions button for searched place (hidden in navigation mode)
                if (_searchedLocation != null && _searchController.text.trim().isNotEmpty && !_isInNavigationMode)
                  Positioned(
                    bottom: 146,
                  right: 16,
                    child: FloatingActionButton(
                      heroTag: 'route_to_search',
                      onPressed: () async {
                        await _toggleNavigationTo(_searchedLocation!, _searchController.text.trim());
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.directions),
                    ),
                ),

                // Search Bar at Bottom (hidden in navigation mode)
                if (!_isInNavigationMode)
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

                // Top origin/destination panel in navigation mode (hidden during active navigation)
                if (_isInNavigationMode && !_isNavigating)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0,2),
                  ),
              ],
            ),
                      child: Row(
                        children: [
                          // Origin input
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final res = await Navigator.of(context).pushNamed('/search', arguments: {
                                  'currentLocation': _currentPosition != null ? {
                                    'lat': _currentPosition!.latitude,
                                    'lng': _currentPosition!.longitude,
                                  } : null,
                                });
                                if (res is Map<String, dynamic>) {
                                  final loc = res['selectedLocation'] as Map<String, double>?;
                                  final name = res['placeName'] as String?;
                                  if (loc != null) {
                                    setState(() {
                                      _directionsOrigin = LatLng(loc['lat']!, loc['lng']!);
                                      _directionsOriginName = name ?? 'Điểm bắt đầu';
                                    });
                                    await _drawRouteBetween();
                                    // Update markers to reflect the change
                                    await _addRouteMarkers();
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGrey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textSecondary)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _directionsOriginName ?? 'Vị trí của tôi',
                                        style: AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Swap button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: IconButton(
                              tooltip: 'Đổi chiều',
                              onPressed: _swapOriginDestination,
                              icon: const Icon(Icons.swap_vert, color: AppColors.textSecondary, size: 20),
                            ),
                          ),
                          // Destination input
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final res = await Navigator.of(context).pushNamed('/search', arguments: {
                                  'currentLocation': _currentPosition != null ? {
                                    'lat': _currentPosition!.latitude,
                                    'lng': _currentPosition!.longitude,
                                  } : null,
                                });
                                if (res is Map<String, dynamic>) {
                                  final loc = res['selectedLocation'] as Map<String, double>?;
                                  final name = res['placeName'] as String?;
                                  if (loc != null) {
                                    setState(() {
                                      _directionsDestination = LatLng(loc['lat']!, loc['lng']!);
                                      _directionsDestinationName = name ?? 'Điểm đến';
                                    });
                                    await _drawRouteBetween();
                                    // Update markers to reflect the change
                                    await _addRouteMarkers();
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGrey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.place, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _directionsDestinationName ?? 'Chọn điểm đến',
                                        style: AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Step-by-step navigation instruction overlay
                if (_isNavigating && _currentInstruction != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation, color: AppColors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bước ${_currentStepIndex + 1}/${_navigationSteps.length}',
                                  style: AppThemes.bodySmall.copyWith(
                                    color: AppColors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentInstruction!,
                                  style: AppThemes.bodyMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isNavigating = false;
                                _isFollowingCamera = false;
                                _currentInstruction = null;
                              });
                              _navigationTimer?.cancel();
                              _locationSubscription?.cancel();
                            },
                            icon: const Icon(Icons.close, color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Instruction preview overlay
                if (_isPreviewMode && _navigationSteps.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: AppColors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xem trước bước ${_previewStepIndex + 1}/${_navigationSteps.length}',
                                  style: AppThemes.bodySmall.copyWith(
                                    color: AppColors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _navigationSteps[_previewStepIndex]['instruction'],
                                  style: AppThemes.bodyMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Navigation arrows
                          Row(
                            children: [
                              IconButton(
                                onPressed: _previewStepIndex > 0 
                                  ? () => _navigatePreviewStep(-1)
                                  : null,
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: _previewStepIndex > 0 
                                    ? AppColors.white 
                                    : AppColors.white.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                onPressed: _previewStepIndex < _navigationSteps.length - 1
                                  ? () => _navigatePreviewStep(1)
                                  : null,
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: _previewStepIndex < _navigationSteps.length - 1
                                    ? AppColors.white 
                                    : AppColors.white.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _exitPreviewMode,
                            icon: const Icon(Icons.close, color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Turn icon button (purple curved arrow)
                if (_isInNavigationMode && !_isNavigating && !_isPreviewMode)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        if (_routeLine != null) {
                          // Toggle route off
                          _mapController!.removeLine(_routeLine!);
                          _routeLine = null;
                          _lastRouteTarget = null;
                          setState(() {
                            _routeDurationText = null;
                            _routeDistanceText = null;
                          });
                          
                          // Zoom camera out when removing route
                          if (_currentPosition != null && _mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                14, // Zoom out to 14
      ),
    );
  }
                        } else {
                          // Draw route
                          _drawRouteBetween();
                        }
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _routeLine != null ? AppColors.primary : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.turn_right,
                          color: _routeLine != null ? AppColors.white : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // Bottom navigation info card (route planning mode)
                if (_isInNavigationMode && _routeDurationText != null && _routeDistanceText != null && !_isNavigating && !_isPreviewMode)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0,2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_routeDurationText!} • ${_routeDistanceText!}',
                                  style: AppThemes.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Đóng',
                                onPressed: _exitNavigationMode,
                                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_isCurrentLocationAtStart()) {
                                      // Start actual navigation
                                      if (_navigationSteps.isNotEmpty) {
                                        _startStepByStepNavigation();
                                      } else {
                                        await _drawRouteBetween();
                                      }
                                    } else {
                                      // Start preview mode
                                      _startPreviewMode();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  child: Text(_isCurrentLocationAtStart() ? 'Bắt đầu' : 'Xem trước'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom stop button (during preview mode)
                if (_isPreviewMode)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0,2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _exitPreviewMode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Dừng',
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

                // Bottom stop button (during active navigation)
                if (_isNavigating)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0,2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _navigationTimer?.cancel();
                                _navigationTimer = null;
                                _locationSubscription?.cancel();
                                setState(() { 
                                  _isNavigating = false;
                                  _isFollowingCamera = false;
                                  _currentInstruction = null;
                                });
                                
                                // Zoom camera out when stopping navigation
                                if (_currentPosition != null && _mapController != null) {
                                  _mapController!.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      14, // Zoom out to 14 (was 18 during navigation)
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Dừng',
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
            // Menu Button with red dot indicator
            Stack(
              children: [
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
                // Red dot indicator for unread notifications
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 8,
                    top: 8,
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
              readOnly: true, // Make it read-only to prevent showing suggestions
              decoration: InputDecoration(
                hintText: AppStrings.searchLocation,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  onPressed: () async {
                    if (_searchController.text.isNotEmpty) {
                      _searchController.clear();
                      await _clearSearchVisuals();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    _searchController.text.isNotEmpty ? Icons.clear : Icons.search,
                    color: AppColors.textSecondary,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: AppThemes.bodyMedium,
              ),
              onTap: () async {
                // Pass current location to search screen if available
                final result = await Navigator.of(context).pushNamed('/search', arguments: {
                  'currentLocation': _currentPosition != null 
                    ? {'lat': _currentPosition!.latitude, 'lng': _currentPosition!.longitude}
                    : null,
                });
                
                // Handle result if user selected a location
                debugPrint('Search result received: $result');
                if (result != null && result is Map<String, dynamic>) {
                  final selectedLocation = result['selectedLocation'] as Map<String, double>?;
                  final placeName = result['placeName'] as String?;
                  debugPrint('Selected location: $selectedLocation');
                  debugPrint('Place name: $placeName');
                  debugPrint('Map controller available: ${_mapController != null}');
                  
                  // Update search field with selected location name
                  if (placeName != null) {
                    _searchController.text = placeName;
                  }
                  
                  if (selectedLocation != null && _mapController != null) {
                    debugPrint('Selected location data: $selectedLocation');
                    debugPrint('Latitude: ${selectedLocation['lat']} (type: ${selectedLocation['lat'].runtimeType})');
                    debugPrint('Longitude: ${selectedLocation['lng']} (type: ${selectedLocation['lng'].runtimeType})');
                    debugPrint('Current map position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
                    debugPrint('Updating map to: ${selectedLocation['lat']}, ${selectedLocation['lng']}');
                    
                    // Update map to show selected location
                    try {
                      final targetLatLng = LatLng(selectedLocation['lat']!, selectedLocation['lng']!);
                      debugPrint('Moving map to: ${targetLatLng.latitude}, ${targetLatLng.longitude}');
                      debugPrint('Map controller ready: ${_mapController != null}');
                      debugPrint('Map ready: $_isMapReady');
                      
                      // Wait a bit to ensure map is fully ready
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Force update the map position
                      await _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          targetLatLng,
                          12, // Reduced zoom level for better overview
                        ),
                      );
                      
                      debugPrint('Map camera updated successfully to searched location');
                      
                      // Add a marker at the searched location for visual confirmation
                      await _addSearchedLocationMarker(targetLatLng, placeName ?? 'Searched Location');
                      _isSearchActive = true;
                      _searchedLocation = targetLatLng;
                    } catch (e) {
                      debugPrint('Error updating map camera: $e');
                      // Fallback: just move to location without zoom
                      final targetLatLng = LatLng(selectedLocation['lat']!, selectedLocation['lng']!);
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLng(targetLatLng),
                      );
                      debugPrint('Map camera updated with fallback method');
                    }
                    
                    // Load parking lots for the selected location
                    await _loadParkingLotsAtLocation(
                      LatLng(selectedLocation['lat']!, selectedLocation['lng']!),
                    );
                  } else {
                    debugPrint('ERROR: Missing selectedLocation or mapController');
                  }
                } else {
                  debugPrint('ERROR: No result or invalid result format');
                }
              },
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigate (route) button
                InkWell(
                  onTap: () async {
                    final dest = LatLng(parking.latitude, parking.longitude);
                    await _toggleNavigationTo(dest, parking.name);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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

  void _startRealTimeTracking() {
    if (_isRealTimeTracking) return;
    
    debugPrint('[Navigation] Starting real-time tracking');
    _isRealTimeTracking = true;
    
    // Start location subscription for real-time updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 5 meters
      ),
    ).listen((Position position) {
      _onLocationUpdate(position);
    });
  }

  void _stopRealTimeTracking() {
    if (!_isRealTimeTracking) return;
    
    debugPrint('[Navigation] Stopping real-time tracking');
    _isRealTimeTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _realTimeTrackingTimer?.cancel();
    _realTimeTrackingTimer = null;
    _lastRouteUpdatePosition = null;
    _stopProgressiveRouteDrawing();
  }

  void _onLocationUpdate(Position position) {
    if (!_isNavigating || _navigationDestination == null) return;
    
    debugPrint('[Navigation] Location update: ${position.latitude}, ${position.longitude}');
    
    // Update current position
    _currentPosition = position;
    
    // Update user location marker on map
    _updateUserLocationMarker(position);
    
    // Update real-time route drawing
    _updateRealTimeRoute(position);
    
    // Follow camera if enabled
    if (_isFollowingCamera && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          18,
        ),
      );
    }
    
    // Note: Arrival detection now handled by Goong API route distance
    // _checkArrival(position); // Disabled - using Goong API route distance instead
    
    // Update route less frequently to preserve route line
    // Only update route every 50+ meters to avoid constantly redrawing
    _updateRouteFromCurrentLocation(position);
  }

  void _checkArrival(Position position) {
    debugPrint('[Navigation] Checking arrival - destination: $_navigationDestination, hasTriggered: $_hasTriggeredArrival');
    
    if (_navigationDestination == null) {
      debugPrint('[Navigation] No navigation destination set - skipping arrival check');
      return;
    }
    
    if (_hasTriggeredArrival) {
      debugPrint('[Navigation] Arrival already triggered - skipping check');
      return;
    }
    
    final distanceToDestination = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _navigationDestination!.latitude,
      _navigationDestination!.longitude,
    );
    
    debugPrint('[Navigation] Current position: ${position.latitude}, ${position.longitude}');
    debugPrint('[Navigation] Destination: ${_navigationDestination!.latitude}, ${_navigationDestination!.longitude}');
    debugPrint('[Navigation] Distance to destination: ${distanceToDestination.toStringAsFixed(1)}m (threshold: ${_arrivalThresholdMeters}m)');
    
    if (distanceToDestination <= _arrivalThresholdMeters) {
      debugPrint('[Navigation] *** ARRIVAL THRESHOLD REACHED! *** Triggering arrival notification.');
      _hasTriggeredArrival = true; // Prevent multiple notifications
      _onArrival();
    }
  }

  void _stopNavigation() {
    debugPrint('[Navigation] Stopping navigation');
    _exitNavigationMode();
  }

  void _onArrival() {
    debugPrint('[Navigation] *** ARRIVED AT DESTINATION! ***');
    
    // Stop navigation
    _stopNavigation();
    
    // Show arrival notification
    _showArrivalNotification();
  }

  // Manual arrival trigger for testing
  void _triggerManualArrival() {
    debugPrint('[Navigation] Manual arrival triggered for testing');
    if (_isNavigating && !_hasTriggeredArrival) {
      _hasTriggeredArrival = true;
      _onArrival();
    }
  }

  void _showArrivalNotification() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Đã đến nơi!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn đã đến ${_navigationDestinationName ?? "điểm đến"}. Chúc bạn có một ngày tốt lành!',
          style: AppThemes.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Zoom out to show overview
              if (_mapController != null && _currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    14,
                  ),
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
              'Hoàn thành',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRouteFromCurrentLocation(Position position) async {
    if (_navigationDestination == null || !_isNavigating) return;
    
    // Only update route every 50 meters or if significantly off course
    // to avoid constantly redrawing and losing the route line
    if (_lastRouteUpdatePosition != null) {
      final distanceFromLastUpdate = Geolocator.distanceBetween(
        _lastRouteUpdatePosition!.latitude,
        _lastRouteUpdatePosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      // Only update if moved more than 50 meters from last route update
      if (distanceFromLastUpdate < 50) {
        return;
      }
    }
    
    try {
      debugPrint('[Navigation] Updating route from current location');
      _lastRouteUpdatePosition = position;
      
      // Recalculate route from current position to destination
      await _drawRouteTo(
        _navigationDestination!,
        _navigationDestinationName ?? "Điểm đến",
        true,
      );
    } catch (e) {
      debugPrint('[Navigation] Error updating route: $e');
    }
  }

  void _updateUserLocationMarker(Position position) {
    if (_mapController == null || !_isMapReady) return;
    
    try {
      // Remove old user location marker
      if (_userLocationSymbol != null) {
        _mapController!.removeSymbol(_userLocationSymbol!);
      }
      
      // Add new user location marker
      _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(position.latitude, position.longitude),
        iconImage: _carIconLoaded ? 'car' : 'marker-15',
        iconSize: _carIconLoaded ? 0.8 : 1.0,
      )).then((symbol) {
        _userLocationSymbol = symbol;
      });
    } catch (e) {
      debugPrint('[Navigation] Error updating user location marker: $e');
    }
  }

  void _initializeRealTimeRouteDrawing() async {
    if (_routeProgressTimer != null) {
      debugPrint('[Navigation] Progressive route drawing already initialized');
      return;
    }
    
    debugPrint('[Navigation] Initializing progressive route drawing');
    _traveledPath.clear();
    _currentRoutePointIndex = 0;
    
    // Remove any existing route lines
    if (_routeLine != null && _mapController != null) {
      try { 
        await _mapController!.removeLine(_routeLine!); 
        _routeLine = null;
      } catch (_) {}
    }
    if (_traveledRouteLine != null && _mapController != null) {
      try { 
        await _mapController!.removeLine(_traveledRouteLine!); 
        _traveledRouteLine = null;
      } catch (_) {}
    }
    
    // Start progressive route drawing timer (every second)
    _startProgressiveRouteDrawing();
    
    debugPrint('[Navigation] Progressive route drawing initialized with ${_fullRoutePoints.length} route points');
  }

  void _updateRealTimeRoute(Position position) {
    if (!_drawRouteRealTime || _mapController == null || _fullRoutePoints.isEmpty) {
      return;
    }
    
    final currentLatLng = LatLng(position.latitude, position.longitude);
    
    // Find the closest point on the route to current position
    _updateRouteProgress(currentLatLng);
  }

  bool _shouldAddPointToPath(LatLng newPoint) {
    if (_traveledPath.isEmpty) {
      debugPrint('[Navigation] Should add point: traveled path is empty');
      return true;
    }
    
    final lastPoint = _traveledPath.last;
    final distance = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );
    
    debugPrint('[Navigation] Distance from last point: ${distance.toStringAsFixed(2)}m');
    
    // Add point if moved more than 5 meters from last point (reduced from 10m for testing)
    final shouldAdd = distance > 5.0;
    debugPrint('[Navigation] Should add point: $shouldAdd');
    return shouldAdd;
  }

  void _updateTraveledPath(LatLng currentPosition) {
    // Add current position to traveled path if it's significantly different from last point
    if (_traveledPath.isEmpty || _shouldAddPointToPath(currentPosition)) {
      _traveledPath.add(currentPosition);
      debugPrint('[Navigation] Added point to traveled path: ${_traveledPath.length} points');
      
      // Draw the updated traveled path
      _drawTraveledRoute();
    }
  }


  void _drawTraveledRoute() async {
    if (_mapController == null || _traveledPath.length < 2) return;
    
    try {
      // Remove previous traveled route line
      if (_traveledRouteLine != null) {
        await _mapController!.removeLine(_traveledRouteLine!);
        _traveledRouteLine = null;
      }
      
      // Draw the traveled path with a different color (blue for where you've been)
      _traveledRouteLine = await _mapController!.addLine(LineOptions(
        geometry: _traveledPath,
        lineColor: '#2196F3', // Blue for traveled path (where you've been)
        lineWidth: 6.0, // Thicker line for traveled path
      ));
      
      debugPrint('[Navigation] Drew traveled route with ${_traveledPath.length} points');
    } catch (e) {
      debugPrint('[Navigation] Error drawing traveled route: $e');
    }
  }

  void _drawRemainingRoute(List<LatLng> points) async {
    if (_mapController == null || points.length < 2) return;
    
    try {
      // Remove previous remaining route line
      if (_routeLine != null) {
        await _mapController!.removeLine(_routeLine!);
        _routeLine = null;
      }
      
      // Draw the remaining route (green for where you're going)
      _routeLine = await _mapController!.addLine(LineOptions(
        geometry: points,
        lineColor: '#00E676', // Green for remaining route (where you're going)
        lineWidth: 5.0, // Slightly thicker line
      ));
      
      debugPrint('[Navigation] Drew remaining route with ${points.length} points (green)');
    } catch (e) {
      debugPrint('[Navigation] Error drawing remaining route: $e');
    }
  }

  void _startProgressiveRouteDrawing() {
    if (_fullRoutePoints.isEmpty) {
      debugPrint('[Navigation] Cannot start progressive route drawing - no route points available');
      return;
    }
    
    debugPrint('[Navigation] Starting real-time route drawing with ${_fullRoutePoints.length} points');
    
    // Initially show the full planned route in green
    _drawRemainingRoute(_fullRoutePoints);
    debugPrint('[Navigation] Drew full planned route in green');
    
    debugPrint('[Navigation] Real-time route drawing initialized - waiting for navigation instructions to start API updates');
  }

  void _startRealTimeRouteUpdates() {
    // Only start API updates when step-by-step navigation begins
    _routeProgressTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isNavigating || !_drawRouteRealTime || _navigationDestination == null) {
        debugPrint('[Navigation] Stopping route update timer - navigation ended');
        timer.cancel();
        return;
      }
      
      debugPrint('[Navigation] Updating route from current position via Goong API');
      _updateRouteFromCurrentPosition();
    });
    
    debugPrint('[Navigation] Started real-time route updates - will call Goong API every 3 seconds');
  }

  void _updateRouteFromCurrentPosition() async {
    if (_currentPosition == null || _navigationDestination == null) return;
    
    final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    
    try {
      debugPrint('[Navigation] Fetching updated route from ${currentLatLng.latitude}, ${currentLatLng.longitude} to ${_navigationDestination!.latitude}, ${_navigationDestination!.longitude}');
      
      // Get route distance and duration from Goong API
      await _checkRouteDistanceFromGoongAPI(currentLatLng);
      
      // Get new route from current position to destination
      final newRoutePoints = await _directionsService.getDrivingRoute(
        origin: currentLatLng,
        destination: _navigationDestination!,
      );
      
      if (newRoutePoints.isNotEmpty) {
        // Update the green line with new route
        _drawRemainingRoute(newRoutePoints);
        debugPrint('[Navigation] Updated route with ${newRoutePoints.length} points from current position');
      } else {
        debugPrint('[Navigation] Failed to get updated route - keeping existing route');
      }
    } catch (e) {
      debugPrint('[Navigation] Error updating route from current position: $e');
    }
  }

  Future<void> _checkRouteDistanceFromGoongAPI(LatLng currentPosition) async {
    if (_navigationDestination == null || _hasTriggeredArrival) return;
    
    try {
      final origins = '${currentPosition.latitude},${currentPosition.longitude}';
      final destinations = '${_navigationDestination!.latitude},${_navigationDestination!.longitude}';
      
      final response = await http.get(
        Uri.parse('https://rsapi.goong.io/DistanceMatrix?origins=$origins&destinations=$destinations&vehicle=car&api_key=${ApiConfig.goongPlacesApiKey}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      debugPrint('[Navigation] Goong Distance API response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[Navigation] Goong Distance API data: $data');
        
        if (data['rows'] != null && data['rows'].isNotEmpty) {
          final elements = data['rows'][0]['elements'];
          if (elements != null && elements.isNotEmpty) {
            final element = elements[0];
            
            if (element['status'] == 'OK') {
              final distanceValue = element['distance']['value']; // Distance in meters
              final durationValue = element['duration']['value']; // Duration in seconds
              final distanceText = element['distance']['text'];
              final durationText = element['duration']['text'];
              
              debugPrint('[Navigation] Goong API - Route distance: ${distanceValue}m ($distanceText), Duration: ${durationValue}s ($durationText)');
              
              // Check if within 50 meters using route distance (not straight-line distance)
              if (distanceValue <= _arrivalThresholdMeters) {
                debugPrint('[Navigation] *** GOONG API ARRIVAL THRESHOLD REACHED! *** Route distance: ${distanceValue}m <= ${_arrivalThresholdMeters}m');
                _hasTriggeredArrival = true;
                _onArrival();
              }
            } else {
              debugPrint('[Navigation] Goong API element status: ${element['status']}');
            }
          }
        }
      } else {
        debugPrint('[Navigation] Goong Distance API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[Navigation] Error checking route distance from Goong API: $e');
    }
  }


  void _updateRouteProgress(LatLng currentPosition) {
    // Simply update the traveled path (blue line - where you've been)
    // The green line (remaining route) is now updated by the Goong API timer
    _updateTraveledPath(currentPosition);
    
    debugPrint('[Navigation] Updated traveled path with GPS position: ${currentPosition.latitude}, ${currentPosition.longitude}');
  }


  void _stopProgressiveRouteDrawing() {
    _routeProgressTimer?.cancel();
    _routeProgressTimer = null;
    _currentRoutePointIndex = 0;
    debugPrint('[Navigation] Stopped progressive route drawing');
  }

  void _removeExistingRouteForProgressiveDrawing() async {
    debugPrint('[Navigation] Removing existing route for progressive drawing');
    
    // Remove existing blue route line
    if (_routeLine != null && _mapController != null) {
      try {
        await _mapController!.removeLine(_routeLine!);
        _routeLine = null;
        debugPrint('[Navigation] Removed existing blue route line');
      } catch (e) {
        debugPrint('[Navigation] Error removing existing route line: $e');
      }
    }
    
    // Remove any existing traveled route line
    if (_traveledRouteLine != null && _mapController != null) {
      try {
        await _mapController!.removeLine(_traveledRouteLine!);
        _traveledRouteLine = null;
        debugPrint('[Navigation] Removed existing traveled route line');
      } catch (e) {
        debugPrint('[Navigation] Error removing existing traveled route line: $e');
      }
    }
  }
}