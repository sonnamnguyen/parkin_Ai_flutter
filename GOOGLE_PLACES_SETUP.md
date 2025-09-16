# Google Places API Setup Guide

This guide will help you set up Google Places API for your Flutter parking app.

## Prerequisites

1. A Google Cloud Platform account
2. A Flutter project with the necessary dependencies

## Step 1: Enable Google Places API

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Library"
4. Search for "Places API" and enable it
5. Also enable "Geocoding API" and "Maps JavaScript API" if needed

## Step 2: Configure Environment Variables

Since you're using `flutter_dotenv` and have a `.env` file, you can use the same `MAPS_API_KEY` for Google Places API.

### Create or Update Your .env File

Create a `.env` file in your project root (if it doesn't exist) and add your Google Maps API key:

```env
# Google Maps API Key
MAPS_API_KEY=your_actual_google_maps_api_key_here
```

**Note**: Make sure your Google Maps API key has the following APIs enabled:
- Maps SDK for Android
- Places API
- Geocoding API (optional, for additional functionality)

### Environment Variable Setup

The app is already configured to load the API key from your `.env` file using:
```dart
static String get googlePlacesApiKey => dotenv.env['MAPS_API_KEY'] ?? '';
```

## Step 4: Install Dependencies

Run the following command to install the required dependencies:

```bash
flutter pub get
```

## Step 5: Test the Implementation

1. Run your Flutter app
2. Navigate to the search screen
3. Start typing in the search field
4. You should see Google Places autocomplete suggestions

## Features Included

- **Place Autocomplete**: Real-time search suggestions as you type
- **Place Details**: Detailed information about selected places
- **Text Search**: Search for places by name or description
- **Nearby Search**: Find places near a specific location
- **Vietnamese Language Support**: Localized for Vietnamese users
- **Recent Searches**: Remember and display recent search queries

## API Usage and Billing

- Google Places API has usage limits and billing
- Autocomplete requests are charged per request
- Place Details requests are charged per request
- Monitor your usage in the Google Cloud Console

## Security Best Practices

1. **Restrict API Key**: Limit your API key to specific apps and APIs
2. **Use Environment Variables**: Store API keys in environment variables for production
3. **Monitor Usage**: Set up billing alerts and usage monitoring
4. **Rate Limiting**: Implement rate limiting in your app to avoid excessive API calls

## Troubleshooting

### Common Issues

1. **"This API project is not authorized to use this API"**
   - Make sure you've enabled the Places API in your Google Cloud project

2. **"The provided API key is invalid"**
   - Check that your API key is correct and properly configured

3. **"REQUEST_DENIED"**
   - Verify that your API key has the necessary permissions
   - Check if you've set up proper restrictions

4. **No search results**
   - Ensure your API key is valid and the Places API is enabled
   - Check your internet connection
   - Verify the search query is not empty

### Debug Mode

To debug API calls, check the console output for error messages. The service includes error logging for troubleshooting.

## Additional Resources

- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
