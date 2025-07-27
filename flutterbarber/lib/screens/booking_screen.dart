import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../services/barber_service.dart';
import '../models/barber.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Future<List<Booking>>? futureBookings;
  List<Barber> _barbers = [];

  @override
  void initState() {
    super.initState();
    _loadBarbersAndBookings();
  }

  void _loadBarbersAndBookings() async {
    final userId = await AuthService.getUserId();
    final barbers = await BarberService.fetchBarbers();
    setState(() {
      _barbers = barbers;
      futureBookings = BookingService.fetchBookings(userId: userId);
    });
  }

  String _getBarberName(int barberId) {
    final barber = _barbers.firstWhere((b) => b.id == barberId, orElse: () => Barber(id: 0, name: '-', photo: '', specialty: '', status: ''));
    return barber.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: Text('Daftar Booking'), backgroundColor: Colors.blue.shade700),
      body: FutureBuilder<List<Booking>>(
        future: futureBookings,
        builder: (context, snapshot) {
          if (futureBookings == null || snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data booking'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.blue.shade100, size: 64),
                  SizedBox(height: 16),
                  Text('Belum ada riwayat booking', style: TextStyle(fontSize: 18, color: Colors.blue.shade300, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          final bookings = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.all(18),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => SizedBox(height: 22),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          Icon(Icons.event_note, color: Colors.blue.shade700, size: 28),
                          SizedBox(width: 10),
                          Text('Detail Booking'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue.shade300, size: 18),
                              SizedBox(width: 6),
                              Text(booking.bookingDate, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blue.shade300, size: 18),
                              SizedBox(width: 6),
                              Text(booking.bookingTime),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue.shade300, size: 18),
                              SizedBox(width: 6),
                              Text('Barber: ${_getBarberName(booking.barberId)}'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.green.shade700, size: 18),
                              SizedBox(width: 6),
                              Text('Rp${booking.amount}', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: booking.status == 'pending' ? Colors.orange.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      booking.status == 'pending' ? Icons.hourglass_empty : Icons.check_circle,
                                      color: booking.status == 'pending' ? Colors.orange : Colors.green,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      booking.status,
                                      style: TextStyle(
                                        color: booking.status == 'pending' ? Colors.orange.shade700 : Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: booking.paymentStatus == 'unpaid' ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      booking.paymentStatus == 'unpaid' ? Icons.close : Icons.check_circle,
                                      color: booking.paymentStatus == 'unpaid' ? Colors.red : Colors.green,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      booking.paymentStatus == 'unpaid' ? 'Belum Bayar' : 'Lunas',
                                      style: TextStyle(
                                        color: booking.paymentStatus == 'unpaid' ? Colors.red.shade700 : Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Tutup', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          radius: 28,
                          child: Icon(Icons.event_note, color: Colors.blue.shade700, size: 32),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue.shade300, size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      booking.bookingDate,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.access_time, color: Colors.blue.shade300, size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      booking.bookingTime,
                                      style: TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: booking.status == 'pending' ? Colors.orange.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      booking.status == 'pending' ? Icons.hourglass_empty : Icons.check_circle,
                                      color: booking.status == 'pending' ? Colors.orange : Colors.green,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      booking.status,
                                      style: TextStyle(
                                        color: booking.status == 'pending' ? Colors.orange.shade700 : Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Rp${booking.amount}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
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