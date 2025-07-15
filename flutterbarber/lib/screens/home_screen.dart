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
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                userName != null ? 'Hai, $userName!' : 'Selamat datang!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue.shade900),
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
        icon: Icon(Icons.add),
        label: Text('Booking Baru'),
        backgroundColor: Colors.blue.shade700,
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
            Text('Barber Online', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            SizedBox(height: 12),
            Container(
              height: 140,
              child: loadingBarber
                  ? Center(child: CircularProgressIndicator())
                  : errorBarber != null
                      ? Center(child: Text(errorBarber!, style: TextStyle(color: Colors.red)))
                      : barbers.isEmpty
                          ? Center(child: Text('Tidak ada barber online'))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: barbers.length,
                              separatorBuilder: (_, __) => SizedBox(width: 16),
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
                                print('Photo URL: $photoUrl');
                                return Container(
                                  width: 130,
                                  height: 180,
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          photoUrl.isNotEmpty
                                              ? CircleAvatar(
                                                  backgroundImage: NetworkImage(photoUrl),
                                                  radius: 28,
                                                  backgroundColor: Colors.purple.shade50,
                                                )
                                              : CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor: Colors.purple.shade50,
                                                  child: Icon(Icons.person, size: 32, color: Colors.purple.shade100),
                                                ),
                                          SizedBox(height: 8),
                                          Text(barber.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                          Flexible(child: Text(barber.specialty, style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1)),
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
                                  ),
                                );
                              },
                            ),
            ),
            SizedBox(height: 32),
            Text('Booking Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            SizedBox(height: 12),
            loadingBooking
                ? Center(child: CircularProgressIndicator())
                : errorBooking != null
                    ? Center(child: Text(errorBooking!, style: TextStyle(color: Colors.red)))
                    : bookings.isEmpty
                        ? Center(child: Text('Belum ada booking'))
                        : Column(
                            children: bookings.map((booking) {
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                                margin: EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  leading: Icon(Icons.event_note, color: Colors.blue.shade700, size: 36),
                                  title: Text('Tanggal: ${booking.bookingDate}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Jam: ${booking.bookingTime}'),
                                      Text('Status: ${booking.status}', style: TextStyle(color: booking.status == 'pending' ? Colors.orange : Colors.green)),
                                      Text('Barber ID: ${booking.barberId}'),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Rp${booking.amount}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
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
            SizedBox(height: 32),
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