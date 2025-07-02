import 'package:apkmonitoring/screens/history_screen.dart';
import 'package:apkmonitoring/screens/logout_screen.dart';
import 'package:apkmonitoring/screens/pengambilan_screen.dart';
import 'package:apkmonitoring/screens/permintaan_screen.dart';
import 'package:apkmonitoring/screens/profilanggota_screen.dart';
import 'package:apkmonitoring/screens/ubahpassword_screen.dart';
import 'package:flutter/material.dart';
import 'package:apkmonitoring/screens/home_screen.dart'; // Import TacticalWOPage
import 'nontactical_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            title: Text('Tactical WO'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TacticalWOPage()),
              );
            },
          ),
          ListTile(
            title: Text('Non-Tactical WO'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NonTacticalWOPage()),
              );
            },
          ),
          ListTile(
            title: Text('Pengambilan Barang'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PengambilanPage()),
              );
            },
          ),
          ListTile(
            title: Text('Permintaan Barang'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PermintaanPage()),
              );
            },
          ),
          ListTile(
            title: Text('History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage()),
              );
            },
          ),
          ListTile(
            title: Text('Pengaturan Anggota'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AturProfilAnggotaPage(),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Atur Password'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UbahPasswordPage()),
              );
            },
          ),
          ListTile(
            title: Text('Logout'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogoutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}