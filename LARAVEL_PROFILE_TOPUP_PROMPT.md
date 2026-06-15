# Prompt Laravel: Edit Profil dan Bukti Top-Up

Gunakan prompt berikut pada project Laravel Smart Parking:

---

Sesuaikan backend Laravel Smart Parking yang sudah ada agar mendukung dua
perubahan pada aplikasi Flutter MyParking:

1. Mahasiswa dapat mengubah nama profil.
2. Mahasiswa dapat mengirim permintaan top-up beserta bukti pembayaran.

Pelajari dahulu struktur model, tabel, controller, route, autentikasi, dan relasi
yang sudah ada. Gunakan struktur existing dan jangan membuat model atau tabel
duplikat.

## Ketentuan Umum

- Gunakan autentikasi Laravel Sanctum dengan middleware `auth:sanctum`.
- Mahasiswa hanya boleh mengakses dan mengubah data miliknya sendiri.
- Gunakan Form Request untuk validasi.
- Gunakan API Resource atau response JSON yang konsisten.
- Pertahankan endpoint lama yang masih digunakan.
- Jangan menambah saldo saat permintaan top-up dibuat.
- Saldo hanya bertambah setelah top-up disetujui admin.

## 1. Edit Nama Profil

Tambahkan atau sesuaikan endpoint:

```http
PATCH /api/student/profile
Authorization: Bearer {token}
Content-Type: application/json
```

Daftarkan juga method `PUT` pada URL yang sama jika memungkinkan:

```http
PUT /api/student/profile
```

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

Aturan keamanan:

- Ambil mahasiswa dari user/token yang sedang login.
- Jangan menerima `student_id` dari request.
- Hanya field `name` yang boleh diperbarui.
- Abaikan atau tolak perubahan NPM, password, saldo, RFID UID, status RFID,
  kendaraan, dan field sensitif lainnya.

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

Pastikan response mengembalikan profil lengkap agar aplikasi Flutter dapat
langsung memperbarui tampilan.

## 2. Top-Up Dengan Bukti Pembayaran

Sesuaikan endpoint berikut agar menerima multipart:

```http
POST /api/student/topups
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

Field yang dikirim aplikasi Flutter:

```text
amount=50000
payment_proof={file}
```

Validasi:

```php
[
    'amount' => ['required', 'integer', 'min:1000'],
    'payment_proof' => [
        'required',
        'file',
        'image',
        'mimes:jpg,jpeg,png',
        'max:5120',
    ],
]
```

Simpan file pada disk `public`, misalnya:

```text
storage/app/public/topup-proofs/{student_id}/{uuid}.jpg
```

Ketentuan penyimpanan:

- Gunakan UUID atau nama file acak.
- Jangan gunakan nama file asli sebagai nama penyimpanan.
- Simpan path relatif pada kolom `payment_proof_path`.
- Jalankan `php artisan storage:link`.
- URL bukti harus dapat diakses perangkat lain pada jaringan, bukan memakai
  `localhost`.

Jika tabel top-up belum memiliki kolom yang dibutuhkan, buat migration untuk
menambahkan:

```text
payment_proof_path nullable/string
approved_at nullable/timestamp
approved_by nullable/foreign key
rejection_reason nullable/text
```

Gunakan status:

```text
pending
approved
rejected
```

Saat mahasiswa mengirim top-up:

- Ambil `student_id` dari token login.
- Simpan nominal dan bukti pembayaran.
- Set status awal menjadi `pending`.
- Jangan mengubah saldo mahasiswa.
- Gunakan database transaction.

Response sukses dengan HTTP `201`:

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

Pastikan endpoint riwayat berikut juga mengembalikan URL bukti:

```http
GET /api/student/topups
Authorization: Bearer {token}
```

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

Riwayat harus:

- Hanya berisi top-up milik mahasiswa yang sedang login.
- Diurutkan dari data terbaru.
- Tidak membocorkan data mahasiswa lain.

## Approval Admin

Pertahankan atau sesuaikan proses approval admin:

- Gunakan database transaction dan `lockForUpdate()`.
- Top-up hanya dapat diproses jika status masih `pending`.
- Saat approved, tambahkan saldo tepat satu kali.
- Saat rejected, saldo tidak berubah.
- Simpan `approved_at`, `approved_by`, atau `rejection_reason`.
- Kembalikan HTTP `409` jika top-up sudah pernah diproses.

## Format Error

Gunakan format error Laravel:

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

Gunakan status:

- `401` untuk token tidak valid.
- `403` untuk akses tidak diizinkan.
- `422` untuk validasi gagal.
- `409` untuk top-up yang sudah diproses.

## Pengujian

Buat Feature Test untuk memastikan:

1. Mahasiswa dapat mengubah namanya sendiri.
2. Mahasiswa tidak dapat mengubah field sensitif.
3. Top-up tanpa bukti ditolak.
4. Top-up dengan JPG atau PNG valid tersimpan sebagai `pending`.
5. File selain gambar ditolak.
6. File lebih dari 5 MB ditolak.
7. Pengiriman top-up tidak langsung menambah saldo.
8. Mahasiswa hanya dapat melihat top-up miliknya.
9. Approval menambah saldo tepat satu kali.
10. Rejection tidak mengubah saldo.

Setelah implementasi:

- Jalankan migration.
- Jalankan `php artisan storage:link`.
- Jalankan seluruh test Laravel.
- Tampilkan file yang diubah.
- Tampilkan route API terkait profil dan top-up.
- Jelaskan penyesuaian yang dilakukan terhadap struktur project existing.

---
