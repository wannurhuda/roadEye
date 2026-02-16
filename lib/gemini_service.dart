import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';;
  static const String _model = 'gemini-2.0-flash-lite';

  static Future<Map<String, dynamic>> analyzePothole(File imageFile) async {
    try {
      print('📸 Reading image file...');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('✅ Image encoded: ${bytes.length} bytes');

      final url =
          'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey';

      print('🌐 Calling Gemini API...');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "You are a road damage expert. Look at this road image.\n\nRespond ONLY in this exact format:\nDAMAGE_DETECTED: YES\nSEVERITY: CRITICAL\nCONFIDENCE: 90\nDESCRIPTION: Large pothole detected\nRECOMMENDATION: Immediate repair needed\n\nIf no damage: use DAMAGE_DETECTED: NO and SEVERITY: NONE"
                },
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 150,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
        data['candidates'][0]['content']['parts'][0]['text'] as String;
        print('✅ Gemini response: $text');
        return _parseResponse(text);
      } else {
        print('❌ Error: ${response.statusCode}');
        return _errorResult('API Error ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      print('❌ No internet');
      return _errorResult('No internet connection');
    } catch (e) {
      print('❌ Exception: $e');
      return _errorResult(e.toString());
    }
  }

  static Map<String, dynamic> _parseResponse(String text) {
    final lines = text.trim().split('\n');
    String severity = 'UNKNOWN';
    String description = 'Could not parse response';
    String recommendation = 'Please try again';
    int confidence = 0;
    bool damageDetected = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('DAMAGE_DETECTED:')) {
        damageDetected =
            trimmed.split(':')[1].trim().toUpperCase() == 'YES';
      } else if (trimmed.startsWith('SEVERITY:')) {
        severity = trimmed.split(':')[1].trim().toUpperCase();
      } else if (trimmed.startsWith('CONFIDENCE:')) {
        confidence = int.tryParse(trimmed.split(':')[1].trim()) ?? 0;
      } else if (trimmed.startsWith('DESCRIPTION:')) {
        description = trimmed.split(':').sublist(1).join(':').trim();
      } else if (trimmed.startsWith('RECOMMENDATION:')) {
        recommendation = trimmed.split(':').sublist(1).join(':').trim();
      }
    }

    print('✅ Parsed → Severity: $severity | Confidence: $confidence%');

    return {
      'damage_detected': damageDetected,
      'severity': severity,
      'confidence': confidence,
      'description': description,
      'recommendation': recommendation,
    };
  }

  static Map<String, dynamic> _errorResult(String error) {
    return {
      'damage_detected': false,
      'severity': 'UNKNOWN',
      'confidence': 0,
      'description': 'Error: $error',
      'recommendation': 'Please try again',
      'error': error,
    };
  }
}