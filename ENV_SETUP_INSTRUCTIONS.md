# Environment Variables Setup

## Create Your .env File

1. **Create a `.env` file** in your project root directory (same level as `pubspec.yaml`)

2. **Add your Google Maps API key** to the `.env` file:

```env
MAPS_API_KEY=your_actual_google_maps_api_key_here
```

## Example .env File

```env
# Google Maps API Key
MAPS_API_KEY=AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Other environment variables (optional)
# API_BASE_URL=https://your-api-url.com
# DEBUG_MODE=true
```

## Important Notes

- **Never commit your `.env` file** to version control (it should be in `.gitignore`)
- **Replace the placeholder** with your actual Google Maps API key
- **Make sure Places API is enabled** for your API key in Google Cloud Console
- The same API key works for both Google Maps and Google Places API

## Security

- Keep your API key secure
- Use API key restrictions in Google Cloud Console
- Monitor your API usage and billing

## Testing

After setting up your `.env` file:

1. Run `flutter pub get`
2. Run your app
3. Navigate to the search screen
4. Start typing to test Google Places autocomplete

If you see "Error: Google Places API key not found in environment variables" in the console, check that:
- Your `.env` file exists in the project root
- The `MAPS_API_KEY` variable is correctly named
- Your API key is valid and has Places API enabled
