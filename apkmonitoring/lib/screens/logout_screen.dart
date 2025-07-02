import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Jika menggunakan Firebase Authentication
import 'login_screen.dart'; // Import halaman login

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logout')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Proses logout
            await FirebaseAuth.instance.signOut(); // Jika menggunakan Firebase

            // Redirect ke halaman login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          child: Text('Logout'),
        ),
      ),
    );
  }
}
