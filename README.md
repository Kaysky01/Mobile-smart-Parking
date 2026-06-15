# MyParking

Flutter student client for the Laravel RFID Smart Parking backend.

## Run

Android emulator:

```powershell
flutter run
```

Physical device or production API:

```powershell
flutter run --dart-define=API_BASE_URL=https://parking.example.edu
```

The default API URL is `http://10.42.26.242:8000`.

## API

The client uses the `/api/student` login, profile, balance, parking history,
transactions, and top-up endpoints. The optional password dialog expects:

```text
POST /api/student/change-password
```

Profile name updates use `PATCH /api/student/profile` and fall back to `PUT`
when the backend returns HTTP 405. Top-up requests use multipart form data with
`amount` and `payment_proof`.

Laravel Sanctum tokens are stored with `flutter_secure_storage`. Only
non-sensitive session metadata is stored in `SharedPreferences`.
