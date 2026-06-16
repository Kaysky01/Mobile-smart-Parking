import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_repository.dart';
import '../data/student_repository.dart';
import '../models/student_models.dart';
import '../network/api_client.dart';
import '../storage/session_storage.dart';

enum SessionStatus { checking, signedOut, authenticated }

class AppController extends ChangeNotifier {
  AppController(this._storage, this._authRepository, this._studentRepository);

  final SessionStorage _storage;
  final AuthRepository _authRepository;
  final StudentRepository _studentRepository;

  SessionStatus status = SessionStatus.checking;
  StudentProfile? profile;
  double balance = 0;
  List<TopUpRequest> topUps = [];
  List<ParkingActivity> parkingHistory = [];
  List<StudentTransaction> transactions = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  DateTime? lastReadNotificationTime;

  Future<void> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    status = SessionStatus.authenticated;
    isLoading = true;
    notifyListeners();
    try {
      profile = await _studentRepository.profile();
    } catch (error) {
      errorMessage = apiErrorMessage(error);
      await _storage.clear();
      status = SessionStatus.signedOut;
      isLoading = false;
      notifyListeners();
      return;
    }
    await refresh(includeProfile: false);
  }

  Future<void> loadLastReadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('notifications_last_read_time');
    if (timestamp != null) {
      lastReadNotificationTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      notifyListeners();
    }
  }

  Future<void> markNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(
      'notifications_last_read_time',
      now.millisecondsSinceEpoch,
    );
    lastReadNotificationTime = now;
    notifyListeners();
  }

  bool get hasUnreadNotifications {
    final approvedTopUps = topUps
        .where((item) => item.status == 'approved')
        .take(3);
    final rejectedTopUps = topUps
        .where((item) => item.status == 'rejected')
        .take(3);

    final hasUnreadApproved = approvedTopUps.any(
      (item) =>
          lastReadNotificationTime == null ||
          (item.createdAt != null &&
              item.createdAt!.isAfter(lastReadNotificationTime!)),
    );

    final hasUnreadRejected = rejectedTopUps.any(
      (item) =>
          lastReadNotificationTime == null ||
          (item.createdAt != null &&
              item.createdAt!.isAfter(lastReadNotificationTime!)),
    );

    final hasUnreadParking =
        parkingHistory.isNotEmpty &&
        (lastReadNotificationTime == null ||
            (parkingHistory.first.entryTime != null &&
                parkingHistory.first.entryTime!.isAfter(
                  lastReadNotificationTime!,
                )));

    final hasUnreadBalanceWarning =
        balance < 10000 && lastReadNotificationTime == null;

    return hasUnreadApproved ||
        hasUnreadRejected ||
        hasUnreadParking ||
        hasUnreadBalanceWarning;
  }

  Future<bool> login(String npm, String password) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authRepository.login(npm: npm, password: password);
      profile = result.profile;
      status = SessionStatus.authenticated;
      isSubmitting = false;
      notifyListeners();
      await refresh();
      return true;
    } catch (error) {
      errorMessage = apiErrorMessage(error);
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh({bool includeProfile = true}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    Object? firstError;
    void captureError(Object error) => firstError ??= error;

    await Future.wait<void>([
      if (includeProfile)
        _studentRepository.profile().then<void>(
          (value) => profile = value,
          onError: (Object error, StackTrace _) => captureError(error),
        ),
      _studentRepository.balance().then<void>(
        (value) => balance = value,
        onError: (Object error, StackTrace _) => captureError(error),
      ),
      _studentRepository.parkingHistory().then<void>(
        (value) => parkingHistory = value,
        onError: (Object error, StackTrace _) => captureError(error),
      ),
      _studentRepository.transactions().then<void>(
        (value) => transactions = value,
        onError: (Object error, StackTrace _) => captureError(error),
      ),
      _studentRepository.topUps().then<void>(
        (value) => topUps = value,
        onError: (Object error, StackTrace _) => captureError(error),
      ),
    ]);

    if (firstError != null) errorMessage = apiErrorMessage(firstError!);
    isLoading = false;
    notifyListeners();
  }

  Future<bool> submitTopUp({
    required double amount,
    required List<int> proofBytes,
    required String proofFileName,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final request = await _studentRepository.requestTopUp(
        amount: amount,
        proofBytes: proofBytes,
        proofFileName: proofFileName,
      );
      topUps = [request, ...topUps];
      return true;
    } catch (error) {
      errorMessage = apiErrorMessage(error);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfileName(String name) async {
    isSubmitting = true;
    notifyListeners();
    try {
      final updated = await _studentRepository.updateProfile(name: name);
      profile = updated ?? profile?.copyWith(name: name);
      return null;
    } catch (error) {
      return apiErrorMessage(error);
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      await _studentRepository.changePassword(
        currentPassword: currentPassword,
        password: password,
      );
      return null;
    } catch (error) {
      return apiErrorMessage(error);
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      await _storage.clear();
    }
    profile = null;
    balance = 0;
    topUps = [];
    parkingHistory = [];
    transactions = [];
    errorMessage = null;
    status = SessionStatus.signedOut;
    notifyListeners();
  }
}
