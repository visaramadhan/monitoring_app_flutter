import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'drawer.dart';
import '../widgets/scrollable_data_table.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AturProfilAnggotaPage extends StatefulWidget {
  const AturProfilAnggotaPage({super.key});

  @override
  State<AturProfilAnggotaPage> createState() => _AturProfilAnggotaPageState();
}

class _AturProfilAnggotaPageState extends State<AturProfilAnggotaPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> anggotaList = [];
  UserModel? currentUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadAnggotaFromFirestore();
  }

  Future<void> _loadCurrentUser() async {
    currentUser = await _authService.getCurrentUserData();
    setState(() {});
  }

  String generateRandomPassword(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  bool _isEmailExist(String email) {
    return anggotaList.any(
      (anggota) => anggota['email'].toLowerCase() == email.toLowerCase(),
    );
  }

  Future<void> _loadAnggotaFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> tempList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] ?? '';
        
        // Skip supervisor dan admin dari pemeringkatan kinerja
        if (role.toLowerCase() == 'supervisor' || role.toLowerCase() == 'admin') {
          continue;
        }
        
        final username = (data['username'] ?? data['email']) ?? 'unknown';
        Map<String, dynamic> kinerjaData = await _hitungKinerja(doc.id);

        tempList.add({
          'uid': doc.id,
          'email': data['email'] ?? '',
          'username': username,
          'role': role,
          'kinerjaPercentage': kinerjaData['percentage'],
          'totalTactical': kinerjaData['totalTactical'],
          'totalNontactical': kinerjaData['totalNontactical'],
          'closeTactical': kinerjaData['closeTactical'],
          'closeNontactical': kinerjaData['closeNontactical'],
          'incompleteTasks': kinerjaData['incompleteTasks'],
        });
      }

      // Sort berdasarkan username untuk tampilan utama
      tempList.sort(
        (a, b) => a['username'].toString().toLowerCase().compareTo(
          b['username'].toString().toLowerCase(),
        ),
      );

      // Hitung peringkat berdasarkan kinerja
      List<Map<String, dynamic>> sortedByKinerja = [...tempList];
      sortedByKinerja.sort(
        (a, b) => b['kinerjaPercentage'].compareTo(a['kinerjaPercentage']),
      );
      
      // Assign peringkat
      for (int i = 0; i < sortedByKinerja.length; i++) {
        sortedByKinerja[i]['peringkat'] = i + 1;
      }

      // Update peringkat di tempList
      for (var anggota in tempList) {
        final match = sortedByKinerja.firstWhere(
          (x) => x['uid'] == anggota['uid'],
        );
        anggota['peringkat'] = match['peringkat'];
      }

      setState(() {
        anggotaList = tempList;
      });
    } catch (e) {
      print('Gagal ambil data anggota: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data anggota: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _hitungKinerja(String uid) async {
    try {
      // Load tactical work orders
      final tacticalSnapshot = await FirebaseFirestore.instance
          .collection('tactical_work_orders')
          .where('userId', isEqualTo: uid)
          .get();
      
      // Load non-tactical work orders
      final nontacticalSnapshot = await FirebaseFirestore.instance
          .collection('nontactical_work_order')
          .where('userId', isEqualTo: uid)
          .get();

      int totalTactical = tacticalSnapshot.docs.length;
      int totalNontactical = nontacticalSnapshot.docs.length;
      
      int closeTactical = tacticalSnapshot.docs
          .where((doc) => doc.data()['status']?.toLowerCase() == 'close')
          .length;
      
      int closeNontactical = nontacticalSnapshot.docs
          .where((doc) => doc.data()['status']?.toLowerCase() == 'close')
          .length;
      
      int totalClose = closeTactical + closeNontactical;
      int totalTugas = totalTactical + totalNontactical;
      double percentage = totalTugas > 0 ? (totalClose / totalTugas) * 100 : 0.0;

      // Get incomplete tasks details
      List<Map<String, dynamic>> incompleteTasks = [];
      
      // Add incomplete tactical tasks
      for (var doc in tacticalSnapshot.docs) {
        final data = doc.data();
        if (data['status']?.toLowerCase() != 'close') {
          incompleteTasks.add({
            'id': doc.id,
            'title': data['wo'] ?? 'Tactical Task',
            'status': data['status'] ?? 'open',
            'type': 'Tactical',
            'description': data['desc'] ?? '',
            'category': data['category'] ?? '',
            'pic': data['pic'] ?? '',
            'no': data['no'] ?? 0,
            'timestamp': data['timestamp'] ?? '',
          });
        }
      }
      
      // Add incomplete nontactical tasks
      for (var doc in nontacticalSnapshot.docs) {
        final data = doc.data();
        if (data['status']?.toLowerCase() != 'close') {
          incompleteTasks.add({
            'id': doc.id,
            'title': data['wo'] ?? 'Non-Tactical Task',
            'status': data['status'] ?? 'open',
            'type': 'Non-Tactical',
            'description': data['desc'] ?? '',
            'category': data['category'] ?? '',
            'pic': data['pic'] ?? '',
            'no': data['no'] ?? 0,
            'timestamp': data['timestamp'] ?? '',
          });
        }
      }

      return {
        'percentage': percentage,
        'totalTactical': totalTactical,
        'totalNontactical': totalNontactical,
        'closeTactical': closeTactical,
        'closeNontactical': closeNontactical,
        'incompleteTasks': incompleteTasks,
      };
    } catch (e) {
      print('Error menghitung kinerja untuk UID $uid: $e');
      return {
        'percentage': 0.0,
        'totalTactical': 0,
        'totalNontactical': 0,
        'closeTactical': 0,
        'closeNontactical': 0,
        'incompleteTasks': <Map<String, dynamic>>[],
      };
    }
  }

  void _showTaskDetails(String username, List<Map<String, dynamic>> incompleteTasks, 
      double kinerjaPercentage, Map<String, dynamic> anggotaData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Kinerja - $username'),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistik kinerja
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Kinerja',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Persentase:', style: TextStyle(fontSize: 12)),
                          Text(
                            '${kinerjaPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kinerjaPercentage >= 80 ? Colors.green : 
                                     kinerjaPercentage >= 60 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Peringkat:', style: TextStyle(fontSize: 12)),
                          Text(
                            '#${anggotaData['peringkat']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: anggotaData['peringkat'] == 1 ? Colors.amber.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Tugas:', style: TextStyle(fontSize: 12)),
                          Text('${anggotaData['totalTactical'] + anggotaData['totalNontactical']}', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Selesai:', style: TextStyle(fontSize: 12)),
                          Text('${anggotaData['closeTactical'] + anggotaData['closeNontactical']}', style: TextStyle(fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Tugas yang belum selesai
                if (incompleteTasks.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Semua tugas telah diselesaikan! 🎉',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Icon(Icons.assignment_late, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tugas Belum Selesai (${incompleteTasks.length}):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: incompleteTasks.length,
                      itemBuilder: (context, index) {
                        final task = incompleteTasks[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: task['type'] == 'Tactical' 
                                            ? Colors.blue.shade100 
                                            : Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        task['type'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: task['type'] == 'Tactical' 
                                              ? Colors.blue.shade700 
                                              : Colors.purple.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (task['no'] != null && task['no'] != 0) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'No: ${task['no']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: task['status']?.toLowerCase() == 'open' 
                                            ? Colors.orange.shade100 
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        task['status'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: task['status']?.toLowerCase() == 'open' 
                                              ? Colors.orange.shade700 
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (task['category'] != null && task['category'].isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'Kategori: ${task['category']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (task['pic'] != null && task['pic'].isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'PIC: ${task['pic']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (task['description'] != null && task['description'].isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    task['description'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _buatAkunBaru() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String username = _usernameController.text.trim();
      String role = 'karyawan';

      if (_isEmailExist(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email "$email" sudah terdaftar!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        String tempPassword = generateRandomPassword(8);
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email,
              password: tempPassword,
            );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': email,
              'username': username,
              'role': role,
              'createdAt': Timestamp.now(),
            });

        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        _emailController.clear();
        _usernameController.clear();
        _loadAnggotaFromFirestore();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akun "$username" berhasil dibuat! Link reset password telah dikirim ke $email',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat akun: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _resetPassword(String email, String username) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link reset password dikirim ke $email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim reset password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _hapusAkun(String uid, String username) async {
    // Konfirmasi sebelum menghapus
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus akun "$username"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        _loadAnggotaFromFirestore();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun $username berhasil dihapus'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus akun: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if current user is admin or supervisor
    bool canManageUsers = currentUser?.isAdmin == true || currentUser?.isSupervisor == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Profil Anggota'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      endDrawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (canManageUsers) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email Anggota',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Username Anggota',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username wajib diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Username minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _buatAkunBaru,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text('Buat Akun Karyawan'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            if (anggotaList.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.leaderboard, color: Colors.green.shade700),
                  SizedBox(width: 8),
                  Text(
                    'Daftar Karyawan & Pemeringkatan Kinerja',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
            
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : anggotaList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada karyawan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (canManageUsers) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Tambahkan karyawan menggunakan form di atas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ScrollableDataTable(
                          headingRowColor: WidgetStateProperty.all(Color(0xFF4CAF50)),
                          headingTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          dataRowHeight: 72,
                          columnSpacing: 12,
                          showCheckboxColumn: false,
                          columns: [
                            DataColumn(label: Text('No.')),
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Kinerja (%)')),
                            DataColumn(label: Text('Peringkat')),
                            if (canManageUsers) ...[
                              DataColumn(label: Text('Reset Password')),
                              DataColumn(label: Text('Hapus Akun')),
                            ],
                          ],
                          rows: List.generate(anggotaList.length, (index) {
                            final anggota = anggotaList[index];
                            final kinerjaPercentage = anggota['kinerjaPercentage'];
                            final incompleteTasks = anggota['incompleteTasks'] as List<Map<String, dynamic>>;
                            
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        anggota['username'],
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      if (anggota['role'] != null && anggota['role'].isNotEmpty)
                                        Text(
                                          anggota['role'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  InkWell(
                                    onTap: () => _showTaskDetails(
                                      anggota['username'],
                                      incompleteTasks,
                                      kinerjaPercentage,
                                      anggota,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kinerjaPercentage >= 80 
                                            ? Colors.green.shade100
                                            : kinerjaPercentage >= 60
                                                ? Colors.orange.shade100
                                                : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: kinerjaPercentage >= 80 
                                              ? Colors.green
                                              : kinerjaPercentage >= 60
                                                  ? Colors.orange
                                                  : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${kinerjaPercentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: kinerjaPercentage >= 80 
                                                  ? Colors.green.shade700
                                                  : kinerjaPercentage >= 60
                                                      ? Colors.orange.shade700
                                                      : Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.info_outline,
                                            size: 14,
                                            color: kinerjaPercentage >= 80 
                                                ? Colors.green.shade700
                                                : kinerjaPercentage >= 60
                                                    ? Colors.orange.shade700
                                                    : Colors.red.shade700,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: anggota['peringkat'] == 1 
                                          ? Colors.amber.shade100
                                          : anggota['peringkat'] <= 3
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: anggota['peringkat'] == 1 
                                            ? Colors.amber.shade300
                                            : anggota['peringkat'] <= 3
                                                ? Colors.blue.shade300
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (anggota['peringkat'] == 1)
                                          Icon(
                                            Icons.emoji_events,
                                            size: 14,
                                            color: Colors.amber.shade700,
                                          ),
                                        if (anggota['peringkat'] == 1)
                                          SizedBox(width: 4),
                                        Text(
                                          '#${anggota['peringkat']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: anggota['peringkat'] == 1 
                                                ? Colors.amber.shade700
                                                : anggota['peringkat'] <= 3
                                                    ? Colors.blue.shade700
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (canManageUsers) ...[
                                  DataCell(
                                    ElevatedButton.icon(
                                      onPressed: () => _resetPassword(
                                        anggota['email'],
                                        anggota['username'],
                                      ),
                                      icon: Icon(Icons.lock_reset, size: 16),
                                      label: Text(
                                        'Reset',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size(0, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ElevatedButton.icon(
                                      onPressed: () => _hapusAkun(
                                        anggota['uid'],
                                        anggota['username'],
                                      ),
                                      icon: Icon(Icons.delete, size: 16),
                                      label: Text(
                                        'Hapus',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size(0, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}