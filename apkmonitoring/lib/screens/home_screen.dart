import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TacticalWOPage extends StatefulWidget {
  const TacticalWOPage({super.key});

  @override
  _TacticalWOPageState createState() => _TacticalWOPageState();
}

class _TacticalWOPageState extends State<TacticalWOPage> {
  Map<String, List<Map<String, dynamic>>> categorizedWorkOrders = {
    'Common': [],
    'Boiler': [],
    'Turbin': [],
  };

  Map<String, int> statusCount = {
    'Close': 0,
    'WShutt': 0,
    'WMatt': 0,
    'Inprogress': 0,
    'Reschedule': 0,
  };

  String selectedFileName = 'Tidak ada file yang dipilih';
  bool isLoadingFile = false;
  bool isSyncingFirebase = false;
  final ImagePicker _picker = ImagePicker();
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadSavedData();
    _initializeEmptyRows();
    _loadFromFirebase();
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      // Handle anonymous user or create a default user ID
      _currentUserId = 'anonymous_user';
    }
  }

  void _initializeEmptyRows() {
    categorizedWorkOrders.forEach((key, value) {
      if (value.isEmpty) {
        value.add({
          'no': 1,
          'wo': '',
          'desc': '',
          'typeWO': '',
          'pic': '',
          'status': null,
          'photo': false,
          'photoPath': null,
          'photoData': null,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': _currentUserId ?? '',
          'jenis_wo': 'Tactical',
        });
      }
    });
  }

  // Load data from Firebase
  Future<void> _loadFromFirebase() async {
    if (_currentUserId == null) return;

    setState(() {
      isSyncingFirebase = true;
    });

    try {
      // Load tactical work orders
      final tacticalSnapshot = await _firestore
          .collection('tactical_work_orders')
          .doc('tactical')
          .get();

      if (tacticalSnapshot.exists) {
        final data = tacticalSnapshot.data() as Map<String, dynamic>;
        
        // Organize data by category
        Map<String, List<Map<String, dynamic>>> firebaseData = {
          'Common': [],
          'Boiler': [],
          'Turbin': [],
        };

        // Process each work order from Firebase
        data.forEach((key, value) {
          if (value is Map<String, dynamic> && value['category'] != null) {
            final category = value['category'] as String;
            if (firebaseData.containsKey(category)) {
              firebaseData[category]!.add(Map<String, dynamic>.from(value));
            }
          }
        });

        // Sort by 'no' field
        firebaseData.forEach((category, workOrders) {
          workOrders.sort((a, b) => (a['no'] ?? 0).compareTo(b['no'] ?? 0));
        });

        setState(() {
          categorizedWorkOrders = firebaseData;
        });

        _initializeEmptyRows();
        _recalculateStatusCount();
      }

      // Load status counts
      final statusSnapshot = await _firestore
          .collection('status_counts')
          .doc('stat_tactical')
          .get();

      if (statusSnapshot.exists) {
        final data = statusSnapshot.data() as Map<String, dynamic>;
        setState(() {
          statusCount = {
            'Close': data['close'] ?? 0,
            'WShutt': data['wshutt'] ?? 0,
            'WMatt': data['wmatt'] ?? 0,
            'Inprogress': data['inprogress'] ?? 0,
            'Reschedule': data['reschedule'] ?? 0,
          };
        });
      }

    } catch (e) {
      print('Error loading from Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading from Firebase: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        isSyncingFirebase = false;
      });
    }
  }

  // Save to Firebase
  Future<void> _saveToFirebase() async {
    if (_currentUserId == null) return;

    setState(() {
      isSyncingFirebase = true;
    });

    try {
      // Prepare tactical work orders data
      Map<String, dynamic> tacticalData = {};
      int counter = 0;

      categorizedWorkOrders.forEach((category, workOrders) {
        for (var wo in workOrders) {
          if (wo['wo'].toString().trim().isNotEmpty) {
            counter++;
            tacticalData['wo_$counter'] = {
              'category': category,
              'no': wo['no'],
              'wo': wo['wo'],
              'desc': wo['desc'],
              'typeWO': wo['typeWO'],
              'pic': wo['pic'],
              'status': wo['status'],
              'photo': wo['photo'],
              'photoPath': wo['photoPath'],
              'photoData': wo['photoData'],
              'timestamp': wo['timestamp'],
              'userId': _currentUserId,
              'jenis_wo': 'Tactical',
            };
          }
        }
      });

      // Save tactical work orders
      await _firestore
          .collection('tactical_work_orders')
          .doc('tactical')
          .set(tacticalData);

      // Save status counts
      await _firestore
          .collection('status_counts')
          .doc('stat_tactical')
          .set({
        'close': statusCount['Close'],
        'wshutt': statusCount['WShutt'],
        'wmatt': statusCount['WMatt'],
        'inprogress': statusCount['Inprogress'],
        'reschedule': statusCount['Reschedule'],
        'lastupdated': FieldValue.serverTimestamp(),
      });

      // Save completed work orders to history
      await _saveCompletedToHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil disinkronisasi ke Firebase'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error saving to Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving to Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSyncingFirebase = false;
      });
    }
  }

  // Save completed work orders to history
  Future<void> _saveCompletedToHistory() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();

      categorizedWorkOrders.forEach((category, workOrders) {
        for (var wo in workOrders) {
          if (wo['status'] == 'Close' && wo['wo'].toString().isNotEmpty) {
            final historyRef = _firestore
                .collection('work_order_history')
                .doc('wo_${wo['wo']}_${wo['timestamp']}');

            batch.set(historyRef, {
              'tanggal': wo['timestamp'],
              'wo': wo['wo'],
              'desc': wo['desc'],
              'typeWO': wo['typeWO'],
              'status': wo['status'],
              'jenis_wo': 'Tactical',
              'pic': wo['pic'],
              'category': category,
              'userId': _currentUserId,
              'photoData': wo['photoData'],
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      await batch.commit();
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  // Load data yang tersimpan dari SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('tactical_work_orders');
      final savedStatusCount = prefs.getString('tactical_status_count');

      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);
        setState(() {
          categorizedWorkOrders = decodedData.map(
            (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(
                value.map((item) => Map<String, dynamic>.from(item)),
              ),
            ),
          );
        });
        _recalculateStatusCount();
      }

      if (savedStatusCount != null) {
        final Map<String, dynamic> decodedStatusCount = json.decode(
          savedStatusCount,
        );
        setState(() {
          statusCount = decodedStatusCount.map(
            (key, value) => MapEntry(key, value as int),
          );
        });
      }
    } catch (e) {
      print('Error loading saved data: $e');
      _initializeEmptyRows();
    }
  }

  // Recalculate status count from existing data
  void _recalculateStatusCount() {
    Map<String, int> newStatusCount = {
      'Close': 0,
      'WShutt': 0,
      'WMatt': 0,
      'Inprogress': 0,
      'Reschedule': 0,
    };

    categorizedWorkOrders.forEach((category, workOrders) {
      for (var wo in workOrders) {
        if (wo['status'] != null && wo['wo'].toString().isNotEmpty) {
          String status = wo['status'];
          if (newStatusCount.containsKey(status)) {
            newStatusCount[status] = newStatusCount[status]! + 1;
          }
        }
      }
    });

    setState(() {
      statusCount = newStatusCount;
    });
  }


  Future<void> _saveData() async {
    try {
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'tactical_work_orders',
        json.encode(categorizedWorkOrders),
      );
      await prefs.setString(
        'tactical_status_count',
        json.encode(statusCount),
      );

      // Save to history
      await _saveToHistory();

      // Save to Firebase
      await _saveToFirebase();

    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // Simpan ke history untuk sinkronisasi
  Future<void> _saveToHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> historyList =
          prefs.getStringList('work_order_history') ?? [];

      categorizedWorkOrders.forEach((category, workOrders) {
        for (var wo in workOrders) {
          if (wo['status'] == 'Close' && wo['wo'].toString().isNotEmpty) {
            final historyItem = {
              'category': category,
              'workOrder': wo['wo'],
              'description': wo['desc'],
              'pic': wo['pic'],
              'typeWO': wo['typeWO'],
              'status': wo['status'],
              'hasPhoto': wo['photo'],
              'photoData': wo['photoData'],
              'timestamp': wo['timestamp'] ?? DateTime.now().toIso8601String(),
              'type': 'Tactical',
              'date': DateTime.parse(
                wo['timestamp'] ?? DateTime.now().toIso8601String(),
              ).toString().substring(0, 10),
            };

            bool exists = false;
            for (int i = 0; i < historyList.length; i++) {
              try {
                final decoded = json.decode(historyList[i]);
                if (decoded['workOrder'] == wo['wo'] &&
                    decoded['type'] == 'Tactical') {
                  historyList[i] = json.encode(historyItem);
                  exists = true;
                  break;
                }
              } catch (e) {
                print('Error decoding history item: $e');
              }
            }

            if (!exists) {
              historyList.add(json.encode(historyItem));
            }
          }
        }
      });

      await prefs.setStringList('work_order_history', historyList);
      print('Saved ${historyList.length} items to history');
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  Widget _buildPieChart() {
    final colors = {
      'Close': Colors.green,
      'WShutt': Colors.orange,
      'WMatt': Colors.yellow,
      'Inprogress': Colors.blue,
      'Reschedule': Colors.red,
    };

    final validEntries =
        statusCount.entries.where((entry) => entry.value > 0).toList();

    if (validEntries.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data status',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections:
            validEntries.map((entry) {
              final double value = entry.value.toDouble();
              return PieChartSectionData(
                color: colors[entry.key] ?? Colors.grey,
                value: value,
                title: '${entry.key}\n(${entry.value})',
                radius: 60,
                titleStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      isLoadingFile = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes != null) {
          await _readExcelFile(file.bytes!);
          setState(() {
            selectedFileName = file.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File Excel berhasil dimuat: ${file.name}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('File bytes is null');
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membaca file Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingFile = false;
      });
    }
  }

  Future<void> _readExcelFile(Uint8List bytes) async {
  try {
    final excel = ex.Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('File Excel kosong atau tidak valid');
    }

    setState(() {
      categorizedWorkOrders = {'Common': [], 'Boiler': [], 'Turbin': []};
      statusCount = {
        'Close': 0,
        'WShutt': 0,
        'WMatt': 0,
        'Inprogress': 0,
        'Reschedule': 0,
      };
    });

    // Ambil sheet pertama (Tactical sheet)
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('Sheet Excel kosong');
    }

    print('Reading Excel file with ${sheet.maxRows} rows');

    String currentCategory = ''; // Mulai tanpa kategori
    Map<String, int> categoryCounters = {
      'Common': 1,
      'Boiler': 1,  
      'Turbin': 1,
    };
    
    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];
      
      if (row.isEmpty) continue;

      // Gabungkan semua cell dalam satu baris untuk deteksi divisi
      String rowText = '';
      for (int j = 0; j < row.length && j < 10; j++) { // Batasi maksimal 10 kolom
        final cellValue = row[j]?.value?.toString().trim() ?? '';
        if (cellValue.isNotEmpty) {
          rowText += '$cellValue ';
        }
      }
      rowText = rowText.trim().toUpperCase();

      print('Row $i: $rowText'); // Debug print

      // Deteksi header divisi
      if (rowText.contains('DIVISI COMMON')) {
        currentCategory = 'Common';
        print('Found DIVISI COMMON at row $i');
        continue;
      } else if (rowText.contains('DIVISI BOILER')) {
        currentCategory = 'Boiler';
        print('Found DIVISI BOILER at row $i');
        continue;
      } else if (rowText.contains('DIVISI TURBIN')) {
        currentCategory = 'Turbin';
        print('Found DIVISI TURBIN at row $i');
        continue;
      }

      // Skip jika belum ada kategori yang terdeteksi
      if (currentCategory.isEmpty) continue;

      // Skip header row dengan kolom NO, WORK ORDER, etc.
      if (rowText.contains('NO') && rowText.contains('WORK ORDER')) {
        print('Skipping header row at $i');
        continue;
      }

      // Skip baris kosong atau baris yang tidak memiliki data WO
      if (row.length < 2) continue;

      // Coba ambil data dari berbagai posisi kolom karena formatnya tidak konsisten
      String no = '';
      String wo = '';
      String desc = '';
      String typeWO = '';
      String pic = '';
      String status = '';

      // Cari Work Order (biasanya dimulai dengan WO)
      int woColumnIndex = -1;
      for (int j = 0; j < row.length && j < 8; j++) {
        final cellValue = row[j]?.value?.toString().trim() ?? '';
        if (cellValue.toUpperCase().startsWith('WO') && cellValue.length > 2) {
          woColumnIndex = j;
          wo = cellValue;
          break;
        }
      }

      // Jika tidak ada WO, skip baris ini
      if (wo.isEmpty) continue;

      // Ambil nomor urut (biasanya sebelum WO atau bisa jadi angka di kolom pertama)
      if (woColumnIndex > 0) {
        no = row[woColumnIndex - 1]?.value?.toString().trim() ?? '';
        // Jika bukan angka, gunakan counter kategori
        if (!RegExp(r'^\d+$').hasMatch(no)) {
          no = categoryCounters[currentCategory].toString();
        }
      } else {
        no = categoryCounters[currentCategory].toString();
      }

      // Ambil deskripsi (biasanya setelah WO)
      if (woColumnIndex >= 0 && woColumnIndex + 1 < row.length) {
        desc = row[woColumnIndex + 1]?.value?.toString().trim() ?? '';
      }

      // Cari Type WO (PM, CM, PAM)
      for (int j = 0; j < row.length; j++) {
        final cellValue = row[j]?.value?.toString().trim().toUpperCase() ?? '';
        if (cellValue == 'PM' || cellValue == 'CM') {
          typeWO = cellValue;
          
          // PIC biasanya setelah Type WO
          if (j + 1 < row.length) {
            pic = row[j + 1]?.value?.toString().trim() ?? '';
          }
          
          // Status biasanya setelah PIC
          if (j + 2 < row.length) {
            final statusValue = row[j + 2]?.value?.toString().trim() ?? '';
            if (statusValue.isNotEmpty) {
              // Mapping status dari Excel ke format aplikasi
              switch (statusValue.toLowerCase()) {
                case 'close':
                  status = 'Close';
                  break;
                case 'wshut':
                case 'wshut mill':
                case 'wshut':
                  status = 'WShutt';
                  break;
                case 'wmatt':
                  status = 'WMatt';
                  break;
                case 'inprogress':
                case 'in progress':
                  status = 'Inprogress';
                  break;
                case 'reschedule':
                  status = 'Reschedule';
                  break;
              }
            }
          }
          break;
        }
      }

      // Jika tidak ada Type WO yang ditemukan, coba cari di seluruh baris
      if (typeWO.isEmpty) {
        for (int j = 0; j < row.length; j++) {
          final cellValue = row[j]?.value?.toString().trim() ?? '';
          if (cellValue.toUpperCase().contains('PM') || 
              cellValue.toUpperCase().contains('CM')) {
            if (cellValue.toUpperCase().startsWith('PM')) {
              typeWO = 'PM';
            } else if (cellValue.toUpperCase().startsWith('CM')) typeWO = 'CM';
            break;
          }
        }
      }

      // Jika masih tidak ada PIC, cari nama yang bukan status
      if (pic.isEmpty) {
        for (int j = 0; j < row.length; j++) {
          final cellValue = row[j]?.value?.toString().trim() ?? '';
          if (cellValue.isNotEmpty && 
              !cellValue.toUpperCase().startsWith('WO') &&
              !['PM', 'CM', 'CLOSE', 'WSHUT', 'WMATT', 'INPROGRESS', 'RESCHEDULE'].contains(cellValue.toUpperCase()) &&
              !RegExp(r'^\d+$').hasMatch(cellValue) &&
              cellValue.length > 2) {
            pic = cellValue;
            break;
          }
        }
      }

      // Hanya proses jika ada Work Order dan ini adalah Tactical WO (PM, CM, atau PAM)
      if (wo.isNotEmpty && (typeWO == 'PM' || typeWO == 'CM')) {
        
        // Buat entry baru
        final newEntry = {
          'no': int.tryParse(no) ?? categoryCounters[currentCategory]!,
          'wo': wo,
          'desc': desc.isNotEmpty ? desc : 'Deskripsi tidak tersedia',
          'typeWO': typeWO,
          'pic': pic.isNotEmpty ? pic : 'PIC tidak tersedia',
          'status': status.isNotEmpty ? status : null,
          'photo': false,
          'photoPath': null,
          'photoData': null,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': _currentUserId ?? '',
          'jenis_wo': 'Tactical',
        };

        setState(() {
          categorizedWorkOrders[currentCategory]!.add(newEntry);
          
          // Update status count jika ada status
          if (status.isNotEmpty && statusCount.containsKey(status)) {
            statusCount[status] = statusCount[status]! + 1;
          }
        });

        categoryCounters[currentCategory] = categoryCounters[currentCategory]! + 1;
        print('Added WO: $wo to category: $currentCategory with status: $status, PIC: $pic, Type: $typeWO');
      }
    }

    // Tambahkan baris kosong di akhir setiap kategori untuk input baru
    categorizedWorkOrders.forEach((key, value) {
      value.add({
        'no': value.length + 1,
        'wo': '',
        'desc': '',
        'typeWO': '', 
        'pic': '',
        'status': null,
        'photo': false,
        'photoPath': null,
        'photoData': null,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _currentUserId ?? '',
        'jenis_wo': 'Tactical',
      });
    });

    await _saveData();

    int totalItems = categorizedWorkOrders.values.fold(0, (sum, list) => sum + list.length - 1);
    print('Excel import completed. Total items: $totalItems');
    print('Common: ${categorizedWorkOrders['Common']!.length - 1} items');
    print('Boiler: ${categorizedWorkOrders['Boiler']!.length - 1} items');
    print('Turbin: ${categorizedWorkOrders['Turbin']!.length - 1} items');
    
  } catch (e) {
    print('Error reading Excel file: $e');
    throw Exception('Error reading Excel file: $e');
  }
}

  void _updateStatus(String kategori, int index, String? newStatus) async {
    final row = categorizedWorkOrders[kategori]![index];
    final oldStatus = row['status'];

    if (newStatus == 'Close') {
      if (row['wo'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Work Order tidak boleh kosong untuk status Close'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (row['photo'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload foto terlebih dahulu sebelum memilih status Close',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      if (oldStatus != null && statusCount.containsKey(oldStatus)) {
        statusCount[oldStatus] =
            (statusCount[oldStatus]! - 1).clamp(0, double.infinity).toInt();
      }

      if (newStatus != null && statusCount.containsKey(newStatus)) {
        statusCount[newStatus] = statusCount[newStatus]! + 1;
      }

      row['status'] = newStatus;
      row['timestamp'] = DateTime.now().toIso8601String();
    });

    await _saveData();
  }

  void _uploadPhoto(String kategori, int index) async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pilih Sumber Foto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        setState(() {
          categorizedWorkOrders[kategori]![index]['photo'] = true;
          categorizedWorkOrders[kategori]![index]['photoPath'] = image.path;
          categorizedWorkOrders[kategori]![index]['photoData'] = base64Image;
          categorizedWorkOrders[kategori]![index]['timestamp'] =
              DateTime.now().toIso8601String();
        });

        await _saveData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto berhasil diupload!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Lihat',
              onPressed: () => _showPhotoPreview(kategori, index),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhotoPreview(String kategori, int index) {
    final row = categorizedWorkOrders[kategori]![index];
    final String? photoData = row['photoData'];

    if (photoData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada foto untuk ditampilkan')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Foto Work Order: ${row['wo']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Image.memory(
                    base64Decode(photoData),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Tutup'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _uploadPhoto(kategori, index);
                      },
                      child: Text('Ganti Foto'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkAndAddNewRow(String kategori) async {
    final list = categorizedWorkOrders[kategori]!;

    if (list.isEmpty) return;

    final last = list.last;

    if (last['wo'].toString().trim().isNotEmpty &&
        last['desc'].toString().trim().isNotEmpty &&
        last['pic'].toString().trim().isNotEmpty) {
      setState(() {
        list.add({
          'no': list.length + 1,
          'wo': '',
          'desc': '',
          'typeWO': '',
          'pic': '',
          'status': null,
          'photo': false,
          'photoPath': null,
          'photoData': null,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': _currentUserId ?? '',
          'jenis_wo': 'Tactical',
        });
      });
      await _saveData();
    }
  }

  void _updateRowData(
    String kategori,
    int index,
    String field,
    String value,
  ) async {
    setState(() {
      categorizedWorkOrders[kategori]![index][field] = value;
      categorizedWorkOrders[kategori]![index]['timestamp'] =
          DateTime.now().toIso8601String();
    });

    _checkAndAddNewRow(kategori);
    await _saveData();
  }

  // Manual sync button
  Future<void> _manualSync() async {
    await _saveToFirebase();
  }

  Widget _buildTable(String kategori) {
    final list = categorizedWorkOrders[kategori]!;

    if (list.isEmpty || list.last['wo'].toString().trim().isNotEmpty) {
      list.add({
        'no': list.length + 1,
        'wo': '',
        'desc': '',
        'typeWO': '',
        'pic': '',
        'status': null,
        'photo': false,
        'photoPath': null,
        'photoData': null,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _currentUserId ?? '',
        'jenis_wo': 'Tactical',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.work, color: Colors.green.shade700),
              SizedBox(width: 8),
              Text(
                '$kategori (${list.where((item) => item['wo'].toString().trim().isNotEmpty).length} items)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.green.shade100),
            headingTextStyle: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
            dataRowHeight: 60,
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Work Order')),
              DataColumn(label: Text('Deskripsi')),
              DataColumn(label: Text('Type WO')),
              DataColumn(label: Text('PIC')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Foto')),
            ],
            rows: List.generate(list.length, (index) {
              final row = list[index];
              final isEmptyRow = row['wo'].toString().trim().isEmpty;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (isEmptyRow) return Colors.grey.shade50;
                  return null;
                }),
                cells: [
                  DataCell(Text('${row['no']}')),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: row['wo'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'WO-001',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged:
                            (val) => _updateRowData(kategori, index, 'wo', val),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        initialValue: row['desc'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Deskripsi pekerjaan...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        maxLines: 2,
                        onChanged:
                            (val) =>
                                _updateRowData(kategori, index, 'desc', val),
                      ),
                    ),
                  ),
                  DataCell(
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: row['typeWO'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type WO',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged:
                            (val) =>
                                _updateRowData(kategori, index, 'typeWO', val),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: row['pic'].toString(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'PIC',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        onChanged:
                            (val) => _updateRowData(kategori, index, 'pic', val),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: DropdownButton<String?>(
                        value: row['status'],
                        hint: Text(
                          'Pilih Status',
                          style: TextStyle(fontSize: 12),
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Pilih Status'),
                          ),
                          ...[
                            'Close',
                            'WShutt',
                            'WMatt',
                            'Inprogress',
                            'Reschedule',
                          ].map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          ),
                        ],
                        onChanged:
                            isEmptyRow
                                ? null
                                : (val) => _updateStatus(kategori, index, val),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap:
                                row['photo']
                                    ? () => _showPhotoPreview(kategori, index)
                                    : null,
                            child: Icon(
                              row['photo'] ? Icons.check_circle : Icons.cancel,
                              color: row['photo'] ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              row['photo'] ? Icons.photo : Icons.camera_alt,
                              size: 20,
                              color: row['photo'] ? Colors.green : Colors.grey,
                            ),
                            onPressed:
                                isEmptyRow
                                    ? null
                                    : () => _uploadPhoto(kategori, index),
                            tooltip:
                                row['photo']
                                    ? 'Lihat/Ganti Foto'
                                    : 'Upload Foto',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Tactical WO',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
         iconTheme: IconThemeData(color: Colors.green.shade700),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.green.shade700),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
        ],
      ),
      endDrawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // File Upload Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 48,
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Upload File Excel Pekerjaan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isLoadingFile ? null : _pickFile,
                    icon: isLoadingFile
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.file_upload),
                    label: Text(
                      isLoadingFile ? 'Loading...' : 'Pilih File Excel',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectedFileName,
                    style: TextStyle(
                      color: selectedFileName == 'Tidak ada file yang dipilih'
                          ? Colors.grey.shade600
                          : Colors.green.shade700,
                      fontWeight: selectedFileName != 'Tidak ada file yang dipilih'
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Tables
            _buildTable('Common'),
            _buildTable('Boiler'),
            _buildTable('Turbin'),

            // Pie Chart Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Status Work Orders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 300, child: _buildPieChart()),
                  SizedBox(height: 16),
                  // Status Summary
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: statusCount.entries.map((entry) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.key).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(entry.key),
                          ),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(entry.key),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Close':
        return Colors.green;
      case 'WShutt':
        return Colors.orange;
      case 'WMatt':
        return Colors.yellow.shade700;
      case 'Inprogress':
        return Colors.blue;
      case 'Reschedule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}