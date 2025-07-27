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
      appBar: AppBar(
        title: Text('Daftar Barber'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                futureBarbers = BarberService.fetchBarbers();
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureBarbers = BarberService.fetchBarbers();
          });
          await futureBarbers;
        },
        child: FutureBuilder<List<Barber>>(
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
                String baseUrl = 'http://192.168.1.22:8000';
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
                return GestureDetector(
                  onTap: barber.status.toLowerCase() == 'active' ? () {} : null,
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue.shade100, width: 2),
                                ),
                                child: ClipOval(
                                  child: barber.photo.isNotEmpty
                                      ? Image.network(
                                          photoUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.person, size: 40, color: Colors.blue.shade100);
                                          },
                                        )
                                      : Icon(Icons.person, size: 40, color: Colors.blue.shade100),
                                ),
                              ),
                              SizedBox(width: 22),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          barber.name,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue.shade900),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: barber.status.toLowerCase() == 'active' ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                barber.status.toLowerCase() == 'active' ? Icons.check_circle : Icons.block,
                                                color: barber.status.toLowerCase() == 'active' ? Colors.green : Colors.red,
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                barber.status.toLowerCase() == 'active' ? 'Aktif' : 'Tidak Aktif',
                                                style: TextStyle(
                                                  color: barber.status.toLowerCase() == 'active' ? Colors.green.shade700 : Colors.red.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        Chip(
                                          label: Text(barber.specialty, style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                                          backgroundColor: Colors.blue.shade50,
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (barber.status.toLowerCase() != 'active')
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text('Barber Tidak Aktif', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 