import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'drawer.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedYear = '2025';
  String selectedMonth = 'Juni';
  bool hasData = false;
  List<Map<String, dynamic>> workOrderData = [];
  List<Map<String, dynamic>> tacticalData = [];
  List<Map<String, dynamic>> nonTacticalData = [];
  List<Map<String, dynamic>> monthlyData = [];

  final List<String> years = ['2023', '2024', '2025'];
  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadDataFromFirestore();
  }

  Future<void> _loadDataFromFirestore() async {
    try {
      print('Loading data from Firestore...');
      workOrderData.clear();
      
      // Load from multiple collections based on your structure
      await _loadFromCollection('work_order_history');
      await _loadFromCollection('tactical_work_order');
      await _loadFromCollection('nontactical_work_order');
      
      print('Total data loaded: ${workOrderData.length}');
      
      setState(() {
        _filterDataByMonthYear();
        hasData = monthlyData.isNotEmpty;
      });
    } catch (e) {
      print('Error loading data from Firestore: $e');
    }
  }

  Future<void> _loadFromCollection(String collectionName) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(collectionName).get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> docData = doc.data();
        print('Document from $collectionName: ${doc.id}');
        print('Document data keys: ${docData.keys.toList()}');
        
        // Check if this is a direct work order document
        if (docData.containsKey('wo') && docData.containsKey('status')) {
          workOrderData.add(_normalizeData(docData));
        }
        
        // Check for nested work orders (like wo_1, wo_2, etc.)
        docData.forEach((key, value) {
          if (key.startsWith('wo_') && value is Map<String, dynamic>) {
            Map<String, dynamic> nestedData = value;
            if (nestedData.containsKey('wo') || nestedData.containsKey('desc')) {
              workOrderData.add(_normalizeData(nestedData));
            }
          }
        });
      }
    } catch (e) {
      print('Error loading from collection $collectionName: $e');
    }
  }

  // Normalize data structure and field names
  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    Map<String, dynamic> normalized = Map.from(data);
    
    // Normalize status field (convert to proper case)
    String status = normalized['status']?.toString().toLowerCase() ?? '';
    switch (status) {
      case 'close':
        normalized['status'] = 'Close';
        break;
      case 'inprogress':
      case 'in progress':
        normalized['status'] = 'InProgress';
        break;
      case 'reschedule':
        normalized['status'] = 'Reschedule';
        break;
      case 'wmatt':
        normalized['status'] = 'WMatt';
        break;
      case 'wshutt':
        normalized['status'] = 'WShutt';
        break;
      default:
        if (status.isEmpty) {
          normalized['status'] = 'InProgress'; // Default status for null values
        }
    }
    
    // Normalize date field
    if (normalized['timestamp'] != null && normalized['tanggal'] == null) {
      normalized['tanggal'] = normalized['timestamp'];
    }
    
    // Ensure required fields exist
    normalized['wo'] = normalized['wo'] ?? 'N/A';
    normalized['desc'] = normalized['desc'] ?? 'No description';
    normalized['jenis_wo'] = normalized['jenis_wo'] ?? 'Unknown';
    
    print('Normalized data: wo=${normalized['wo']}, status=${normalized['status']}, jenis=${normalized['jenis_wo']}');
    
    return normalized;
  }

  void _filterDataByMonthYear() {
    tacticalData.clear();
    nonTacticalData.clear();
    monthlyData.clear();
    
    int monthNumber = months.indexOf(selectedMonth) + 1;
    print('Filtering for: $selectedYear-$monthNumber ($selectedMonth)');
    
    for (var data in workOrderData) {
      String? dateStr = data['tanggal']?.toString() ?? data['timestamp']?.toString();
      if (dateStr != null) {
        try {
          DateTime date;
          if (dateStr.contains('T')) {
            // ISO format like "2025-06-29T18:46:31.311"
            date = DateTime.parse(dateStr);
          } else {
            // Try other formats
            date = DateTime.parse(dateStr);
          }
          
          if (date.year.toString() == selectedYear && date.month == monthNumber) {
            monthlyData.add(data);
            
            String jenis = data['jenis_wo']?.toString().toLowerCase() ?? '';
            print('Processing jenis_wo: "$jenis" for WO: ${data['wo']}');
            
            if (jenis.contains('tactical') || jenis.contains('taktis')) {
              tacticalData.add(data);
              print('Added to tactical: ${data['wo']}');
            } else if (jenis.contains('non-tactical') || jenis.contains('non tactical') || 
                      jenis.contains('nontactical') || jenis.contains('non taktis')) {
              nonTacticalData.add(data);
              print('Added to non-tactical: ${data['wo']}');
            } else {
              // Default to non-tactical if unclear
              nonTacticalData.add(data);
              print('Added to non-tactical (default): ${data['wo']} - jenis: "$jenis"');
            }
          }
        } catch (e) {
          print('Error parsing date: $dateStr - $e');
        }
      } else {
        print('Missing date field in data: ${data['wo']}');
      }
    }
    
    print('Results for $selectedMonth $selectedYear:');
    print('- Monthly data: ${monthlyData.length}');
    print('- Tactical: ${tacticalData.length}');
    print('- Non-tactical: ${nonTacticalData.length}');
  }

  Map<String, int> _getStatusCounts(List<Map<String, dynamic>> data) {
    Map<String, int> counts = {'Close': 0, 'InProgress': 0, 'Reschedule': 0, 'WMatt': 0, 'WShutt': 0};
    
    for (var item in data) {
      String status = item['status']?.toString() ?? 'InProgress';
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      } else {
        print('Unknown status found: $status');
        counts['InProgress'] = counts['InProgress']! + 1; // Default to InProgress
      }
    }
    
    print('Status counts: $counts');
    return counts;
  }

  List<BarChartGroupData> _generateBarChartData(Map<String, int> statusCounts) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: statusCounts['Close']!.toDouble(), color: Colors.green, width: 20)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: statusCounts['Reschedule']!.toDouble(), color: Colors.red, width: 20)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: statusCounts['InProgress']!.toDouble(), color: Colors.orange, width: 20)],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [BarChartRodData(toY: statusCounts['WMatt']!.toDouble(), color: Colors.amber, width: 20)],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [BarChartRodData(toY: statusCounts['WShutt']!.toDouble(), color: Colors.blue, width: 20)],
      ),
    ];
  }

  List<PieChartSectionData> _generatePieChartData(Map<String, int> statusCounts) {
    int total = statusCounts.values.reduce((a, b) => a + b);
    if (total == 0) return [];
    
    List<PieChartSectionData> sections = [];
    
    statusCounts.forEach((status, count) {
      if (count > 0) {
        Color color;
        switch (status) {
          case 'Close':
            color = Colors.green;
            break;
          case 'InProgress':
            color = Colors.orange;
            break;
          case 'Reschedule':
            color = Colors.red;
            break;
          case 'WMatt':
            color = Colors.amber;
            break;
          case 'WShutt':
            color = Colors.blue;
            break;
          default:
            color = Colors.grey;
        }
        
        double percentage = (count / total * 100);
        sections.add(PieChartSectionData(
          color: color,
          value: percentage,
          title: '${percentage.toStringAsFixed(1)}%\n$status\n($count)',
          titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ));
      }
    });
    
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> yearlyStatusCounts = _getStatusCounts(workOrderData);
    Map<String, int> monthlyStatusCounts = _getStatusCounts(monthlyData);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History Pekerjaan',
          style: TextStyle(color: Color(0xFF4CAF50)),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      endDrawer: AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDataFromFirestore,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Pilih Tahun dan Bulan
              Text(
                'Pilih Tahun dan Bulan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedYear,
                      items: years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value!;
                          _filterDataByMonthYear();
                          hasData = monthlyData.isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Pilih Tahun',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedMonth,
                      items: months.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value!;
                          _filterDataByMonthYear();
                          hasData = monthlyData.isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Pilih Bulan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              
              // Info jumlah data
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasData ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hasData ? Colors.green.shade200 : Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasData 
                        ? 'Data ditemukan untuk $selectedMonth $selectedYear:'
                        : 'Tidak ada data untuk $selectedMonth $selectedYear',
                      style: TextStyle(
                        color: hasData ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (hasData) ...[
                      SizedBox(height: 8),
                      Text(
                        '• Total: ${monthlyData.length} work orders\n'
                        '• Tactical WO: ${tacticalData.length}\n'
                        '• Non-Tactical WO: ${nonTacticalData.length}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadDataFromFirestore,
                      icon: Icon(Icons.refresh, size: 16),
                      label: Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Grafik Tahunan
              _buildChartSection(
                'Grafik Tahunan - Semua Data ($selectedYear)',
                yearlyStatusCounts,
                workOrderData.isNotEmpty,
              ),
              
              SizedBox(height: 30),
              
              // Diagram Lingkaran Tahunan
              _buildPieChartSection(
                'Diagram Lingkaran Tahunan - Semua Data ($selectedYear)',
                yearlyStatusCounts,
                workOrderData.isNotEmpty,
              ),
              
              SizedBox(height: 30),

              // Tactical WO Table
              _buildTableSection('Tactical WO', tacticalData),
              
              SizedBox(height: 30),
              
              // Non-Tactical WO Table
              _buildTableSection('Non-Tactical WO', nonTacticalData),
              
              SizedBox(height: 30),
              
              // Grafik Bulanan
              _buildChartSection(
                'Grafik Bulanan - $selectedMonth $selectedYear',
                monthlyStatusCounts,
                hasData,
              ),
              
              SizedBox(height: 30),
              
              // Diagram Lingkaran Bulanan
              _buildPieChartSection(
                'Diagram Lingkaran Bulanan - $selectedMonth $selectedYear',
                monthlyStatusCounts,
                hasData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, Map<String, int> statusCounts, bool hasData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasData
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0: return Text('Close', style: TextStyle(fontSize: 12));
                                case 1: return Text('Reschedule', style: TextStyle(fontSize: 10));
                                case 2: return Text('InProgress', style: TextStyle(fontSize: 10));
                                case 3: return Text('WMatt', style: TextStyle(fontSize: 12));
                                case 4: return Text('WShutt', style: TextStyle(fontSize: 12));
                                default: return Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      barGroups: _generateBarChartData(statusCounts),
                      maxY: statusCounts.values.isEmpty ? 5 : statusCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    'Tidak ada data untuk ditampilkan',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection(String title, Map<String, int> statusCounts, bool hasData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasData
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartData(statusCounts),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    'Tidak ada data untuk ditampilkan',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTableSection(String title, List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title - $selectedMonth $selectedYear',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        SizedBox(height: 10),
        if (data.isNotEmpty)
          _buildDataTable(data)
        else
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tidak ada data $title untuk periode ini',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Text('Tidak ada data untuk ditampilkan');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Color(0xFFE8F5E9)),
        columnSpacing: 16,
        columns: [
          DataColumn(
            label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Work Order', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Jenis WO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        rows: data.map((item) {
          Color statusColor = _getStatusColor(item['status']?.toString() ?? '');
          String dateStr = item['tanggal']?.toString() ?? item['timestamp']?.toString() ?? '';
          
          // Format date for display
          String displayDate = '';
          if (dateStr.isNotEmpty) {
            try {
              DateTime date = DateTime.parse(dateStr);
              displayDate = '${date.day}/${date.month}/${date.year}';
            } catch (e) {
              displayDate = dateStr;
            }
          }

          return DataRow(
            cells: [
              DataCell(Text(displayDate)),
              DataCell(Text(item['wo']?.toString() ?? '-')),
              DataCell(Text(item['jenis_wo']?.toString() ?? '-')),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    item['desc']?.toString() ?? '-',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    item['status']?.toString() ?? 'N/A',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Close':
        return Colors.green;
      case 'InProgress':
        return Colors.orange;
      case 'Reschedule':
        return Colors.red;
      case 'WMatt':
        return Colors.amber[700]!;
      case 'WShutt':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}