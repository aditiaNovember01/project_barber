import 'dart:io';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/barber_service.dart';
import '../models/barber.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class BookingFormScreen extends StatefulWidget {
  @override
  _BookingFormScreenState createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedBarberId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _amount;
  bool _loading = false;
  List<Barber> _barbers = [];
  String? _proofOfPaymentPath;
  // Tambahan untuk web
  Uint8List? _proofOfPaymentBytes;
  String? _proofOfPaymentName;
  int _bookingCountThisMonth = 0;
  bool _promoActive = false;
  bool _jamError = false;
  bool _barberError = false;
  bool _dateError = false;
  bool _amountError = false;

  @override
  void initState() {
    super.initState();
    _fetchBarbers();
    _checkPromo();
  }

  void _fetchBarbers() async {
    final barbers = await BarberService.fetchBarbers();
    setState(() {
      _barbers = barbers;
    });
  }

  void _checkPromo() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return;
    final allBookings = await BookingService.fetchBookings(userId: userId);
    final now = DateTime.now();
    final thisMonthBookings = allBookings.where((b) {
      final date = DateTime.tryParse(b.bookingDate);
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();
    setState(() {
      _bookingCountThisMonth = thisMonthBookings.length;
      _promoActive = _bookingCountThisMonth >= 3;
    });
  }

  void showErrorDialog(BuildContext context, String title, String message, {IconData icon = Icons.error, Color color = Colors.red, String buttonText = 'Tutup'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText, style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBarberId == null || _selectedDate == null || _selectedTime == null) {
      setState(() {
        _barberError = _selectedBarberId == null;
        _dateError = _selectedDate == null;
        _jamError = _selectedTime == null;
        _amountError = _amount == null || _amount!.isEmpty;
      });
      showErrorDialog(context, 'Data Belum Lengkap', 'Lengkapi semua data booking terlebih dahulu.', icon: Icons.info_outline, color: Colors.blue);
      return;
    }
    // Validasi status barber aktif
    final selectedBarber = _barbers.firstWhere((b) => b.id == _selectedBarberId, orElse: () => Barber(id: 0, name: '', photo: '', specialty: '', status: ''));
    if (selectedBarber.status.toLowerCase() != 'active') {
      showErrorDialog(context, 'Barber Tidak Aktif', 'Maaf, barber yang Anda pilih sedang tidak aktif dan tidak dapat menerima booking saat ini. Silakan pilih barber lain.', icon: Icons.block, color: Colors.red, buttonText: 'Pilih Barber Lain');
      return;
    }
    // Validasi upload bukti pembayaran
    if (kIsWeb) {
      if (_proofOfPaymentBytes == null || _proofOfPaymentName == null) {
        showErrorDialog(context, 'Bukti Pembayaran', 'Upload bukti pembayaran terlebih dahulu.', icon: Icons.info_outline, color: Colors.blue);
        return;
      }
    } else {
      if (_proofOfPaymentPath == null) {
        showErrorDialog(context, 'Bukti Pembayaran', 'Upload bukti pembayaran terlebih dahulu.', icon: Icons.info_outline, color: Colors.blue);
        return;
      }
    }
    setState(() { _loading = true; });
    final userId = await AuthService.getUserId();
    if (userId == null) {
      setState(() { _loading = false; });
      showErrorDialog(context, 'User Tidak Ditemukan', 'User tidak ditemukan. Silakan login ulang.', icon: Icons.error_outline, color: Colors.red);
      return;
    }
    // Ambil semua booking (tanpa filter userId)
    final allBookings = await BookingService.fetchBookings();
    final selectedDateStr = _selectedDate!.toIso8601String().split('T')[0];
    final selectedTime = Duration(hours: _selectedTime!.hour, minutes: _selectedTime!.minute);
    final conflict = allBookings.any((b) {
      if (b.bookingDate != selectedDateStr) return false;
      if (b.barberId != _selectedBarberId) return false;
      final parts = b.bookingTime.split(':');
      if (parts.length < 2) return false;
      final bHour = int.tryParse(parts[0]) ?? 0;
      final bMinute = int.tryParse(parts[1]) ?? 0;
      final bTime = Duration(hours: bHour, minutes: bMinute);
      return (selectedTime - bTime).inMinutes.abs() < 60;
    });
    if (conflict) {
      setState(() { _loading = false; _jamError = true; });
      showErrorDialog(context, 'Jadwal Tidak Tersedia', 'Barber sudah ada booking lain dalam rentang 1 jam pada tanggal & jam yang dipilih. Silakan pilih jam lain.', icon: Icons.error_outline, color: Colors.orange, buttonText: 'Pilih Jam Lain');
      return;
    } else {
      setState(() { _jamError = false; });
    }
    // Hitung amount dengan promo jika aktif
    double amountValue = double.tryParse(_amount ?? '0') ?? 0;
    if (_promoActive) {
      amountValue = (amountValue * 0.8).roundToDouble();
    }
    final bookingData = {
      'user_id': userId,
      'barber_id': _selectedBarberId,
      'booking_date': selectedDateStr,
      'booking_time': _selectedTime!.hour.toString().padLeft(2, '0') + ':' + _selectedTime!.minute.toString().padLeft(2, '0'),
      'status': 'pending',
      'amount': amountValue.toStringAsFixed(0),
      'payment_status': 'unpaid',
      'proof_of_payment': '',
    };
    Map<String, dynamic> result;
    if (kIsWeb) {
      result = await BookingService.createBooking(
        bookingData,
        fileBytes: _proofOfPaymentBytes,
        fileName: _proofOfPaymentName,
      );
    } else {
      result = await BookingService.createBooking(bookingData, filePath: _proofOfPaymentPath);
    }
    setState(() { _loading = false; });
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking berhasil!')));
      Navigator.pop(context);
    } else {
      String msg = result['message'] ?? 'Booking gagal! Cek koneksi atau data.';
      showErrorDialog(context, 'Booking Gagal', msg, icon: Icons.error_outline, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: Text('Buat Booking'), backgroundColor: Colors.blue.shade700),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available, size: 54, color: Colors.blue.shade700),
                    SizedBox(height: 18),
                    Text('Booking Baru', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    SizedBox(height: 32),
                    Divider(thickness: 1, color: Colors.blue.shade50),
                    SizedBox(height: 18),
                    DropdownButtonFormField<int>(
                      value: _selectedBarberId,
                      items: _barbers.isEmpty
                          ? []
                          : _barbers.map((barber) => DropdownMenuItem(
                              value: barber.id,
                              child: Text(barber.name),
                            )).toList(),
                      onChanged: (val) => setState(() => _selectedBarberId = val),
                      decoration: InputDecoration(
                        labelText: 'Pilih Barber',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      validator: (val) => val == null ? 'Pilih barber' : null,
                      disabledHint: _barbers.isEmpty ? Text('Barber belum tersedia') : null,
                    ),
                    SizedBox(height: 18),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: Colors.blue.shade50,
                      title: Text(_selectedDate == null ? 'Pilih Tanggal' : _selectedDate!.toLocal().toString().split(' ')[0], style: TextStyle(fontSize: 16)),
                      trailing: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                    SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: _jamError ? Colors.red.shade50 : Colors.blue.shade50,
                      title: Text(_selectedTime == null ? 'Pilih Jam' : _selectedTime!.format(context), style: TextStyle(fontSize: 16, color: _jamError ? Colors.red : null)),
                      trailing: Icon(Icons.access_time, color: _jamError ? Colors.red : Colors.blue.shade700),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() { _selectedTime = picked; _jamError = false; });
                      },
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Jumlah (Amount)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Isi jumlah' : null,
                      onChanged: (val) => _amount = val,
                    ),
                    SizedBox(height: 24),
                    Divider(thickness: 1, color: Colors.blue.shade50),
                    SizedBox(height: 18),
                    if (_promoActive)
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer, color: Colors.orange.shade400, size: 18),
                            SizedBox(width: 8),
                            Expanded(child: Text('Promo aktif! Diskon 20% untuk booking ke-${_bookingCountThisMonth + 1} bulan ini.', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13))),
                          ],
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _loading
                          ? null
                          : () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                              if (result != null) {
                                if (kIsWeb) {
                                  setState(() {
                                    _proofOfPaymentBytes = result.files.single.bytes;
                                    _proofOfPaymentName = result.files.single.name;
                                  });
                                  if (_proofOfPaymentBytes != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bukti pembayaran berhasil dipilih: ' + _proofOfPaymentName!)));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file.')));
                                  }
                                } else {
                                  if (result.files.single.path != null) {
                                    setState(() => _proofOfPaymentPath = result.files.single.path);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bukti pembayaran berhasil dipilih: ' + result.files.single.name)));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file.')));
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file.')));
                              }
                            },
                      child: kIsWeb
                          ? (_proofOfPaymentName == null
                              ? Text('Upload Bukti Pembayaran')
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    SizedBox(width: 8),
                                    Flexible(child: Text(_proofOfPaymentName!, overflow: TextOverflow.ellipsis)),
                                  ],
                                ))
                          : (_proofOfPaymentPath == null
                              ? Text('Upload Bukti Pembayaran')
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    SizedBox(width: 8),
                                    Flexible(child: Text(_proofOfPaymentPath!.split(Platform.pathSeparator).last, overflow: TextOverflow.ellipsis)),
                                  ],
                                )),
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text('Booking'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 