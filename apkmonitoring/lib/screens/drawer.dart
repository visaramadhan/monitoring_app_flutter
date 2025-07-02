import 'package:apkmonitoring/screens/history_screen.dart';
import 'package:apkmonitoring/screens/logout_screen.dart';
import 'package:apkmonitoring/screens/pengambilan_screen.dart';
import 'package:apkmonitoring/screens/permintaan_screen.dart';
import 'package:apkmonitoring/screens/profilanggota_screen.dart';
import 'package:apkmonitoring/screens/ubahpassword_screen.dart';
import 'package:flutter/material.dart';
import 'package:apkmonitoring/screens/home_screen.dart';
import 'nontactical_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/role_based_widget.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green.shade700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  currentUser?.username ?? 'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser?.role.toUpperCase() ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Work Order Management
          ListTile(
            leading: Icon(Icons.work, color: Colors.green.shade700),
            title: Text('Tactical WO'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TacticalWOPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.work_outline, color: Colors.green.shade700),
            title: Text('Non-Tactical WO'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NonTacticalWOPage()),
              );
            },
          ),
          
          Divider(),
          
          // Inventory Management
          ListTile(
            leading: Icon(Icons.inventory, color: Colors.blue.shade700),
            title: Text('Pengambilan Barang'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PengambilanPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.request_page, color: Colors.blue.shade700),
            title: Text('Permintaan Barang'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PermintaanPage()),
              );
            },
          ),
          
          Divider(),
          
          // Reports and History
          ListTile(
            leading: Icon(Icons.history, color: Colors.orange.shade700),
            title: Text('History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage()),
              );
            },
          ),
          
          // Admin/Supervisor only features
          RoleBasedWidget(
            user: currentUser,
            adminWidget: Column(
              children: [
                Divider(),
                ListTile(
                  leading: Icon(Icons.admin_panel_settings, color: Colors.red.shade700),
                  title: Text('Pengaturan Anggota'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AturProfilAnggotaPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            supervisorWidget: Column(
              children: [
                Divider(),
                ListTile(
                  leading: Icon(Icons.supervisor_account, color: Colors.purple.shade700),
                  title: Text('Pengaturan Anggota'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AturProfilAnggotaPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Divider(),
          
          // Settings
          ListTile(
            leading: Icon(Icons.lock, color: Colors.grey.shade700),
            title: Text('Atur Password'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UbahPasswordPage()),
              );
            },
          ),
          
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
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