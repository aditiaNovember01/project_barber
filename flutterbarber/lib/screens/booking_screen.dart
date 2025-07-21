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
            padding: EdgeInsets.all(18),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => SizedBox(height: 22),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 22),
                  leading: Icon(Icons.event_note, color: Colors.blue.shade700, size: 38),
                  title: Text('Tanggal: ${booking.bookingDate}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam: ${booking.bookingTime}', style: TextStyle(fontSize: 15)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.status == 'pending' ? Colors.orange.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              booking.status,
                              style: TextStyle(
                                color: booking.status == 'pending' ? Colors.orange.shade700 : Colors.green.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('Barber ID: ${booking.barberId}', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rp${booking.amount}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 16)),
                      SizedBox(height: 6),
                      booking.paymentStatus == 'unpaid'
                          ? Icon(Icons.close, color: Colors.red, size: 20)
                          : Icon(Icons.check_circle, color: Colors.green, size: 20),
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