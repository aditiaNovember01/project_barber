import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class BookingService {
  static const String baseUrl = 'http://192.168.1.11:8000/api/bookings';

  static Future<List<Booking>> fetchBookings() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data booking');
    }
  }

  static Future<bool> createBooking(Map<String, dynamic> data, {String? filePath, Uint8List? fileBytes, String? fileName}) async {
    if (kIsWeb) {
      try {
        var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
        if (fileBytes != null && fileName != null) {
          request.files.add(http.MultipartFile.fromBytes('proof_of_payment', fileBytes, filename: fileName));
        }
        var streamedResponse = await request.send().timeout(Duration(seconds: 15));
        var response = await http.Response.fromStream(streamedResponse);
        if (!(response.statusCode == 201 || response.statusCode == 200)) {
          if (kDebugMode) print('Booking gagal (web): ${response.statusCode} - ${response.body}');
        }
        return response.statusCode == 201 || response.statusCode == 200;
      } catch (e) {
        if (kDebugMode) print('Booking error (web): $e');
        return false;
      }
    } else if (filePath != null) {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      request.files.add(await http.MultipartFile.fromPath('proof_of_payment', filePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (!(response.statusCode == 201 || response.statusCode == 200)) {
        if (kDebugMode) print('Booking gagal: ${response.statusCode} - ${response.body}');
      }
      return response.statusCode == 201 || response.statusCode == 200;
    } else {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (!(response.statusCode == 201 || response.statusCode == 200)) {
        if (kDebugMode) print('Booking gagal: ${response.statusCode} - ${response.body}');
      }
      return response.statusCode == 201 || response.statusCode == 200;
    }
  }
} 