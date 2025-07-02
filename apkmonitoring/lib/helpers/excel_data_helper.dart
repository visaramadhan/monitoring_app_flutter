import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExcelDataHelper {
  // Fungsi untuk menyimpan data Excel ke SharedPreferences
  static Future<void> saveWorkOrderData(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert data ke JSON string
      String jsonData = json.encode(data);
      
      // Simpan ke SharedPreferences
      await prefs.setString('work_order_data', jsonData);
      
      print('✅ Data berhasil disimpan: ${data.length} records');
      
      // Debug: Print sample data
      if (data.isNotEmpty) {
        print('Sample data: ${data.first}');
      }
    } catch (e) {
      print('❌ Error saving data: $e');
    }
  }
  
  // Fungsi untuk menambahkan data baru ke data yang sudah ada
  static Future<void> addWorkOrderData(List<Map<String, dynamic>> newData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil data yang sudah ada
      List<Map<String, dynamic>> existingData = [];
      String? storedData = prefs.getString('work_order_data');
      
      if (storedData != null) {
        List<dynamic> decodedData = json.decode(storedData);
        existingData = decodedData.cast<Map<String, dynamic>>();
        print('📂 Existing data: ${existingData.length} records');
      }
      
      // Tambahkan data baru
      existingData.addAll(newData);
      print('➕ Adding ${newData.length} new records');
      
      // Simpan kembali
      await saveWorkOrderData(existingData);
    } catch (e) {
      print('❌ Error adding data: $e');
    }
  }
  
  // Fungsi untuk mengambil semua data
  static Future<List<Map<String, dynamic>>> getWorkOrderData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedData = prefs.getString('work_order_data');
      
      if (storedData != null) {
        List<dynamic> decodedData = json.decode(storedData);
        List<Map<String, dynamic>> result = decodedData.cast<Map<String, dynamic>>();
        print('📖 Retrieved ${result.length} records from storage');
        return result;
      }
      
      print('📖 No data found in storage');
      return [];
    } catch (e) {
      print('❌ Error getting data: $e');
      return [];
    }
  }
  
  // Fungsi untuk menghapus semua data
  static Future<void> clearWorkOrderData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('work_order_data');
      print('🗑️ All data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
  
  // Helper function untuk format tanggal
  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    
    String dateStr = dateValue.toString().trim();
    if (dateStr.isEmpty) return '';
    
    try {
      // Coba parse berbagai format tanggal
      DateTime date;
      
      if (dateStr.contains('/')) {
        // Format MM/DD/YYYY atau DD/MM/YYYY
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          
          // Handle 2-digit year
          if (year < 100) {
            year += (year < 50) ? 2000 : 1900;
          }
          
          date = DateTime(year, month, day);
        } else {
          return '';
        }
      } else if (dateStr.contains('-')) {
        // Format YYYY-MM-DD atau DD-MM-YYYY
        date = DateTime.parse(dateStr);
      } else {
        // Try to parse as is
        date = DateTime.parse(dateStr);
      }
      
      // Return in YYYY-MM-DD format
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
    } catch (e) {
      print('⚠️ Invalid date format: $dateStr - $e');
      return '';
    }
  }
  
  // Helper function untuk clean string
  static String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
  
  // Helper function untuk determine work order type
  static String _determineWOType(String workOrder, String description) {
    String combined = '${workOrder.toLowerCase()} ${description.toLowerCase()}';
    
    if (combined.contains('tactical') || combined.contains('tac')) {
      return 'Tactical';
    } else if (combined.contains('preventive') || combined.contains('pm')) {
      return 'Preventive';
    } else if (combined.contains('corrective') || combined.contains('cm')) {
      return 'Corrective';
    } else {
      return 'Non-Tactical';
    }
  }
  
  // Fungsi utama untuk memproses data Excel dengan debugging
  // Expected Excel structure: No | Work Order | Deskripsi | PIC | Status
  static Future<void> processExcelData(List<List<dynamic>> excelRows) async {
    try {
      print('🔄 Processing Excel data...');
      print('📊 Total rows: ${excelRows.length}');
      
      if (excelRows.isEmpty) {
        print('❌ No data to process');
        return;
      }
      
      // Print header for debugging
      if (excelRows.isNotEmpty) {
        print('📋 Header row: ${excelRows[0]}');
      }
      
      List<Map<String, dynamic>> workOrderData = [];
      int validRows = 0;
      int invalidRows = 0;
      
      // Skip header row (row 0) and process data rows
      for (int i = 1; i < excelRows.length; i++) {
        var row = excelRows[i];
        
        print('🔍 Processing row $i: $row');
        
        // Pastikan row memiliki data yang cukup (minimal 5 kolom: No, WO, Desc, PIC, Status)
        if (row.length >= 5) {
          String no = _cleanString(row[0]);
          String workOrder = _cleanString(row[1]);
          String deskripsi = _cleanString(row[2]);
          String pic = _cleanString(row[3]);
          String status = _cleanString(row[4]);
          
          // Determine work order type based on work order number or description
          String jenisWO = _determineWOType(workOrder, deskripsi);
          
          // Generate date (you can modify this logic based on your needs)
          String tanggal = DateTime.now().toIso8601String().split('T')[0]; // Today's date as default
          
          // Validasi data wajib (skip row jika work order kosong atau invalid)
          if (workOrder.isNotEmpty && 
              workOrder.toLowerCase() != 'no' && // Skip if it's header data
              deskripsi.isNotEmpty && 
              status.isNotEmpty &&
              !workOrder.contains('Zoom meeting') && // Skip invalid entries
              no.isNotEmpty) {
            
            Map<String, dynamic> workOrderItem = {
              'no': no,
              'work_order': workOrder,
              'deskripsi': deskripsi,
              'pic': pic,
              'status': status,
              'jenis_wo': jenisWO,
              'tanggal': tanggal,
              'created_at': DateTime.now().toIso8601String(),
            };
            
            workOrderData.add(workOrderItem);
            validRows++;
            print('✅ Valid row added: No=$no, WO=$workOrder, PIC=$pic, Status=$status, Type=$jenisWO');
          } else {
            invalidRows++;
            print('❌ Invalid row $i - Missing/invalid data: No=$no, WO=$workOrder, Desc=$deskripsi, PIC=$pic, Status=$status');
          }
        } else {
          invalidRows++;
          print('❌ Invalid row $i - Insufficient columns: ${row.length} (expected 5)');
        }
      }
      
      print('📈 Processing complete:');
      print('   ✅ Valid rows: $validRows');
      print('   ❌ Invalid rows: $invalidRows');
      print('   📦 Total items to save: ${workOrderData.length}');
      
      if (workOrderData.isNotEmpty) {
        // Simpan data
        await addWorkOrderData(workOrderData);
        print('💾 Excel data berhasil diproses dan disimpan: ${workOrderData.length} records');
      } else {
        print('⚠️ No valid data to save');
      }
      
    } catch (e) {
      print('❌ Error processing Excel data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
  
  // Function untuk test data (debug purpose)
  static Future<void> testData() async {
    List<Map<String, dynamic>> testData = [
      {
        'no': '1',
        'work_order': 'WO-001',
        'deskripsi': 'Test Tactical Work Order 1',
        'pic': 'John Doe',
        'status': 'Close',
        'jenis_wo': 'Tactical',
        'tanggal': '2025-01-15',
      },
      {
        'no': '2',
        'work_order': 'WO-002',
        'deskripsi': 'Test Non-Tactical Work Order 2',
        'pic': 'Jane Smith',
        'status': 'InProgress',
        'jenis_wo': 'Non-Tactical',
        'tanggal': '2025-01-16',
      }
    ];
    
    await saveWorkOrderData(testData);
    print('🧪 Test data saved');
  }
}