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
            separatorBuilder: (_, __) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              final barber = barbers[index];
              String baseUrl = 'http://192.168.1.11:8000';
              String photoUrl = '';
              if (barber.photo.isNotEmpty) {
                if (barber.photo.startsWith('http')) {
                  photoUrl = barber.photo;
                } else if (barber.photo.contains('storage/')) {
                  photoUrl = '$baseUrl/${barber.photo.startsWith('/') ? barber.photo.substring(1) : barber.photo}';
                } else if (barber.photo.contains('barbers/')) {
                  photoUrl = '$baseUrl/storage/${barber.photo.startsWith('/') ? barber.photo.substring(1) : barber.photo}';
                } else {
                  photoUrl = '$baseUrl/storage/barbers/${barber.photo}';
                }
              }
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                    radius: 28,
                  ),
                  title: Text(barber.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(barber.specialty, style: TextStyle(fontSize: 13, color: Colors.grey)),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: barber.status == 'Available' ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          barber.status,
                          style: TextStyle(
                            color: barber.status == 'Available' ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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