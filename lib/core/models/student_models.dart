import '../utils/formatters.dart';

Map<String, dynamic> objectData(dynamic body, [String? key]) {
  dynamic value = body;
  if (value is Map && value['data'] != null) value = value['data'];
  if (key != null && value is Map && value[key] != null) value = value[key];
  return value is Map ? Map<String, dynamic>.from(value) : {};
}

List<dynamic> listData(dynamic body, [String? key]) {
  dynamic value = body;
  if (value is Map && value['data'] != null) value = value['data'];
  if (key != null && value is Map && value[key] != null) value = value[key];
  if (value is Map && value['data'] is List) value = value['data'];
  return value is List ? value : const [];
}

class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.npm,
    required this.rfidUid,
    required this.plateNumber,
    required this.vehicleType,
    required this.rfidStatus,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : json;
    final vehicle = student['vehicle'] is Map
        ? Map<String, dynamic>.from(student['vehicle'] as Map)
        : <String, dynamic>{};
    final rfid = student['rfid'] is Map
        ? Map<String, dynamic>.from(student['rfid'] as Map)
        : <String, dynamic>{};

    return StudentProfile(
      name: (student['name'] ?? student['nama'] ?? 'Student').toString(),
      npm: (student['npm'] ?? student['student_number'] ?? '-').toString(),
      rfidUid: (student['rfid_uid'] ?? rfid['uid'] ?? rfid['rfid_uid'] ?? '-')
          .toString(),
      plateNumber:
          (student['plate_number'] ??
                  student['nomor_polisi'] ??
                  vehicle['plate_number'] ??
                  '-')
              .toString(),
      vehicleType:
          (student['vehicle_type'] ??
                  vehicle['type'] ??
                  vehicle['jenis'] ??
                  '-')
              .toString(),
      rfidStatus:
          (student['rfid_status'] ??
                  rfid['status'] ??
                  (student['is_active'] == false ? 'Inactive' : 'Active'))
              .toString(),
    );
  }

  final String name;
  final String npm;
  final String rfidUid;
  final String plateNumber;
  final String vehicleType;
  final String rfidStatus;

  StudentProfile copyWith({String? name}) {
    return StudentProfile(
      name: name ?? this.name,
      npm: npm,
      rfidUid: rfidUid,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      rfidStatus: rfidStatus,
    );
  }
}

class TopUpRequest {
  const TopUpRequest({
    required this.id,
    required this.amount,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory TopUpRequest.fromJson(Map<String, dynamic> json) => TopUpRequest(
    id: (json['id'] ?? json['topup_id'] ?? '-').toString(),
    amount: asDouble(json['amount'] ?? json['nominal']),
    status: (json['status'] ?? 'pending').toString().toLowerCase(),
    rejectionReason: json['rejection_reason'] as String?,
    createdAt: asDateTime(json['created_at'] ?? json['date']),
  );

  final String id;
  final double amount;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;
}

class ParkingActivity {
  const ParkingActivity({
    required this.id,
    required this.entryTime,
    required this.exitTime,
    required this.cost,
  });

  factory ParkingActivity.fromJson(Map<String, dynamic> json) =>
      ParkingActivity(
        id: (json['id'] ?? '-').toString(),
        entryTime: asDateTime(
          json['entry_time'] ?? json['waktu_masuk'] ?? json['check_in'],
        ),
        exitTime: asDateTime(
          json['exit_time'] ?? json['waktu_keluar'] ?? json['check_out'],
        ),
        cost: asDouble(json['cost'] ?? json['fee'] ?? json['biaya']),
      );

  final String id;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final double cost;

  Duration? get duration {
    if (entryTime == null || exitTime == null) return null;
    return exitTime!.difference(entryTime!);
  }
}

enum TransactionType { parking, topup }

class StudentTransaction {
  const StudentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.description,
  });

  factory StudentTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['transaction_type'] ?? '')
        .toString()
        .toLowerCase();
    final isTopup =
        rawType.contains('top') ||
        rawType.contains('credit') ||
        rawType.contains('deposit');
    return StudentTransaction(
      id: (json['id'] ?? '-').toString(),
      type: isTopup ? TransactionType.topup : TransactionType.parking,
      amount: asDouble(json['amount'] ?? json['nominal']),
      createdAt: asDateTime(json['created_at'] ?? json['date']),
      description:
          (json['description'] ??
                  json['note'] ??
                  (isTopup ? 'Balance top up' : 'Parking payment'))
              .toString(),
    );
  }

  final String id;
  final TransactionType type;
  final double amount;
  final DateTime? createdAt;
  final String description;
}
