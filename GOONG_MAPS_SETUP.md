# Goong Maps Setup Guide

This guide will help you set up Goong Maps in your Flutter project to replace Google Maps.

## 1. Get Goong Maps API Keys

1. Visit [Goong.io](https://account.goong.io/) and create an account
2. Create a new project
3. Get your API keys:
   - **MAPS_API_KEY**: For map tiles and rendering
   - **PLACE_API_KEY**: For Places API (autocomplete, search, place details)

## 2. Update Environment Variables

Add your API keys to your `.env` file:

```env
# Goong Maps API Keys
MAPS_API_KEY=your_goong_maps_api_key_here
PLACE_API_KEY=your_goong_places_api_key_here
```

## 3. Android Configuration

The AndroidManifest.xml has been updated to use Goong Maps:

```xml
<!-- Goong Maps API Key -->
<meta-data 
    android:name="com.mapbox.token"
    android:value="${MAPS_API_KEY}"/>
```

## 4. Flutter Dependencies

The following dependencies have been updated in `pubspec.yaml`:

```yaml
dependencies:
  # Maps & Location
  mapbox_gl: ^0.15.0  # Uses Mapbox GL for Goong Maps
  geolocator: ^10.1.0
  geocoding: ^2.1.1
```

## 5. API Configuration

The `ApiConfig` class has been updated to use Goong endpoints:

- **Maps API**: `https://rsapi.goong.io`
- **Places API**: `https://rsapi.goong.io/Place`

## 6. Features Implemented

### Home Screen
- ✅ Goong Maps integration using Mapbox GL
- ✅ Custom map style from Goong
- ✅ Location services
- ✅ Parking lot markers
- ✅ Camera controls

### Search Screen
- ✅ Goong Places Autocomplete API
- ✅ Place search functionality
- ✅ Place details API
- ✅ Nearby parking lot integration

## 7. Map Style

The app uses Goong's Vietnamese map style:
```dart
styleString: 'https://tiles.goong.io/assets/goong-map-v2.json'
```

## 8. Running the App

1. Make sure your `.env` file contains the correct API keys
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## 9. Troubleshooting

### Common Issues

1. **Map not loading**: Check if your `MAPS_API_KEY` is correct
2. **Places API not working**: Verify your `PLACE_API_KEY` is valid
3. **Location not working**: Ensure location permissions are granted

### API Key Restrictions

Make sure to configure your API keys properly in the Goong console:
- Set appropriate restrictions for your app
- Enable the required APIs (Maps, Places)
- Configure billing if needed

## 10. Goong Maps Features

- ✅ Vietnamese map tiles
- ✅ Localized place names
- ✅ Vietnamese language support
- ✅ High-quality map rendering
- ✅ Offline map support (if configured)

## 11. Migration from Google Maps

The following changes have been made:

1. **Dependencies**: Replaced `google_maps_flutter` with `mapbox_gl`
2. **API Services**: Created `GoongPlacesService` to replace `PlacesService`
3. **Map Widget**: Updated to use `MapboxMap` instead of `GoogleMap`
4. **API Endpoints**: Changed to Goong API endpoints
5. **Map Style**: Using Goong's Vietnamese map style

## 12. Performance Considerations

- Goong Maps provides better performance for Vietnamese users
- Reduced API costs compared to Google Maps
- Better localization support
- Optimized for Vietnamese geography and place names

## Support

For issues with Goong Maps integration, refer to:
- [Goong Maps Documentation](https://docs.goong.io/)
- [Mapbox GL Flutter Plugin](https://github.com/flutter-mapbox-gl/maps)
- [Goong API Documentation](https://docs.goong.io/rest-api/)
