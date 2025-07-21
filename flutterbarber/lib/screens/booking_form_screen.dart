import 'dart:io';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/barber_service.dart';
import '../models/barber.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchBarbers();
  }

  void _fetchBarbers() async {
    final barbers = await BarberService.fetchBarbers();
    setState(() {
      _barbers = barbers;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBarberId == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lengkapi semua data booking!')));
      return;
    }
    // Validasi upload bukti pembayaran
    if (kIsWeb) {
      if (_proofOfPaymentBytes == null || _proofOfPaymentName == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload bukti pembayaran dulu!')));
        return;
      }
    } else {
      if (_proofOfPaymentPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload bukti pembayaran dulu!')));
        return;
      }
    }
    setState(() { _loading = true; });
    final bookingData = {
      'user_id': 1, // Ganti dengan user login jika ada
      'barber_id': _selectedBarberId,
      'booking_date': _selectedDate!.toIso8601String().split('T')[0],
      'booking_time': _selectedTime!.format(context),
      'status': 'pending',
      'amount': _amount ?? '0',
      'payment_status': 'unpaid',
      'proof_of_payment': '',
    };
    bool success = false;
    if (kIsWeb) {
      success = await BookingService.createBooking(
        bookingData,
        fileBytes: _proofOfPaymentBytes,
        fileName: _proofOfPaymentName,
      );
    } else {
      success = await BookingService.createBooking(bookingData, filePath: _proofOfPaymentPath);
    }
    setState(() { _loading = false; });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking berhasil!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking gagal! Cek koneksi atau data.')));
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
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available, size: 54, color: Colors.blue.shade700),
                    SizedBox(height: 18),
                    Text('Booking Baru', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    SizedBox(height: 36),
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
                      tileColor: Colors.blue.shade50,
                      title: Text(_selectedTime == null ? 'Pilih Jam' : _selectedTime!.format(context), style: TextStyle(fontSize: 16)),
                      trailing: Icon(Icons.access_time, color: Colors.blue.shade700),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _selectedTime = picked);
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
                    SizedBox(height: 28),
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
                    SizedBox(height: 20),
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