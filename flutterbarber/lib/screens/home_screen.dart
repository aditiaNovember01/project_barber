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
  int _bookingCountThisMonth = 0;
  int _barberActiveCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchBarbers();
    _fetchBookings();
    // Hapus timer periodic agar tidak refresh otomatis terus
    // _timer = Timer.periodic(Duration(seconds: 10), (_) {
    //   _fetchBarbers();
    //   _fetchBookings();
    // });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Aman, meski _timer sudah tidak dipakai
    super.dispose();
  }

  void _loadUserName() async {
    final name = await AuthService.getUserName();
    setState(() {
      userName = name;
    });
  }

  Future<void> _fetchBarbers() async {
    setState(() { loadingBarber = true; errorBarber = null; });
    try {
      final data = await BarberService.fetchBarbers();
      print('DEBUG barbers: ' + data.map((b) => ' [33m${b.name} (${b.status}) [0m').join(', '));
      final activeCount = data.where((b) => b.status.toLowerCase() == 'active').length;
      setState(() {
        barbers = data;
        _barberActiveCount = activeCount;
        loadingBarber = false;
      });
    } catch (e) {
      print('Error fetchBarbers: $e');
      setState(() { loadingBarber = false; errorBarber = 'Gagal memuat data barber'; });
    }
    return;
  }

  Future<void> _fetchBookings() async {
    setState(() { loadingBooking = true; errorBooking = null; });
    try {
      final userId = await AuthService.getUserId();
      final data = await BookingService.fetchBookings(); // ambil semua booking
      final userBookings = data.where((b) => b.userId == userId).toList();
      setState(() {
        bookings = data;
        _bookingCountThisMonth = userBookings.length;
        loadingBooking = false;
      });
    } catch (e) {
      print('Error fetchBookings: $e');
      setState(() { loadingBooking = false; errorBooking = 'Gagal memuat data booking'; });
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookingFormScreen()),
          );
        },
        icon: Icon(Icons.add, size: 28, color: Colors.white),
        label: Text('Booking Baru', style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchBarbers(),
            _fetchBookings(),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
          // Header Card Profil
          Container(
            margin: EdgeInsets.fromLTRB(16, 36, 16, 18),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, color: Colors.blue, size: 40),
                    ),
                    SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName != null ? 'Hai, $userName!' : 'Selamat datang!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade900),
                          ),
                          SizedBox(height: 6),
                          Text('Selamat datang di FlutterBarber', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.red.shade400, size: 28),
                      onPressed: widget.onLogout,
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Banner Welcome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white, size: 44),
                    SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Booking barber kini lebih mudah dan cepat! Yuk, pilih barber favoritmu atau cek promo menarik.',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Statistik Singkat
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      child: Column(
                        children: [
                          Icon(Icons.event_available, color: Colors.blue.shade700, size: 36),
                          SizedBox(height: 8),
                          Text('Total Booking Saya', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          SizedBox(height: 2),
                          Text('$_bookingCountThisMonth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue.shade900)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      child: Column(
                        children: [
                          Icon(Icons.people, color: Colors.orange.shade400, size: 36),
                          SizedBox(height: 8),
                          Text('Barber Aktif', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          SizedBox(height: 2),
                          Text('$_barberActiveCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card Promo/Tips
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.yellow.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.orange.shade400, size: 30),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Promo Spesial! Booking 3x bulan ini, dapatkan potongan 20% untuk booking berikutnya.',
                        style: TextStyle(fontSize: 14, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tombol Aksi Besar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BarberScreen()));
                  },
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_rounded, color: Colors.white, size: 40),
                          SizedBox(width: 22),
                          Expanded(
                            child: Text(
                              'Lihat Barber',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
                  },
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.yellow.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade100,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_note_rounded, color: Colors.white, size: 40),
                          SizedBox(width: 22),
                          Expanded(
                            child: Text(
                              'Lihat Booking',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
} 