/// Gemini API Setup Guide
/// 
/// To fix the 404 error, follow these steps:
/// 
/// 1. Get a Gemini API Key:
///    - Go to https://aistudio.google.com/app/apikey
///    - Sign in with your Google account
///    - Click "Create API Key"
///    - Copy the generated API key
/// 
/// 2. Add to your .env file:
///    GEMINI_API_KEY=your_actual_api_key_here
/// 
/// 3. Make sure your .env file is loaded in main.dart:
///    await dotenv.load(fileName: ".env");
/// 
/// 4. API Key Format:
///    - Uses x-goog-api-key header (not query parameter)
///    - Format: 'x-goog-api-key': 'YOUR_API_KEY'
/// 
/// 5. Test the API key:
///    - The app will show "API Key: Present" in console if loaded correctly
///    - If you see "API Key: Missing", check your .env file
/// 
/// 6. Common Issues:
///    - 404: Wrong endpoint or API key not found
///    - 401: Invalid API key
///    - 403: API key doesn't have permissions
/// 
/// 7. Alternative endpoints to try:
///    - gemini-2.5-flash (current)
///    - gemini-pro
///    - gemini-1.5-pro
/// 
/// 8. If still having issues, the app will automatically fall back to
///    distance-based recommendations without AI.

class GeminiSetupGuide {
  static void printSetupInstructions() {
    print('''
=== GEMINI API SETUP GUIDE ===

1. Get API Key: https://aistudio.google.com/app/apikey
2. Add to .env: GEMINI_API_KEY=your_key_here
3. Restart app to load new environment variables
4. Check console for "API Key: Present" message

Current endpoint: gemini-2.5-flash
If 404 persists, try: gemini-pro or gemini-1.5-pro
''');
  }
}
