import 'package:flutter/material.dart';
import 'barber_screen.dart';
import 'booking_screen.dart';
import 'booking_form_screen.dart';
import '../services/auth_service.dart';
import '../models/barber.dart';
import '../models/booking.dart';
import '../services/barber_service.dart';
import '../services/booking_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const HomeScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  List<Barber> barbers = [];
  List<Booking> bookings = [];
  bool loadingBarber = true;
  bool loadingBooking = true;
  Timer? _timer;
  String? errorBarber;
  String? errorBooking;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchBarbers();
    _fetchBookings();
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      _fetchBarbers();
      _fetchBookings();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadUserName() async {
    final name = await AuthService.getUserName();
    setState(() {
      userName = name;
    });
  }

  void _fetchBarbers() async {
    setState(() { loadingBarber = true; errorBarber = null; });
    try {
      final data = await BarberService.fetchBarbers();
      setState(() {
        barbers = data;
        loadingBarber = false;
      });
    } catch (e) {
      print('Error fetchBarbers: $e');
      setState(() { loadingBarber = false; errorBarber = 'Gagal memuat data barber'; });
    }
  }

  void _fetchBookings() async {
    setState(() { loadingBooking = true; errorBooking = null; });
    try {
      final data = await BookingService.fetchBookings();
      setState(() {
        bookings = data;
        loadingBooking = false;
      });
    } catch (e) {
      print('Error fetchBookings: $e');
      setState(() { loadingBooking = false; errorBooking = 'Gagal memuat data booking'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, color: Colors.blue, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                userName != null ? 'Hai, $userName!' : 'Selamat datang!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue.shade900),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookingFormScreen()),
          );
        },
        icon: Icon(Icons.add, size: 28),
        label: Text('Booking Baru', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue.shade700,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
          children: [
            Text('Barber Online', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            SizedBox(height: 16),
            Container(
              height: 160,
              child: loadingBarber
                  ? Center(child: CircularProgressIndicator())
                  : errorBarber != null
                      ? Center(child: Text(errorBarber!, style: TextStyle(color: Colors.red)))
                      : barbers.isEmpty
                          ? Center(child: Text('Tidak ada barber online'))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: barbers.length,
                              separatorBuilder: (_, __) => SizedBox(width: 20),
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
                                }
                                return Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.blue.shade200, width: 2),
                                          ),
                                          child: ClipOval(
                                            child: barber.photo.isNotEmpty
                                                ? Image.network(
                                                    photoUrl,
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(Icons.person, size: 32, color: Colors.purple.shade100);
                                                    },
                                                  )
                                                : Icon(Icons.person, size: 32, color: Colors.purple.shade100),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(barber.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Flexible(child: Text(barber.specialty, style: TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        SizedBox(height: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: barber.status == 'Available' ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            barber.status,
                                            style: TextStyle(
                                              color: barber.status == 'Available' ? Colors.green.shade700 : Colors.red.shade700,
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
                            ),
            ),
            SizedBox(height: 36),
            Text('Booking Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            SizedBox(height: 16),
            loadingBooking
                ? Center(child: CircularProgressIndicator())
                : errorBooking != null
                    ? Center(child: Text(errorBooking!, style: TextStyle(color: Colors.red)))
                    : bookings.isEmpty
                        ? Center(child: Text('Belum ada booking'))
                        : Column(
                            children: bookings.map((booking) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.event_note, color: Colors.blue.shade700, size: 36),
                                  title: Text('Tanggal: ${booking.bookingDate}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Jam: ${booking.bookingTime}', style: TextStyle(fontSize: 14)),
                                      Text('Status: ${booking.status}', style: TextStyle(color: booking.status == 'pending' ? Colors.orange : Colors.green, fontSize: 14)),
                                      Text('Barber ID: ${booking.barberId}', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Rp${booking.amount}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 15)),
                                      SizedBox(height: 4),
                                      booking.paymentStatus == 'unpaid'
                                          ? Icon(Icons.close, color: Colors.red, size: 18)
                                          : Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
            SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lihat Semua Barber', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700, size: 18),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BarberScreen()));
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lihat Semua Booking', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700, size: 18),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 