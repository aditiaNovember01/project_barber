import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/barber.dart';
import '../services/barber_service.dart';

class BarberScreen extends StatefulWidget {
  @override
  _BarberScreenState createState() => _BarberScreenState();
}

class _BarberScreenState extends State<BarberScreen> {
  late Future<List<Barber>> futureBarbers;

  @override
  void initState() {
    super.initState();
    futureBarbers = BarberService.fetchBarbers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: Text('Daftar Barber'), backgroundColor: Colors.blue.shade700),
      body: FutureBuilder<List<Barber>>(
        future: futureBarbers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data barber'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada data barber'));
          }
          final barbers = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: barbers.length,
            separatorBuilder: (_, __) => SizedBox(height: 20),
            itemBuilder: (context, index) {
              final barber = barbers[index];
              String baseUrl = 'http://10.176.85.163:8000';
              String photoUrl = '';
              if (barber.photo.isNotEmpty) {
                if (barber.photo.startsWith('http')) {
                  photoUrl = barber.photo;
                } else {
                  photoUrl = '$baseUrl/storage/barbers/${barber.photo}';
                }
                print('Barber object: ' + barber.toString());
                print('Barber photo: ${barber.photo}');
                print('Photo URL: $photoUrl');
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue.shade200, width: 3),
                        ),
                        child: ClipOval(
                          child: barber.photo.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Image load error for $photoUrl: $error');
                                    return Icon(Icons.person, size: 40, color: Colors.purple.shade100);
                                  },
                                )
                              : Icon(Icons.person, size: 40, color: Colors.purple.shade100),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              barber.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue.shade900),
                            ),
                            SizedBox(height: 6),
                            Text(
                              barber.specialty,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: barber.status == 'Available' ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    barber.status,
                                    style: TextStyle(
                                      color: barber.status == 'Available' ? Colors.green.shade700 : Colors.red.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 