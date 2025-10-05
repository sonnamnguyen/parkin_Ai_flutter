import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../constants/app_strings.dart';
import '../../data/models/parking_lot_model.dart';

class AiService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  /// Test if Gemini API is properly configured
  static Future<bool> testApiConnection() async {
    try {
      if (!ApiConfig.isGeminiApiKeyLoaded) {
        print('❌ Gemini API key not loaded');
        return false;
      }
      
      print('✅ Gemini API key is loaded');
      print('🔗 Testing endpoint: $_geminiApiUrl');
      
      // Simple test request
      final response = await http.post(
        Uri.parse(_geminiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': ApiConfig.geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': 'Hello, respond with "API working"'}]
            }
          ]
        }),
      );
      
      print('📊 Test response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0];
          final content = candidate['content'];
          final parts = content?['parts'] as List?;
          
          if (parts != null && parts.isNotEmpty) {
            print('✅ Kết nối Gemini API thành công!');
            return true;
          } else {
            print('⚠️ Gemini API đã kết nối nhưng không có nội dung trả về (có thể đạt giới hạn token)');
            return true; // Still consider it successful since API is working
          }
        } else {
          print('⚠️ Gemini API đã kết nối nhưng không có ứng viên trả về');
          return true; // Still consider it successful since API is working
        }
      } else {
        print('❌ Kiểm tra Gemini API thất bại: ${response.statusCode}');
        print('Phản hồi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi kiểm tra Gemini API: $e');
      return false;
    }
  }
  
  /// Get AI recommendation for best parking lot
  static Future<AiRecommendation> getBestParkingLot({
    required List<ParkingLot> parkingLots,
    required double userLatitude,
    required double userLongitude,
    String? userPreferences,
  }) async {
    try {
      // Check if API key is available
      if (!ApiConfig.isGeminiApiKeyLoaded) {
        print('Gemini API key not loaded, using fallback recommendation');
        return _getFallbackRecommendation(parkingLots, userLatitude, userLongitude);
      }
      
      final prompt = _buildPrompt(parkingLots, userLatitude, userLongitude, userPreferences);
      
      final response = await http.post(
        Uri.parse(_geminiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': ApiConfig.geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 5,
            'topP': 0.3,
            'maxOutputTokens': 500,
          }
        }),
      );

      print('=== GEMINI API REQUEST ===');
      print('URL: $_geminiApiUrl');
      print('API Key: ${ApiConfig.geminiApiKey.isNotEmpty ? 'Present' : 'Missing'}');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates == null || candidates.isEmpty) {
          throw Exception('Không có phản hồi từ AI');
        }
        
        final candidate = candidates[0];
        final content = candidate['content'];
        final parts = content?['parts'] as List?;
        
        if (parts == null || parts.isEmpty) {
          // Handle case where model hit token limit or no content
          final finishReason = candidate['finishReason'];
          if (finishReason == 'MAX_TOKENS') {
            throw Exception('AI đã đạt giới hạn token. Vui lòng thử với ít bãi đỗ xe hơn hoặc sở thích ngắn gọn hơn.');
          }
          throw Exception('Không có nội dung trong phản hồi AI');
        }
        
        final aiResponse = parts[0]['text'] as String?;
        if (aiResponse == null || aiResponse.isEmpty) {
          throw Exception('Phản hồi AI trống');
        }
        
        return _parseAiResponse(aiResponse, parkingLots);
      } else {
        print('=== GEMINI API ERROR ===');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        print('Headers: ${response.headers}');
        
        if (response.statusCode == 404) {
          throw Exception('Gemini API not found. Please check your API key and endpoint.');
        } else if (response.statusCode == 401) {
          throw Exception('Invalid Gemini API key. Please check your API key.');
        } else if (response.statusCode == 403) {
          throw Exception('Gemini API access forbidden. Please check your API key permissions.');
        } else {
          throw Exception('AI API Error: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('AI Service Error: $e');
      // Fallback to simple distance-based recommendation
      return _getFallbackRecommendation(parkingLots, userLatitude, userLongitude);
    }
  }

  /// Build the prompt for Gemini AI
  static String _buildPrompt(List<ParkingLot> parkingLots, double userLat, double userLng, String? preferences) {
    // Limit to only 5 parking lots to reduce token usage
    final limitedLots = parkingLots.take(5).toList();
    
    final parkingData = limitedLots.map((lot) => {
      'id': lot.id,
      'name': lot.name,
      'distance_km': _calculateDistance(userLat, userLng, lot.latitude, lot.longitude),
    }).toList();

    return '''
Chọn bãi đỗ xe tốt nhất:
${jsonEncode(parkingData)}

JSON: {"recommended_lot_id": [ID], "reasoning": "Lý do", "confidence_score": 0.95, "alternatives": [{"lot_id": [ID]}], "ai_message": "Tin nhắn"}
''';
  }

  /// Parse AI response and create recommendation
  static AiRecommendation _parseAiResponse(String aiResponse, List<ParkingLot> parkingLots) {
    try {
      // Clean the response to extract JSON
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('No valid JSON found in AI response');
      }
      
      final jsonString = aiResponse.substring(jsonStart, jsonEnd);
      final data = jsonDecode(jsonString);
      
      final recommendedId = data['recommended_lot_id'] as int;
      final recommendedLot = parkingLots.firstWhere(
        (lot) => lot.id == recommendedId,
        orElse: () => parkingLots.first,
      );
      
      return AiRecommendation(
        recommendedLot: recommendedLot,
        reasoning: data['reasoning'] ?? 'AI analysis completed',
        confidenceScore: (data['confidence_score'] ?? 0.8).toDouble(),
        alternatives: _parseAlternatives(data['alternatives'] ?? [], parkingLots),
        aiMessage: data['ai_message'] ?? 'Đây là lựa chọn bãi đỗ xe tốt nhất cho bạn!',
      );
    } catch (e) {
      print('Error parsing AI response: $e');
      return _getFallbackRecommendation(parkingLots, 0, 0);
    }
  }

  /// Parse alternative recommendations
  static List<AiAlternative> _parseAlternatives(List<dynamic> alternatives, List<ParkingLot> parkingLots) {
    return alternatives.map((alt) {
      final lotId = alt['lot_id'] as int;
      final lot = parkingLots.firstWhere(
        (l) => l.id == lotId,
        orElse: () => parkingLots.first,
      );
      return AiAlternative(
        lot: lot,
        reason: alt['reason'] ?? 'Lựa chọn thay thế tốt',
      );
    }).toList();
  }

  /// Fallback recommendation when AI fails
  static AiRecommendation _getFallbackRecommendation(List<ParkingLot> parkingLots, double userLat, double userLng) {
    if (parkingLots.isEmpty) {
      throw Exception('Không có bãi đỗ xe nào khả dụng');
    }

    // Simple distance-based fallback
    final sortedLots = List<ParkingLot>.from(parkingLots);
    sortedLots.sort((a, b) {
      final distanceA = _calculateDistance(userLat, userLng, a.latitude, a.longitude);
      final distanceB = _calculateDistance(userLat, userLng, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });

    return AiRecommendation(
      recommendedLot: sortedLots.first,
      reasoning: 'Bãi đỗ xe gần nhất với vị trí của bạn',
      confidenceScore: 0.6,
      alternatives: sortedLots.skip(1).take(2).map((lot) => AiAlternative(
        lot: lot,
        reason: 'Lựa chọn thay thế',
      )).toList(),
      aiMessage: 'Tôi đã tìm thấy bãi đỗ xe gần nhất cho bạn!',
    );
  }

  /// Calculate distance between two points (Haversine formula)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

/// AI Recommendation model
class AiRecommendation {
  final ParkingLot recommendedLot;
  final String reasoning;
  final double confidenceScore;
  final List<AiAlternative> alternatives;
  final String aiMessage;

  AiRecommendation({
    required this.recommendedLot,
    required this.reasoning,
    required this.confidenceScore,
    required this.alternatives,
    required this.aiMessage,
  });
}

/// AI Alternative model
class AiAlternative {
  final ParkingLot lot;
  final String reason;

  AiAlternative({
    required this.lot,
    required this.reason,
  });
}
