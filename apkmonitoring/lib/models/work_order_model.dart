class WorkOrderModel {
  final String id;
  final String wo;
  final String desc;
  final String typeWO;
  final String pic;
  final String status;
  final String category;
  final String jenisWO;
  final bool photo;
  final String? photoData;
  final String? photoPath;
  final DateTime timestamp;
  final String userId;
  final int no;

  WorkOrderModel({
    required this.id,
    required this.wo,
    required this.desc,
    required this.typeWO,
    required this.pic,
    required this.status,
    required this.category,
    required this.jenisWO,
    required this.photo,
    this.photoData,
    this.photoPath,
    required this.timestamp,
    required this.userId,
    required this.no,
  });

  factory WorkOrderModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkOrderModel(
      id: id,
      wo: map['wo'] ?? '',
      desc: map['desc'] ?? '',
      typeWO: map['typeWO'] ?? '',
      pic: map['pic'] ?? '',
      status: map['status'] ?? '',
      category: map['category'] ?? '',
      jenisWO: map['jenis_wo'] ?? '',
      photo: map['photo'] ?? false,
      photoData: map['photoData'],
      photoPath: map['photoPath'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      userId: map['userId'] ?? '',
      no: map['no'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wo': wo,
      'desc': desc,
      'typeWO': typeWO,
      'pic': pic,
      'status': status,
      'category': category,
      'jenis_wo': jenisWO,
      'photo': photo,
      'photoData': photoData,
      'photoPath': photoPath,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'no': no,
    };
  }
}