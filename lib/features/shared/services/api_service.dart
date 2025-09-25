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

  static Future<Map<String, dynamic>> getSupplyStock({
    DateTime? dateStart,
    DateTime? dateEnd,
  }) async {
    try {
      final startDate = dateStart?.toIso8601String().split('T')[0] ?? '2020-01-01';
      final endDate = dateEnd?.toIso8601String().split('T')[0] ?? '2025-12-31';

      final body = {
        "apikey": "none",
        "apidata": "EXEC spMst_Browse_Select @Data = 'STOCKSUPPLY', @ID = 1, @DateStart = '$startDate', @DateEnd = '$endDate', @Company_ID = 1, @Temp1 = NULL, @Temp2 = NULL"
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

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch supply stock with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> browseItemStockByLot({
    int id = 12,
    int companyId = 1,
    String? temp1,
    String? temp2,
  }) async {
    final temp1Clause = (temp1 == null || temp1.isEmpty) ? 'NULL' : "'${temp1}'";
    final temp2Clause = (temp2 == null || temp2.isEmpty) ? 'NULL' : "'${temp2}'";

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spMst_Browse_Select @Data = 'ITEMSTOCKBYLOT', @ID = ${id}, @DateStart = NULL, @DateEnd = NULL, @Company_ID = '${companyId}', @Temp1 = ${temp1Clause}, @Temp2 = ${temp2Clause}",
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
        final message = responseData['msg'] as String?;
        if (message != null && message.contains('ERR@')) {
          return {
            'success': false,
            'message': message.replaceAll('ERR@', '').trim(),
          };
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch item browse with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> browseWarehouses({
    int? id,
    int companyId = 1,
    String? temp1,
    String? temp2,
  }) async {
    final idClause = id == null ? 'NULL' : '$id';
    final temp1Clause = (temp1 == null || temp1.isEmpty) ? 'NULL' : "'${temp1}'";
    final temp2Clause = (temp2 == null || temp2.isEmpty) ? 'NULL' : "'${temp2}'";

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spMst_Browse_Select @Data = 'WAREHOUSE', @ID = ${idClause}, @DateStart = NULL, @DateEnd = NULL, @Company_ID = '${companyId}', @Temp1 = ${temp1Clause}, @Temp2 = ${temp2Clause}",
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
        final message = responseData['msg'] as String?;
        if (message != null && message.contains('ERR@')) {
          return {
            'success': false,
            'message': message.replaceAll('ERR@', '').trim(),
          };
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch warehouse browse with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> showItemStockByLot({
    required dynamic id,
    required dynamic seq,
    required int companyId,
    String temp = 'Temp',
  }) async {
    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spMst_Browse_Show @Data = 'ITEMSTOCKBYLOT', @ID = '${id}', @Seq = '${seq}', @Company_ID = '${companyId}', @Temp = '${temp}'",
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
        final message = responseData['msg'] as String?;
        if (message != null && message.contains('ERR@')) {
          return {
            'success': false,
            'message': message.replaceAll('ERR@', '').trim(),
          };
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch item detail with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> createNewSupply({
    required int supplyCls,
    required String userEntry,
    required String supplyDate,
    required bool useTemplate,
    required int companyId,
  }) async {
    try {
      final body = {
        "apikey": "none",
        "apidata": "EXEC spInv_StockSupply_Select @Data = 'New', @Supply_Cls = $supplyCls, @Supply_ID = 0, @User_Entry = '$userEntry', @Supply_Date = '$supplyDate', @UseTemplate = ${useTemplate ? 1 : 0}, @Company_ID = $companyId"
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

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create new supply with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> getSupplyDetail({
    required int supplyCls,
    required int supplyId,
    required String userEntry,
    required int companyId,
  }) async {
    try {
      final body = {
        "apikey": "none",
        "apidata": "EXEC spInv_StockSupply_Select @Data = 'Detail', @Supply_Cls = $supplyCls, @Supply_ID = $supplyId, @User_Entry = '$userEntry', @Supply_Date = NULL, @UseTemplate = 0, @Company_ID = $companyId"
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

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get supply detail with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> getSupplyHeader({
    required int supplyCls,
    required int supplyId,
    required String userEntry,
    required int companyId,
    String? supplyDateStr,
  }) async {
    try {
      final body = {
        "apikey": "none",
        "apidata": "EXEC spInv_StockSupply_Select @Data = 'Header', @Supply_Cls = $supplyCls, @Supply_ID = $supplyId, @User_Entry = '$userEntry', @Supply_Date = ${supplyDateStr != null ? "'$supplyDateStr'" : 'NULL'}, @UseTemplate = 0, @Company_ID = $companyId"
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

        final message = responseData['msg'] as String?;
        if (message != null && message.contains('ERR@')) {
          return {
            'success': false,
            'message': message.replaceAll('ERR@', '').trim(),
          };
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get supply header with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> browseEmployees({
    int? id,
    int companyId = 1,
    String? temp1,
    String? temp2,
  }) async {
    final idClause = id == null ? 'NULL' : '$id';
    final temp1Clause = (temp1 == null || temp1.isEmpty) ? 'NULL' : "'${temp1}'";
    final temp2Clause = (temp2 == null || temp2.isEmpty) ? 'NULL' : "'${temp2}'";

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spMst_Browse_Select @Data = 'EMPLOYEE', @ID = ${idClause}, @DateStart = NULL, @DateEnd = NULL, @Company_ID = '${companyId}', @Temp1 = ${temp1Clause}, @Temp2 = ${temp2Clause}",
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
        final message = responseData['msg'] as String?;
        if (message != null && message.contains('ERR@')) {
          return {
            'success': false,
            'message': message.replaceAll('ERR@', '').trim(),
          };
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch employee browse with status: ${response.statusCode}',
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
