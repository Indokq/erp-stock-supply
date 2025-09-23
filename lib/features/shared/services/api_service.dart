import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.19/oAPI/api';
  static const String token = 'XYZ';

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final body = {
        "apikey": "none",
        "apidata": "EXECUTE spWMS_Login @Username='$username', @Password='$password'"
      };

      print('🔗 API URL: $baseUrl');
      print('📤 Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response contains an error message
        final message = responseData['msg'] as String?;
        if (message != null && message.contains('ERR@')) {
          return {
            'success': false,
            'message': message.replaceAll('ERR@', '').trim(),
          };
        }

        // Check if the table data contains error results
        final tbl0 = responseData['tbl0'] as List?;
        if (tbl0 != null && tbl0.isNotEmpty) {
          final result = tbl0[0]['Result'] as String?;
          if (result != null && result.contains('Wrong Password')) {
            return {
              'success': false,
              'message': result,
            };
          }
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}