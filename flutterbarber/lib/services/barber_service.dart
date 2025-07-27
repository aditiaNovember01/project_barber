import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/barber.dart';
import 'package:flutter/foundation.dart';

class BarberService {
  static const String baseUrl = 'http://192.168.1.22:8000/api/barbers';

  static Future<List<Barber>> fetchBarbers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => Barber.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data barber');
    }
  }
} 