# Prompt Penyesuaian Backend Laravel MyParking

Gunakan prompt berikut pada project Laravel Smart Parking:

---

Saya memiliki backend Laravel Smart Parking yang sudah menyediakan autentikasi
mahasiswa menggunakan Laravel Sanctum. Sesuaikan backend agar kompatibel dengan
aplikasi Flutter MyParking.

## Ketentuan Umum

- Pertahankan endpoint dan fitur lama yang masih digunakan.
- Semua endpoint mahasiswa selain login wajib menggunakan middleware
  `auth:sanctum`.
- Gunakan Form Request untuk validasi.
- Gunakan API Resource atau struktur response JSON yang konsisten.
- Gunakan database transaction untuk proses yang mengubah data.
- Jangan langsung menambah saldo ketika mahasiswa mengirim top-up.
- Saldo hanya bertambah ketika admin menyetujui top-up.
- Cegah top-up yang sama disetujui atau ditolak lebih dari satu kali.
- Gunakan status HTTP yang benar.

## Endpoint Yang Dibutuhkan

### 1. Login Mahasiswa

```http
POST /api/student/login
Content-Type: application/json
```

Request:

```json
{
  "npm": "24783072",
  "password": "01062006"
}
```

Response sukses:

```json
{
  "message": "Login berhasil",
  "token": "sanctum-plain-text-token",
  "data": {
    "student": {
      "id": 1,
      "name": "Andika",
      "npm": "24783072",
      "rfid_uid": "C6 EF 25 07",
      "rfid_status": "active",
      "plate_number": "BE1234AA",
      "vehicle_type": "Motorcycle"
    }
  }
}
```

### 2. Profil Mahasiswa

```http
GET /api/student/profile
Authorization: Bearer {token}
```

Response:

```json
{
  "data": {
    "profile": {
      "id": 1,
      "name": "Andika",
      "npm": "24783072",
      "rfid_uid": "C6 EF 25 07",
      "rfid_status": "active",
      "plate_number": "BE1234AA",
      "vehicle_type": "Motorcycle"
    }
  }
}
```

### 3. Ubah Nama Profil

Sediakan endpoint berikut:

```http
PATCH /api/student/profile
Authorization: Bearer {token}
Content-Type: application/json
```

Backend juga boleh menerima method `PUT` pada URL yang sama.

Request:

```json
{
  "name": "Andika Sanddi Pranata"
}
```

Validasi:

```php
'name' => ['required', 'string', 'min:3', 'max:100']
```

Mahasiswa hanya boleh mengubah profil miliknya sendiri. Jangan menerima
`student_id`, `npm`, saldo, RFID UID, atau field sensitif lain dari request.

Response sukses:

```json
{
  "message": "Nama berhasil diperbarui",
  "data": {
    "profile": {
      "id": 1,
      "name": "Andika Sanddi Pranata",
      "npm": "24783072",
      "rfid_uid": "C6 EF 25 07",
      "rfid_status": "active",
      "plate_number": "BE1234AA",
      "vehicle_type": "Motorcycle"
    }
  }
}
```

### 4. Saldo RFID

```http
GET /api/student/balance
Authorization: Bearer {token}
```

Response:

```json
{
  "data": {
    "balance": 95000
  }
}
```

### 5. Kirim Permintaan Top-Up dan Bukti Pembayaran

Ubah endpoint top-up agar menerima `multipart/form-data`:

```http
POST /api/student/topups
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

Field:

```text
amount=50000
payment_proof={file JPG/PNG}
```

Validasi:

```php
'amount' => ['required', 'integer', 'min:1000'],
'payment_proof' => [
    'required',
    'file',
    'image',
    'mimes:jpg,jpeg,png',
    'max:5120',
],
```

Simpan bukti pembayaran pada disk `public`, misalnya:

```text
storage/app/public/topup-proofs/{student_id}/{generated_filename}
```

Jangan gunakan nama file asli secara langsung. Gunakan nama unik seperti UUID.
Pastikan `php artisan storage:link` sudah dijalankan.

Data top-up minimal harus memiliki:

```text
id
student_id
amount
payment_proof_path
status
approved_at
approved_by
rejection_reason
created_at
updated_at
```

Status awal wajib `pending`.

Jika tabel top-up belum memiliki kolom yang dibutuhkan, buat migration tanpa
merusak data lama. Gunakan enum/string status yang mendukung:

```text
pending
approved
rejected
```

Response sukses, status HTTP `201`:

```json
{
  "message": "Permintaan top-up berhasil dikirim",
  "data": {
    "topup": {
      "id": 15,
      "amount": 50000,
      "status": "pending",
      "payment_proof_url": "http://10.42.26.242:8000/storage/topup-proofs/1/example.jpg",
      "created_at": "2026-06-14T10:30:00+07:00"
    }
  }
}
```

### 6. Riwayat Top-Up

```http
GET /api/student/topups
Authorization: Bearer {token}
```

Hanya kembalikan top-up milik mahasiswa yang sedang login. Urutkan paling baru.

Response:

```json
{
  "data": {
    "topups": [
      {
        "id": 15,
        "amount": 50000,
        "status": "pending",
        "payment_proof_url": "http://10.42.26.242:8000/storage/topup-proofs/1/example.jpg",
        "rejection_reason": null,
        "created_at": "2026-06-14T10:30:00+07:00"
      }
    ]
  }
}
```

### 7. Persetujuan Top-Up Oleh Admin

Jika belum tersedia, buat endpoint admin untuk approve dan reject top-up.
Gunakan authorization policy atau middleware role admin.

Saat approve:

- Kunci record top-up dengan `lockForUpdate()`.
- Pastikan status masih `pending`.
- Tambahkan `amount` ke saldo RFID mahasiswa dalam database transaction.
- Ubah status menjadi `approved`.
- Isi `approved_at` dan `approved_by`.
- Catat transaksi top-up.

Saat reject:

- Pastikan status masih `pending`.
- Jangan mengubah saldo.
- Ubah status menjadi `rejected`.
- Simpan `rejection_reason`.

### 8. Riwayat Parkir

```http
GET /api/student/parking-history
Authorization: Bearer {token}
```

Response:

```json
{
  "data": {
    "parking_history": [
      {
        "id": 20,
        "entry_time": "2026-06-10T08:00:00+07:00",
        "exit_time": "2026-06-10T10:00:00+07:00",
        "cost": 2000
      }
    ]
  }
}
```

### 9. Riwayat Transaksi

```http
GET /api/student/transactions
Authorization: Bearer {token}
```

Response:

```json
{
  "data": {
    "transactions": [
      {
        "id": 10,
        "type": "topup",
        "amount": 50000,
        "description": "Balance top up",
        "created_at": "2026-06-14T11:00:00+07:00"
      },
      {
        "id": 11,
        "type": "parking",
        "amount": 2000,
        "description": "Parking payment",
        "created_at": "2026-06-14T14:00:00+07:00"
      }
    ]
  }
}
```

Nilai `type` harus konsisten: `topup` atau `parking`.

### 10. Ubah Password dan Logout

```http
POST /api/student/change-password
POST /api/student/logout
```

Validasi ubah password:

```php
'current_password' => ['required', 'current_password'],
'password' => ['required', 'string', 'min:8', 'confirmed'],
```

Logout harus menghapus token Sanctum yang sedang digunakan.

## Format Error

Gunakan format error Laravel yang konsisten:

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "payment_proof": [
      "Bukti pembayaran wajib diunggah."
    ]
  }
}
```

Gunakan:

- `401` untuk token tidak valid.
- `403` untuk akses yang tidak diizinkan.
- `404` untuk data tidak ditemukan.
- `422` untuk validasi.
- `409` untuk top-up yang sudah diproses.

## CORS dan Akses Jaringan

- Pastikan API dapat diakses dari perangkat pada jaringan yang sama.
- Jalankan Laravel dengan host:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

- Base URL aplikasi Flutter adalah:

```text
http://10.42.26.242:8000
```

- Pastikan firewall port `8000` mengizinkan koneksi lokal.
- Pastikan URL file storage dapat diakses dari perangkat, bukan menggunakan
  `localhost`.

## Pengujian Yang Wajib Dibuat

Buat Feature Test untuk:

1. Mahasiswa dapat mengubah nama sendiri.
2. Mahasiswa tidak dapat mengubah field sensitif.
3. Top-up tanpa bukti ditolak.
4. Top-up dengan gambar valid tersimpan sebagai `pending`.
5. File selain JPG/PNG ditolak.
6. File lebih dari 5 MB ditolak.
7. Mahasiswa hanya melihat top-up miliknya.
8. Approve menambah saldo tepat satu kali.
9. Reject tidak menambah saldo.
10. Top-up yang sudah diproses tidak dapat diproses ulang.

Setelah implementasi:

- Jalankan migration.
- Jalankan `php artisan storage:link`.
- Jalankan test Laravel.
- Tampilkan daftar file yang diubah.
- Tampilkan route API hasil akhir.
- Jelaskan jika nama model, tabel, atau relasi existing berbeda dan sesuaikan
  implementasi dengan struktur project yang ada, bukan membuat duplikasi model.

---
