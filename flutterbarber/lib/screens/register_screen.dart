import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _password;
  String? _phone;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    final result = await AuthService.registerWithMessage(_name!, _email!, _password!, phone: _phone);
    setState(() { _loading = false; });
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registrasi berhasil! Silakan login.')));
      Navigator.pop(context); // Kembali ke login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Registrasi gagal!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
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
                    Icon(Icons.person_add, size: 54, color: Colors.blue.shade700),
                    SizedBox(height: 18),
                    Text('Register', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    SizedBox(height: 36),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Masukkan nama' : null,
                      onChanged: (val) => _name = val,
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || val.isEmpty ? 'Masukkan email' : null,
                      onChanged: (val) => _email = val,
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      obscureText: true,
                      validator: (val) => val == null || val.isEmpty ? 'Masukkan password' : null,
                      onChanged: (val) => _password = val,
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'No. HP (opsional)',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => _phone = val,
                    ),
                    SizedBox(height: 28),
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
                            : Text('Register'),
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