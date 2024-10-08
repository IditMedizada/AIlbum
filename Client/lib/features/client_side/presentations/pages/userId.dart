// Save user ID to local storage (cookies)
// ignore_for_file: file_names

  import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  // Retrieve user ID from local storage (cookies)
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

// Reset user Id from local storage (cookies)
  Future<void> resetUserId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId'); 
  }