import 'package:dio/dio.dart';

import '../models/student_models.dart';
import '../utils/formatters.dart';

class StudentRepository {
  const StudentRepository(this._dio);

  final Dio _dio;

  Future<StudentProfile> profile() async {
    final response = await _dio.get('/api/student/profile');
    return StudentProfile.fromJson(objectData(response.data, 'profile'));
  }

  Future<double> balance() async {
    final response = await _dio.get('/api/student/balance');
    final data = objectData(response.data);
    return asDouble(data['balance'] ?? data['saldo'] ?? response.data);
  }

  Future<List<ParkingActivity>> parkingHistory() async {
    final response = await _dio.get('/api/student/parking-history');
    return listData(response.data, 'parking_history')
        .whereType<Map>()
        .map(
          (item) => ParkingActivity.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<StudentTransaction>> transactions() async {
    final response = await _dio.get('/api/student/transactions');
    return listData(response.data, 'transactions')
        .whereType<Map>()
        .map(
          (item) =>
              StudentTransaction.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<TopUpRequest>> topUps() async {
    final response = await _dio.get('/api/student/topups');
    return listData(response.data, 'topups')
        .whereType<Map>()
        .map((item) => TopUpRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<TopUpRequest> requestTopUp({
    required double amount,
    required List<int> proofBytes,
    required String proofFileName,
  }) async {
    final response = await _dio.post(
      '/api/student/topups',
      data: FormData.fromMap({
        'amount': amount.round(),
        'payment_proof': MultipartFile.fromBytes(
          proofBytes,
          filename: proofFileName,
        ),
      }),
    );
    return TopUpRequest.fromJson(objectData(response.data, 'topup'));
  }

  Future<StudentProfile?> updateProfile({required String name}) async {
    Response<dynamic> response;
    try {
      response = await _dio.patch('/api/student/profile', data: {'name': name});
    } on DioException catch (error) {
      if (error.response?.statusCode != 405) rethrow;
      response = await _dio.put('/api/student/profile', data: {'name': name});
    }
    final data = objectData(response.data, 'profile');
    return data.isEmpty ? null : StudentProfile.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    await _dio.post(
      '/api/student/change-password',
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': password,
      },
    );
  }
}
