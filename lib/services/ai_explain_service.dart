// ai_explain_service.dart – Service to fetch AI explanation for a question
// Uses the `http` package. In a real app you would inject the base URL
// and handle authentication. The method returns a map with either "text" or "json"
// depending on success.

import 'dart:convert';
import 'package:http/http.dart' as http;

class AIExplainService {
  static const String _baseUrl = 'https://api.example.com'; // placeholder

  /// Fetch explanation for a question.
  /// Returns a map containing either:
  ///   {"text": "..."} on success,
  ///   {"json": "..."} on timeout / error.
  static Future<Map<String, String>> fetchExplanation(String questionId) async {
    final uri = Uri.parse('$_baseUrl/explain?questionId=$questionId');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assume API returns {"explanation": "..."}
        if (data is Map && data['explanation'] != null) {
          return {'text': data['explanation'].toString()};
        }
        // Fallback to raw JSON string
        return {'json': response.body};
      } else {
        // Non‑200: return raw body as JSON fallback
        return {'json': response.body};
      }
    } catch (e) {
      // Timeout or network error -> fallback JSON placeholder
      return {'json': '{"error": "Unable to reach explanation service"}'};
    }
  }
}
