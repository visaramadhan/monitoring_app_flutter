import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'drawer.dart';
import '../widgets/scrollable_data_table.dart';

class PengambilanPage extends StatefulWidget {
  const PengambilanPage({super.key});

  @override
  _PengambilanPageState createState() => _PengambilanPageState();
}

class _PengambilanPageState extends State<PengambilanPage> {
  List<Map<String, dynamic>> items = [];
  String selectedFileName = 'Tidak ada file yang dipilih';
  bool isLoadingFile = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _addInitialRow();
  }

  void _addInitialRow() {
    if (items.isEmpty) {
      items.add({
        'no': 1,
        'nama': '',
        'spesifikasi': '',
        'jumlah': '',
        'pic': '',
        'peletakkan': '',
        'picking': '',
      });
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('pengambilan_data');
    if (savedData != null) {
      setState(() {
        items = List<Map<String, dynamic>>.from(json.decode(savedData));
      });
    }
    _addInitialRow();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pengambilan_data', json.encode(items));
  }

  Future<void> _pickExcelFile() async {
    setState(() {
      isLoadingFile = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          selectedFileName = file.name;
        });

        final bytes = file.bytes;
        if (bytes != null) {
          final excelFile = excel.Excel.decodeBytes(bytes);
          final sheet = excelFile.tables[excelFile.tables.keys.first];

          setState(() {
            items = [];
            for (int i = 1; i < sheet!.rows.length; i++) {
              final row = sheet.rows[i];
              if (row.isNotEmpty) {
                items.add({
                  'no': items.length + 1,
                  'nama': row[0]?.value?.toString() ?? '',
                  'spesifikasi': row[1]?.value?.toString() ?? '',
                  'jumlah': row[2]?.value?.toString() ?? '',
                  'pic': row[3]?.value?.toString() ?? '',
                  'peletakkan': row[4]?.value?.toString() ?? '',
                  'picking': row[5]?.value?.toString() ?? '',
                });
              }
            }
            _addInitialRow();
            _saveData();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingFile = false;
      });
    }
  }

  void _addRow() {
    setState(() {
      items.add({
        'no': items.length + 1,
        'nama': '',
        'spesifikasi': '',
        'jumlah': '',
        'pic': '',
        'peletakkan': '',
        'picking': '',
      });
    });
    _saveData();
  }

  void _deleteRow(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
        for (int i = 0; i < items.length; i++) {
          items[i]['no'] = i + 1;
        }
      });
      _saveData();
    }
  }

  void _updateField(int index, String field, String value) {
    setState(() {
      items[index][field] = value;
    });
    
    // Auto add new row if this is the last row and has content
    if (index == items.length - 1 && value.isNotEmpty) {
      _addRow();
    }
    
    _saveData();
  }

  Future<void> _downloadExcel() async {
    try {
      var excelFile = excel.Excel.createExcel();
      var sheet = excelFile['Pengambilan Barang'];

      sheet.appendRow([
        'No',
        'Nama Barang',
        'Spesifikasi',
        'Jumlah',
        'PIC',
        'Peletakkan',
        'Picking Slip'
      ]);

      for (var item in items) {
        if (item['nama'].toString().isNotEmpty || 
            item['spesifikasi'].toString().isNotEmpty) {
          sheet.appendRow([
            item['no'],
            item['nama'],
            item['spesifikasi'],
            item['jumlah'],
            item['pic'],
            item['peletakkan'],
            item['picking'],
          ]);
        }
      }

      final fileBytes = excelFile.encode();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Pengambilan_Barang_${DateTime.now().millisecondsSinceEpoch}.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File berhasil diunduh'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      if (isEditing) {
        _saveData();
      }
      isEditing = !isEditing;
    });
  }

  Widget _buildTextField(String value, Function(String) onChanged, {bool enabled = true}) {
    return isEditing && enabled
        ? TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            onChanged: onChanged,
          )
        : Container(
            padding: EdgeInsets.all(8),
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(fontSize: 14),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Pengambilan Barang',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.green.shade700),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: isEditing ? 'Simpan' : 'Edit',
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.green.shade700),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: isEditing ? _addRow : null,
                  icon: Icon(Icons.add),
                  label: Text('Tambah Baris'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? Colors.green.shade700 : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickExcelFile,
                  icon: isLoadingFile
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.file_upload),
                  label: Text(isLoadingFile ? 'Loading...' : 'Import Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _downloadExcel,
                  icon: Icon(Icons.download),
                  label: Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            if (selectedFileName != 'Tidak ada file yang dipilih') ...[
              SizedBox(height: 8),
              Text(
                'File: $selectedFileName',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            SizedBox(height: 16),
            
            // Data Table
            Expanded(
              child: ScrollableDataTable(
                headingRowColor: WidgetStateProperty.all(Colors.green),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('No.')),
                  DataColumn(label: Text('Nama Barang')),
                  DataColumn(label: Text('Spesifikasi')),
                  DataColumn(label: Text('Jumlah')),
                  DataColumn(label: Text('PIC')),
                  DataColumn(label: Text('Peletakkan')),
                  DataColumn(label: Text('Picking Slip')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: List.generate(items.length, (index) {
                  final row = items[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('${row['no']}')),
                      DataCell(
                        _buildTextField(
                          row['nama'],
                          (val) => _updateField(index, 'nama', val),
                        ),
                      ),
                      DataCell(
                        _buildTextField(
                          row['spesifikasi'],
                          (val) => _updateField(index, 'spesifikasi', val),
                        ),
                      ),
                      DataCell(
                        _buildTextField(
                          row['jumlah'],
                          (val) => _updateField(index, 'jumlah', val),
                        ),
                      ),
                      DataCell(
                        _buildTextField(
                          row['pic'],
                          (val) => _updateField(index, 'pic', val),
                        ),
                      ),
                      DataCell(
                        _buildTextField(
                          row['peletakkan'],
                          (val) => _updateField(index, 'peletakkan', val),
                        ),
                      ),
                      DataCell(
                        _buildTextField(
                          row['picking'],
                          (val) => _updateField(index, 'picking', val),
                        ),
                      ),
                      DataCell(
                        isEditing && items.length > 1
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRow(index),
                                tooltip: 'Hapus baris',
                              )
                            : SizedBox.shrink(),
                      ),
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