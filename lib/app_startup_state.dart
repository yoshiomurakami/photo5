// import 'package:flutter/foundation.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:sqflite/sqflite.dart';
// import 'dart:math';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'error_dialog.dart';
// import 'package:flutter/material.dart';
//
// class AppStartupState extends ChangeNotifier {
//   BuildContext? _context;
//   final errorMessages = <String>[];
//
//   void setContext(BuildContext context) {
//     _context = context;
//   }
//
//   String globalCheckID = '';
//   String globalUserID = '';
//
//   Future<void> initializeApp() async {
//     try {
//       await _performLanguageSetup();
//       await _performVersionCheck();
//       await _performUserIdCheck();
//     } catch (e) {
//       showErrorIfAny(e);
//       rethrow;  // エラーを再スローします。
//     }
//     notifyListeners();
//   }
//
//   Future<void> _performLanguageSetup() async {
//     // 言語設定の処理を実装します。
//
//     // 処理が完了したら結果をフィールドに保存します。
//   }
//
//   Future<void> _performVersionCheck() async {
//     // バージョンチェックの処理を実装します。
//
//     // 処理が完了したら結果をフィールドに保存します。
//   }
//
//   Future<void> _performUserIdCheck() async {
//     await dotenv.load(fileName: '.env');
//     var apiUri = '';
//     try {
//       apiUri = dotenv.get('API_URI');
//     } catch (e) {
//       debugPrint('Error: $e');
//       errorMessages.add('API_URI variable not found in .env file. Error: $e');
//       showErrorIfAny(e);  // ここでエラーを表示するようにします。
//       return;
//     }
//     debugPrint(apiUri);
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final db = await openDatabase('photo5.db');
//     await db.execute('CREATE TABLE IF NOT EXISTS regist (checkID TEXT, userID TEXT)');
//     globalCheckID = prefs.getString('checkID') ?? '';
//
//     final List<Map<String, dynamic>> maps = await db.query('regist');
//     if (maps.isNotEmpty) {
//       globalUserID = maps[0]['userID'] ?? '';
//     }
//
//     if (globalCheckID.isEmpty) {
//       final checkID = _generateCheckId();
//       prefs.setString('checkID', checkID);
//       globalCheckID = checkID;
//       debugPrint("User ID generated and saved to shared preferences.");
//
//       try {
//         final response = await http.post(
//           Uri.parse(dotenv.get('API_URI') + 'express/regist'),
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode({'checkID': checkID}),
//         );
//
//         debugPrint('Response status: ${response.statusCode}');
//         debugPrint('Response body: ${response.body}');
//
//         if (response.statusCode == 200) {
//           final userID = jsonDecode(response.body)['userID'];
//           if (maps.isEmpty) {
//             await db.insert('regist', {'checkID': checkID, 'userID': userID});
//           } else {
//             await db.update('regist', {'checkID': checkID, 'userID': userID},
//                 where: 'checkID = ?', whereArgs: [checkID]);
//           }
//           globalUserID = userID;
//           debugPrint("User ID saved in SQLite.");
//         } else {
//           throw Exception('Failed to register user');
//         }
//       } catch (e) {
//         debugPrint('Error: $e');
//         errorMessages.add('Failed to register user. Error: $e');
//       }
//     } else {
//       debugPrint("User ID already exists.");
//       debugPrint("Existing check ID: $globalCheckID, user ID: $globalUserID");
//     }
//     debugPrint("User ID check completed. CheckID = $globalCheckID, userID = $globalUserID");
//   }
//
//   void showErrorIfAny(e) {
//     if (_context != null && errorMessages.isNotEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showErrorDialog(_context!, errorMessages.join('\n'));
//       });
//       errorMessages.clear();
//     }
//   }
//
//   String _generateCheckId() {
//     const _allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     final _random = Random();
//
//     return List.generate(5, (index) {
//       int randomIndex = _random.nextInt(_allowedChars.length);
//       return _allowedChars[randomIndex];
//     }).join();
//   }
// }