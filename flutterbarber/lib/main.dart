import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Barber',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginWrapper(),
    );
  }
}

class LoginWrapper extends StatefulWidget {
  @override
  _LoginWrapperState createState() => _LoginWrapperState();
}

class _LoginWrapperState extends State<LoginWrapper> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      _loggedIn = loggedIn;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _loggedIn = true;
    });
  }

  void _onLogout() async {
    await AuthService.logout();
    setState(() {
      _loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loggedIn!) {
      return HomeScreen(onLogout: _onLogout);
    } else {
      return LoginScreen();
    }
  }
}
