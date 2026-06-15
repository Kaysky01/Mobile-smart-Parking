import 'package:flutter_test/flutter_test.dart';
import 'package:parking_sistem/core/models/student_models.dart';

void main() {
  test('student profile accepts nested Laravel resources', () {
    final profile = StudentProfile.fromJson({
      'name': 'Andika',
      'npm': '24783072',
      'rfid': {'uid': 'C6 EF 25 07', 'status': 'active'},
      'vehicle': {'plate_number': 'BE1234AA', 'type': 'Motorcycle'},
    });

    expect(profile.name, 'Andika');
    expect(profile.rfidUid, 'C6 EF 25 07');
    expect(profile.plateNumber, 'BE1234AA');
    expect(profile.rfidStatus, 'active');
  });

  test('listData unwraps paginated Laravel data', () {
    final result = listData({
      'data': {
        'data': [
          {'id': 1},
        ],
      },
    });

    expect(result, hasLength(1));
  });
}
