import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_themes.dart';
import '../../../data/models/parking_lot_model.dart';
import '../../../data/models/place_model.dart';
import '../../../core/services/goong_places_service.dart';
import '../../../core/services/parking_lot_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  final ParkingLotService _parkingLotService = ParkingLotService();
  
  // Store current location passed from home screen
  Map<String, double>? _currentLocation;
  
  List<String> _recentSearches = [];
  
  List<PlacePrediction> _placePredictions = [];
  List<PlaceModel> _searchResults = [];
  List<ParkingLot> _nearbyLots = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  String _sessionToken = GoongPlacesService.generateSessionToken();


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    
    // Get current location from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['currentLocation'] != null) {
        _currentLocation = args['currentLocation'] as Map<String, double>;
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    
    // Clear all search state
    _placePredictions.clear();
    _searchResults.clear();
    _showSuggestions = false;
    _isSearching = false;
    
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placePredictions.clear();
        _searchResults.clear();
        _isSearching = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    try {
      // Use current location to bias search results if available
      String? locationParam;
      if (_currentLocation != null) {
        locationParam = '${_currentLocation!['lat']},${_currentLocation!['lng']}';
        debugPrint('Using current location biasing for autocomplete: $locationParam');
      } else {
        // Fallback to Ho Chi Minh City center for better Vietnamese results
        locationParam = '10.8231,106.6297';
        debugPrint('Using HCM City center for autocomplete biasing: $locationParam');
      }
      
      final predictions = await GoongPlacesService.getPlaceAutocomplete(
        query,
        location: locationParam,
        radius: 50000, // 50km radius for better local results
        language: 'vi',
      );

      setState(() {
        _placePredictions = predictions;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error performing search: $e');
    }
  }

  Future<void> _onPlaceSelected(PlacePrediction prediction) async {
    setState(() {
      _searchController.text = prediction.description;
      _showSuggestions = false;
      _isSearching = true;
    });

    try {
      final placeDetails = await GoongPlacesService.getPlaceDetails(
        prediction.placeId,
        language: 'vi',
      );

      if (placeDetails != null) {
        debugPrint('Place details received: ${placeDetails.name}');
        debugPrint('Place coordinates: ${placeDetails.latitude}, ${placeDetails.longitude}');
        
        // Update place result
        setState(() {
          _searchResults = [placeDetails];
        });

        // Fetch nearby parking lots using selected place lat/lng
        final double? lat = placeDetails.latitude;
        final double? lng = placeDetails.longitude;
        if (lat == null || lng == null) {
          if (!mounted) return;
          setState(() { _isSearching = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không lấy được toạ độ cho điểm đã chọn')),
          );
          return;
        }
        try {
          final nearby = await _parkingLotService.getNearbyParkingLots(
            latitude: lat,
            longitude: lng,
            radius: 5.0,
            page: 1,
            pageSize: 20,
          );
          if (!mounted) return;
          setState(() {
            _nearbyLots = nearby.list;
            _isSearching = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _nearbyLots = [];
            _isSearching = false;
          });
          debugPrint('Error loading nearby parking lots: $e');
        }

        // Add to recent searches
        if (!_recentSearches.contains(prediction.description)) {
          setState(() {
            _recentSearches.insert(0, prediction.description);
            if (_recentSearches.length > 10) {
              _recentSearches = _recentSearches.take(10).toList();
            }
          });
        }
        
        // Return selected location to home screen
        _returnLocationToHome(placeDetails);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error getting place details: $e');
    }
  }

  void _returnLocationToHome(PlaceModel placeDetails) {
    debugPrint('Returning location to home: ${placeDetails.name}');
    debugPrint('Latitude: ${placeDetails.latitude}, Longitude: ${placeDetails.longitude}');
    
    // Clear search state before navigating back
    _placePredictions.clear();
    _searchResults.clear();
    _showSuggestions = false;
    _isSearching = false;
    
    if (placeDetails.latitude != null && placeDetails.longitude != null) {
      // Validate coordinates are reasonable (within Vietnam bounds approximately)
      final lat = placeDetails.latitude!;
      final lng = placeDetails.longitude!;
      
      // More inclusive bounds for global coordinates
      if (lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0) {
        debugPrint('Valid coordinates - Navigating back with: $lat, $lng');
        debugPrint('Place name: ${placeDetails.name}');
        debugPrint('Address: ${placeDetails.formattedAddress}');
        Navigator.of(context).pop({
          'selectedLocation': {
            'lat': lat,
            'lng': lng,
          },
          'placeName': placeDetails.name,
          'address': placeDetails.formattedAddress,
        });
      } else {
        debugPrint('ERROR: Invalid coordinates: lat=$lat, lng=$lng');
        debugPrint('Coordinates must be: lat between -90 and 90, lng between -180 and 180');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tọa độ không hợp lệ cho địa điểm này')),
        );
      }
    } else {
      debugPrint('ERROR: Place details missing coordinates!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lấy tọa độ cho địa điểm này')),
      );
    }
  }

  void _navigateToParkingDetail(ParkingLot parking) {
    Navigator.of(context).pushNamed(
      '/parking-detail',
      arguments: parking,
    );
  }

  void _useCurrentLocation() {
    if (_currentLocation != null) {
      // Clear search state before navigating back
      _placePredictions.clear();
      _searchResults.clear();
      _showSuggestions = false;
      _isSearching = false;
      
      Navigator.of(context).pop({
        'selectedLocation': _currentLocation,
        'placeName': 'Vị trí hiện tại',
        'address': 'Sử dụng vị trí hiện tại',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lấy vị trí hiện tại')),
      );
    }
  }

  Future<void> _performTextSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    try {
      // Use current location to bias search results if available
      String? locationParam;
      if (_currentLocation != null) {
        locationParam = '${_currentLocation!['lat']},${_currentLocation!['lng']}';
        debugPrint('Using current location biasing for text search: $locationParam');
      } else {
        // Fallback to Ho Chi Minh City center for better Vietnamese results
        locationParam = '10.8231,106.6297';
        debugPrint('Using HCM City center for text search biasing: $locationParam');
      }
      
      final results = await GoongPlacesService.searchPlaces(
        query,
        location: locationParam,
        radius: 50000, // 50km radius for better local results
        language: 'vi',
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error performing text search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            // Clear search state before navigating back
            _placePredictions.clear();
            _searchResults.clear();
            _showSuggestions = false;
            _isSearching = false;
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkGrey),
        ),
        title: Text(
          'Tìm kiếm',
          style: AppThemes.headingMedium.copyWith(
            color: AppColors.darkGrey,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.mic, color: AppColors.darkGrey),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
                  focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Tìm điểm đến của bạn',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _placePredictions.clear();
                                    _searchResults.clear();
                                    _showSuggestions = false;
                                  });
                                },
                                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              )
                            : null,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _performTextSearch(value);
                    }
              },
            ),
          ),

          Expanded(
                child: _searchResults.isNotEmpty
                    ? _buildSearchResults()
                    : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                            // Current Location Option
                            if (_currentLocation != null) ...[
                              _buildCurrentLocationItem(),
                              const SizedBox(height: 16),
                            ],
                            
                  // Recent Searches
                  if (_recentSearches.isNotEmpty) ...[
                    _buildSectionHeader('Tìm kiếm gần đây'),
                    ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
                    const SizedBox(height: 24),
                  ],

                            // Nearby Parking (from selected place)
                            if (_nearbyLots.isNotEmpty) ...[
                              _buildSectionHeader('BÃI GẦN ĐIỂM ĐẾN'),
                              ..._nearbyLots.map((p) => _buildParkingItem(p)),
                              const SizedBox(height: 24),
                            ],
                  
                  const SizedBox(height: 24),
                  
                  // Suggestions Section  
                            _buildSectionHeader('GỢI Ý'),
                  _buildCategoryGrid(),
                ],
              ),
            ),
          ),
            ],
          ),
          
          // Search Suggestions Overlay
          if (_showSuggestions && _placePredictions.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _placePredictions[index];
                    return _buildSuggestionItem(prediction);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Kết quả tìm kiếm'),
          ..._searchResults.map((place) => _buildPlaceItem(place)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(PlacePrediction prediction) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(
        Icons.location_on,
        color: AppColors.primary,
        size: 20,
      ),
      title: Text(
        prediction.mainText,
        style: AppThemes.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: prediction.secondaryText.isNotEmpty
          ? Text(
              prediction.secondaryText,
              style: AppThemes.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      onTap: () => _onPlaceSelected(prediction),
    );
  }

  Widget _buildPlaceItem(PlaceModel place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.place,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppThemes.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      place.formattedAddress,
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (place.rating != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        place.rating!.toStringAsFixed(1),
                        style: AppThemes.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (place.types.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: place.types.take(3).map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeDisplayName(type),
                    style: AppThemes.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'restaurant':
        return 'Nhà hàng';
      case 'hospital':
        return 'Bệnh viện';
      case 'school':
        return 'Trường học';
      case 'shopping_mall':
        return 'Trung tâm thương mại';
      case 'gas_station':
        return 'Trạm xăng';
      case 'bank':
        return 'Ngân hàng';
      case 'pharmacy':
        return 'Nhà thuốc';
      case 'gym':
        return 'Phòng gym';
      case 'park':
        return 'Công viên';
      case 'tourist_attraction':
        return 'Điểm du lịch';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppThemes.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCurrentLocationItem() {
    return GestureDetector(
      onTap: _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sử dụng vị trí hiện tại',
                    style: AppThemes.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tìm bãi đậu xe gần bạn',
                    style: AppThemes.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.history,
        color: AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        search,
        style: AppThemes.bodyMedium,
      ),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            _recentSearches.remove(search);
          });
        },
        icon: const Icon(
          Icons.close,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
      onTap: () {
        _searchController.text = search;
        _performTextSearch(search);
      },
    );
  }

  Widget _buildParkingItem(ParkingLot parking) {
    return GestureDetector(
      onTap: () => _navigateToParkingDetail(parking),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_parking,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parking.name,
                  style: AppThemes.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  parking.address,
                  style: AppThemes.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      parking.distanceText,
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${parking.availableSlots} chỗ trống',
                      style: AppThemes.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            parking.priceText,
            style: AppThemes.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.restaurant, 'name': 'Nhà hàng', 'color': AppColors.error},
      {'icon': Icons.local_hospital, 'name': 'Bệnh viện', 'color': AppColors.info},
      {'icon': Icons.school, 'name': 'Trường học', 'color': AppColors.warning},
      {'icon': Icons.shopping_cart, 'name': 'Mua sắm', 'color': AppColors.success},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: category['color'] as Color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['name'] as String,
                  style: AppThemes.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}