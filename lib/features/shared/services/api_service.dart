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

  static Future<Map<String, dynamic>> createSupplyDraft({
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

  static Future<Map<String, dynamic>> saveSupplyHeader({
    required int supplyCls,
    required int supplyId,
    required String supplyNo,
    required String supplyDateDdMmmYyyy,
    required int fromId,
    required int toId,
    required int orderId,
    required String orderSeq,
    required String refNo,
    required String remarks,
    required int templateSts,
    required String templateName,
    required int? preparedBy,
    required int? approvedBy,
    required int? receivedBy,
    required int companyId,
    required String userEntry,
  }) async {
    String _q(String s) => "'${s.replaceAll("'", "''")}'";
    String _qn(String? s) => s == null || s.isEmpty ? 'NULL' : _q(s);
    String _n(int? v) => v == null ? 'NULL' : v.toString();

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spInv_StockSupply_SaveHeader "
            "@Supply_Cls = ${supplyCls}, "
            "@Supply_ID = ${_q(supplyId.toString())}, "
            "@Supply_No = ${_q(supplyNo)}, "
            "@Supply_Date = ${_q(supplyDateDdMmmYyyy)}, "
            "@From_ID = ${fromId}, "
            "@To_ID = ${toId}, "
            "@Order_ID = ${orderId}, "
            "@Order_Seq = ${_q(orderSeq)}, "
            "@Ref_No = ${_q(refNo)}, "
            "@Remarks = ${_q(remarks)}, "
            "@Template_Sts = ${templateSts}, "
            "@Template_Name = ${_q(templateName)}, "
            "@Prepared_By = ${_n(preparedBy)}, "
            "@Approved_By = ${_n(approvedBy)}, "
            "@Received_By = ${_n(receivedBy)}, "
            "@Company_ID = ${_q(companyId.toString())}, "
            "@User_Entry = ${_q(userEntry)}"
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
          'message': 'Failed to save supply header with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> saveSupplyDetail({
    required int supplyId,
    required String seqId,
    required int itemId,
    required double qty,
    required int? unitId,
    required String lotNumber,
    required String heatNumber,
    required String size,
    required String description,
    required String userEntry,
  }) async {
    String _q(String s) => "'${s.replaceAll("'", "''")}'";
    String _qn(String? s) => s == null || s.isEmpty ? 'NULL' : _q(s);
    String _n(int? v) => v == null ? 'NULL' : v.toString();

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spInv_StockSupply_SaveDetail "
            "@Supply_ID = ${supplyId}, "
            "@Seq_ID = ${_q(seqId)}, "
            "@Item_ID = ${itemId}, "
            "@Qty = ${qty}, "
            "@Unit_ID = ${_n(unitId)}, "
            "@Lot_Number = ${_q(lotNumber)}, "
            "@Heat_Number = ${_q(heatNumber)}, "
            "@Size = ${_q(size)}, "
            "@Description = ${_q(description)}, "
            "@User_Entry = ${_q(userEntry)}"
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
          return {'success': false, 'message': message.replaceAll('ERR@', '').trim()};
        }
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': 'Failed to save supply detail with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteSupply({
    required int supplyId,
    String seqId = '0',
  }) async {
    String _seq(String input) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return "'0'";
      return "'${trimmed.replaceAll("'", "''")}'";
    }

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spInv_StockSupply_Delete "
            "@Supply_ID = ${supplyId}, "
            "@Seq_ID = ${_seq(seqId)}"
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
          return {'success': false, 'message': message.replaceAll('ERR@', '').trim()};
        }
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete supply detail with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ API Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
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

  static Future<Map<String, dynamic>> browseOrderEntryItems({
    int companyId = 1,
    String dateStart = '2020-01-01',
    String dateEnd = '2025-02-28',
    String? temp1,
    String? temp2,
  }) async {
    final temp1Clause = (temp1 == null || temp1.isEmpty) ? 'NULL' : "'${temp1}'";
    final temp2Clause = (temp2 == null || temp2.isEmpty) ? 'NULL' : "'${temp2}'";

    try {
      final body = {
        'apikey': 'none',
        'apidata':
            "EXEC spMst_Browse_Select @Data = 'ORDERENTRYITEM', @ID = NULL, @DateStart = '$dateStart', @DateEnd = '$dateEnd', @Company_ID = '${companyId}', @Temp1 = ${temp1Clause}, @Temp2 = ${temp2Clause}",
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
              'Failed to fetch order entry items browse with status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>> createSupplyWithDetails({
    required int supplyCls,
    required String supplyNo,
    required String supplyDateDdMmmYyyy,
    required int fromId,
    required int toId,
    required int orderId,
    required String orderSeq,
    required String refNo,
    required String remarks,
    required int templateSts,
    required String templateName,
    required int? preparedBy,
    required int? approvedBy,
    required int? receivedBy,
    required int companyId,
    required String userEntry,
    required List<Map<String, dynamic>> details,
  }) async {
    final headerRes = await saveSupplyHeader(
      supplyCls: supplyCls,
      supplyId: 0,
      supplyNo: supplyNo.isEmpty ? 'AUTO' : supplyNo,
      supplyDateDdMmmYyyy: supplyDateDdMmmYyyy,
      fromId: fromId,
      toId: toId,
      orderId: orderId,
      orderSeq: orderSeq,
      refNo: refNo,
      remarks: remarks,
      templateSts: templateSts,
      templateName: templateName,
      preparedBy: preparedBy,
      approvedBy: approvedBy,
      receivedBy: receivedBy,
      companyId: companyId,
      userEntry: userEntry,
    );

    if (headerRes['success'] != true) {
      return {
        'success': false,
        'message': headerRes['message'] ?? 'Failed to save header',
      };
    }

    int? newId;
    try {
      final data = headerRes['data'] as Map<String, dynamic>;
      final tbl0 = data['tbl0'] as List?;
      if (tbl0 != null && tbl0.isNotEmpty) {
        final first = (tbl0.first as Map).cast<String, dynamic>();
        final resultMsg = first['Result']?.toString();
        final idField = first['Supply_ID'] ?? first['ID'] ?? first['SupplyId'];
        newId = idField is int ? idField : int.tryParse(idField?.toString() ?? '');
        if (newId == null && resultMsg != null) {
          final match = RegExp(r"ID\s*[:=]\s*(\d+)").firstMatch(resultMsg);
          if (match != null) {
            newId = int.tryParse(match.group(1)!);
          }
        }
      }
    } catch (_) {}

    if (newId == null) {
      return {
        'success': false,
        'message': 'Header saved but Supply_ID not returned',
      };
    }

    final detailResults = <Map<String, dynamic>>[];
    bool allDetailsOk = true;
    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return int.tryParse(text);
    }

    for (var i = 0; i < details.length; i++) {
      final d = details[i];
      final itemId = _toInt(d['itemId']) ?? 0;
      final qty = (d['qty'] as num?)?.toDouble() ?? 0.0;
      if (itemId <= 0 || qty <= 0) {
        detailResults.add({
          'index': i,
          'success': false,
          'message': 'Invalid itemId/qty',
        });
        allDetailsOk = false;
        continue;
      }

      final unitId = _toInt(d['unitId']);
      final lotNumber = (d['lotNumber'] as String? ?? '').trim();
      final heatNumber = (d['heatNumber'] as String? ?? '').trim();
      final size = (d['size'] as String? ?? '').trim();
      final description = (d['description'] as String? ?? '').trim();
      final seqId = (d['seqId']?.toString().trim().isNotEmpty == true)
          ? d['seqId'].toString().trim()
          : '0';

      final res = await saveSupplyDetail(
        supplyId: newId,
        seqId: seqId,
        itemId: itemId,
        qty: qty,
        unitId: unitId,
        lotNumber: lotNumber,
        heatNumber: heatNumber,
        size: size,
        description: description,
        userEntry: userEntry,
      );

      if (res['success'] != true) {
        allDetailsOk = false;
      }
      detailResults.add({
        'index': i,
        'success': res['success'] == true,
        'message': res['message'],
        'data': res['data'],
      });
    }

    return {
      'success': allDetailsOk,
      'headerId': newId,
      'header': headerRes['data'],
      'details': detailResults,
      'message': allDetailsOk
          ? 'Header and details saved'
          : 'Header saved; some details failed',
    };
  }

}

