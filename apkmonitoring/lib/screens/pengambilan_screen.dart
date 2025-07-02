import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'drawer.dart';

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
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('pengambilan_data');
    if (savedData != null) {
      setState(() {
        items = List<Map<String, dynamic>>.from(json.decode(savedData));
      });
    }
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
            _saveData();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
  }

  void _deleteRow(int index) {
    setState(() {
      items.removeAt(index);
      for (int i = 0; i < items.length; i++) {
        items[i]['no'] = i + 1;
      }
    });
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
        SnackBar(content: Text('File berhasil disimpan di: Pengambilan_Barang_${DateTime.now().millisecondsSinceEpoch}.xlsx')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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

  Widget _buildTextField(String value, Function(String) onChanged) {
    return isEditing 
      ? TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onChanged: onChanged,
        )
      : Text(value.isNotEmpty ? value : '-');
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
        ),
        Builder(
          builder:
          (context) => IconButton(
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
            // Data Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300), // Border untuk tabel
                  ),
                  child: DataTable(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                      verticalInside: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    headingRowColor: WidgetStateProperty.all(Colors.green),
                    headingTextStyle: const TextStyle(color: Colors.white),
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
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: Text('${row['no']}'),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: _buildTextField(
                              row['nama'],
                              (val) => row['nama'] = val,
                            ),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: _buildTextField(
                              row['spesifikasi'],
                              (val) => row['spesifikasi'] = val,
                            ),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: _buildTextField(
                              row['jumlah'],
                              (val) => row['jumlah'] = val,
                            ),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: _buildTextField(
                              row['pic'],
                              (val) => row['pic'] = val,
                            ),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: _buildTextField(
                              row['peletakkan'],
                              (val) => row['peletakkan'] = val,
                            ),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: _buildTextField(
                              row['picking'],
                              (val) => row['picking'] = val,
                            ),
                          )),
                          DataCell(Container(
                            padding: EdgeInsets.all(8),
                            child: isEditing
                                ? IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteRow(index),
                                  )
                                : null,
                          )),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: isEditing ? _addRow : null,
                  icon: Icon(Icons.add),
                  label: Text('Tambah Baris'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickExcelFile,
                  icon: isLoadingFile
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
          ],
        ),
      ),
    );
  }
}