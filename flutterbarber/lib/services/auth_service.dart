import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.22:8000/api/login';
  static const String registerUrl = 'http://192.168.1.22:8000/api/register';

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      // Ambil nama user dan userId dari response jika ada
      try {
        final data = json.decode(response.body);
        if (data['user'] != null) {
          if (data['user']['name'] != null) {
            await prefs.setString('userName', data['user']['name']);
          }
          if (data['user']['id'] != null) {
            await prefs.setInt('userId', data['user']['id']);
          }
        }
      } catch (_) {}
      return true;
    }
    return false;
  }

  static Future<bool> register(String name, String email, String password, {String? phone}) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
    };
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Register error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Register exception: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> registerWithMessage(String name, String email, String password, {String? phone}) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
    };
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        String msg = 'Registrasi gagal!';
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            msg = data['message'];
          } else if (data is Map && data['errors'] != null) {
            msg = data['errors'].toString();
          }
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('userName');
    await prefs.remove('userId');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }
} 