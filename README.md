# MyParking App (Flutter)

Aplikasi klien seluler berbasis Flutter untuk Sistem Parkir Pintar (Smart Parking) berteknologi RFID berbasis Laravel. Aplikasi ini dirancang khusus untuk mahasiswa agar dapat mengakses informasi profil mereka, mengelola saldo RFID, dan memantau riwayat aktivitas parkir serta transaksi keuangan di kampus.

---

## 🚀 Fitur Utama

- **Autentikasi (Sanctum)**: Mahasiswa dapat login menggunakan kredensial mereka (NPM dan Password). Token sesi dikelola secara aman menggunakan `flutter_secure_storage`.
- **Dashboard Terpusat**: Memantau ringkasan singkat yang mencakup "RFID Balance" yang terhubung (dengan ID Kartu dan Nomor Plat), jumlah kunjungan parkir bulan ini, serta biaya yang telah dihabiskan.
- **Top Up Saldo**: Pengguna dapat melakukan permohonan *top-up* saldo dompet digital RFID. Fitur ini mendukung input nominal custom atau memilih opsi cepat, dan dilengkapi dengan upload bukti gambar/resi pembayaran.
- **Riwayat Parkir & Transaksi**: Memungkinkan pengguna untuk meninjau secara rinci histori parkir kampus lengkap dengan waktu masuk (check-in), waktu keluar (check-out), serta biaya per kunjungan parkir. Daftar riwayat gabungan dari parkir dan top up dapat ditinjau di tab History atau Quick Action Transactions.
- **Sistem Notifikasi Pintar**: Menginformasikan mahasiswa ketika top up berhasil (disetujui oleh admin), saat ada potongan saldo sukses dari gate parkir, dan peringatan batas *Low Balance* jika saldo berada di bawah ketentuan minim.

---

## 💻 Cara Menjalankan

Aplikasi default akan menembak ke *local development server* (IP/localhost).

**1. Jalankan di Emulator atau Perangkat Fisik Lokal**
```powershell
flutter run
```

**2. Ubah URL API (Production/Staging Server)**
Jika server Laravel (API backend) berjalan di cloud/URL yang berbeda, gunakan argumen berikut saat me-*run* aplikasi:
```powershell
flutter run --dart-define=API_BASE_URL=https://namadomain-anda.com
```
*Ganti `https://namadomain-anda.com` dengan URL endpoint backend Anda yang sebenarnya.*

*(URL API default yang digunakan secara bawaan adalah `http://10.42.26.242:8000`)*

---

## 🏗 Struktur Proyek

Proyek ini dibangun dengan struktur *feature-first* berlapis yang bersih:
- `lib/core/` — Mengandung infrastruktur pusat dan utilitas seperti model data (`student_models.dart`), konfigurasi tema (warna, font), alat konversi (`formatters.dart`), komponen widget yang dapat digunakan ulang (seperti `AppCard`, tombol, dan *badge*), serta pengelolaan *state* utama sistem (`AppController`, `ApiClient`, dan reporsitory autentikasi).
- `lib/features/` — Modul fitur terisolasi. 
  - `auth/` (Login & Autentikasi)
  - `dashboard/` (Halaman Home/Overview)
  - `history/` (Halaman histori riwayat yang menyatukan parkir & top-up)
  - `notifications/` (Manajemen notifikasi lokal)
  - `parking_history/` (Detil aktivitas parkir)
  - `profile/` (Manajemen akun, ubah password, dan nama)
  - `topup/` (Modul permintaan top up saldo lengkap dengan QRIS bayangan)
  - `transactions/` (Ringkasan mutasi saldo)

**Manajemen State:** Menggunakan package `Provider` untuk menampung *single truth source* state lokal agar mempermudah sinkronisasi UI seperti notifikasi dan update *balance*.

---

## 🔗 Rangkuman Endpoint API (Backend Integration)

Aplikasi ini bergantung pada beberapa spesifikasi endpoint Laravel backend (di bawah *namespace* `/api/student/`):

*   **Login**: `POST /login`
*   **Logout**: `POST /logout`
*   **Profil**: `GET /profile`
*   **Update Profil**: `PATCH` atau `PUT /profile`
*   **Ganti Password**: `POST /change-password`
*   **Info Saldo**: `GET /balance`
*   **Riwayat Parkir**: `GET /parking-history`
*   **List Transaksi/Mutasi**: `GET /transactions`
*   **Histori Top Up**: `GET /topup-history`
*   **Request Top Up Baru**: `POST /request-topup` (Dikirim via `multipart/form-data` dengan payload berisi `amount` dan file gambar `payment_proof`).

*Sistem bergantung pada data bertipe format JSON responsif. Token bearer dan unauthenticated status dipantau oleh `SessionStorage`.*