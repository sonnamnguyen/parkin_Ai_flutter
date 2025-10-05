class UrlUtils {
  /// Clean and extract valid URLs from malformed API responses
  static String? cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Remove any whitespace
    url = url.trim();
    
    // Check if it's already a valid URL
    if (_isValidUrl(url)) {
      return url;
    }
    
    // Try to extract valid URLs from concatenated strings
    final validUrls = _extractValidUrls(url);
    
    // Return the first valid URL found
    return validUrls.isNotEmpty ? validUrls.first : null;
  }
  
  /// Check if a URL is valid
  static bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }
  
  /// Extract valid URLs from a potentially concatenated string
  static List<String> _extractValidUrls(String input) {
    final List<String> urls = [];
    
    // Split by common patterns that might separate URLs
    final patterns = [
      RegExp(r'https?://[^\s]+'), // Match http/https URLs
      RegExp(r'\.jpg|\.jpeg|\.png|\.gif|\.webp'), // Match image extensions
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(input);
      for (final match in matches) {
        final url = match.group(0);
        if (url != null && _isValidUrl(url)) {
          urls.add(url);
        }
      }
    }
    
    // If no URLs found with patterns, try manual extraction
    if (urls.isEmpty) {
      final manualUrls = _manualUrlExtraction(input);
      urls.addAll(manualUrls);
    }
    
    return urls;
  }
  
  /// Manual URL extraction for complex cases
  static List<String> _manualUrlExtraction(String input) {
    final List<String> urls = [];
    
    // Look for https:// patterns
    final httpsMatches = RegExp(r'https://[^\s]+').allMatches(input);
    for (final match in httpsMatches) {
      final url = match.group(0);
      if (url != null && _isValidUrl(url)) {
        urls.add(url);
      }
    }
    
    // Look for http:// patterns
    final httpMatches = RegExp(r'http://[^\s]+').allMatches(input);
    for (final match in httpMatches) {
      final url = match.group(0);
      if (url != null && _isValidUrl(url)) {
        urls.add(url);
      }
    }
    
    return urls;
  }
  
  /// Get the best image URL from a list of URLs
  static String? getBestImageUrl(List<String> urls) {
    if (urls.isEmpty) return null;
    
    // Prefer URLs that look like real image URLs
    for (final url in urls) {
      if (url.contains('.jpg') || url.contains('.jpeg') || 
          url.contains('.png') || url.contains('.gif') || 
          url.contains('.webp')) {
        return url;
      }
    }
    
    // Return the first valid URL if no image-specific URL found
    return urls.first;
  }
}
