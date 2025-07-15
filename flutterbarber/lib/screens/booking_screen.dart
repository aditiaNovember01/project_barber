import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Future<List<Booking>> futureBookings;

  @override
  void initState() {
    super.initState();
    futureBookings = BookingService.fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: Text('Daftar Booking'), backgroundColor: Colors.blue.shade700),
      body: FutureBuilder<List<Booking>>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data booking'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada data booking'));
          }
          final bookings = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
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
            },
          );
        },
      ),
    );
  }
} 