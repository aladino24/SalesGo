# Requirements — Mobile Sales Force Automation (SFA)

## 1. Project Overview

Buat aplikasi mobile **Sales Force Automation (SFA)** untuk perusahaan FMCG menggunakan:

- **Flutter**
- **Dart**
- **GetX** sebagai state management
- Local storage untuk mendukung **offline-first**
- REST API sebagai komunikasi dengan backend/server
- Aplikasi harus tetap dapat digunakan ketika tidak ada koneksi internet.
- Data yang dibuat/diubah ketika offline harus disimpan secara lokal dan otomatis dikirim ke server ketika koneksi internet kembali tersedia.

Aplikasi digunakan oleh beberapa role:

1. Sales
2. Supervisor
3. Branch Manager
4. Key Account Manager

Aplikasi harus memiliki desain modern, profesional, ringan, mudah digunakan oleh sales yang banyak bekerja di lapangan, dan tetap optimal pada berbagai ukuran layar Android.

---

# 2. Tujuan Aplikasi

Aplikasi bertujuan untuk membantu aktivitas sales FMCG, antara lain:

- Monitoring aktivitas sales
- Monitoring omset
- Monitoring target dan achievement
- Monitoring insentif
- Pengelolaan perjalanan sales
- Pengelolaan kunjungan outlet
- Check-in dan checkout outlet
- Penjualan produk
- Pembelian
- Retur
- Piutang
- Pemberian hadiah ke outlet
- Catatan kunjungan
- Aktivitas outlet
- Informasi produk dan promosi
- Distribusi file penting untuk sales
- Approval oleh Supervisor / Branch Manager / role terkait
- Sinkronisasi data online dan offline
- Monitoring lokasi sales
- Meeting online
- Remote support

---

# 3. Prinsip Utama Aplikasi

## 3.1 Offline First

Aplikasi harus menerapkan konsep **offline-first**.

Ketika internet tersedia:

```text
Mobile App
    ↓
API Server
    ↓
Database Server
```

Ketika internet tidak tersedia:

```text
Mobile App
    ↓
Local Storage
```

Ketika internet kembali:

```text
Local Storage
    ↓
Sync Manager
    ↓
API Server
    ↓
Database Server
```

Data lokal tidak boleh hilang ketika aplikasi ditutup atau device restart.

---

# 4. Local Storage

Gunakan local storage yang sesuai untuk Flutter.

Prioritaskan penggunaan:

- Hive / Hive CE
- SQLite jika diperlukan untuk data relasional yang kompleks

Pisahkan data menjadi:

### Master Data

Contoh:

- Produk
- Outlet
- Kategori produk
- Tipe outlet
- Area
- Sales
- Target
- Promo
- Banner
- File penting
- Konfigurasi aplikasi

### Transaction Data

Contoh:

- Visit
- Check-in
- Checkout
- Sales order
- Pembelian
- Retur
- Piutang
- Pemberian hadiah
- Catatan
- Perjalanan
- Approval
- Aktivitas outlet

### Sync Data

Sediakan tabel/collection khusus untuk:

- Pending create
- Pending update
- Pending delete
- Failed synchronization
- Last sync
- Sync status

Contoh status:

```text
pending
syncing
success
failed
conflict
```

---

# 5. Authentication

Aplikasi memiliki halaman:

## Login

Field:

- Username
- Password

Fitur:

- Login
- Logout
- Remember session
- Token authentication
- Refresh token jika backend mendukung
- Menyimpan session secara aman
- Menampilkan informasi versi aplikasi

Setelah login:

```text
Login
  ↓
Validasi user
  ↓
Ambil role
  ↓
Download initial/master data
  ↓
Home
```

Jika user sebelumnya sudah login dan session masih valid, aplikasi dapat langsung masuk ke Home.

---

# 6. Role & Permission

## 6.1 Sales

Sales dapat:

- Melihat dashboard
- Memulai perjalanan
- Melihat daftar kunjungan
- Melihat peta outlet
- Check-in outlet
- Melihat detail outlet
- Membuat penjualan
- Membuat pembelian
- Membuat retur
- Melihat piutang
- Memberikan hadiah
- Membuat catatan
- Melihat history visit
- Checkout
- Menunda kunjungan
- Membatalkan kunjungan dengan alasan
- Melihat promosi
- Download file penting
- Mengikuti meeting online
- Melihat insentif
- Melihat target dan achievement
- Sinkronisasi data
- Menggunakan remote support

---

## 6.2 Supervisor

Supervisor dapat:

- Melihat dashboard
- Melihat aktivitas sales
- Melihat kunjungan sales
- Monitoring lokasi sales
- Melihat achievement sales
- Melihat target sales
- Melihat omset
- Melihat kunjungan yang belum tercapai
- Melihat alasan pembatalan/penundaan
- Melakukan approval sesuai permission
- Melihat laporan aktivitas team

---

## 6.3 Branch Manager

Branch Manager dapat:

- Melihat dashboard cabang
- Monitoring sales
- Monitoring omset
- Monitoring achievement
- Monitoring kunjungan
- Melihat aktivitas sales
- Melihat perjalanan sales
- Melihat surat jalan
- Melakukan approval kunjungan yang tidak tercapai
- Melakukan approval surat jalan
- Melakukan approval transaksi tertentu
- Melakukan approval lainnya sesuai permission
- Melihat laporan cabang

Contoh:

```text
Visit tidak tercapai
        ↓
Sales memberikan alasan
        ↓
Supervisor / Branch Manager
        ↓
Review
        ↓
Approve / Reject
```

---

## 6.4 Key Account Manager

Key Account Manager dapat:

- Melihat outlet/key account
- Monitoring penjualan
- Monitoring target
- Monitoring achievement
- Melihat produk
- Melihat promosi
- Melihat history transaksi
- Monitoring aktivitas account
- Melihat laporan
- Melakukan approval sesuai permission

---

# 7. Struktur Navigasi Utama

Gunakan Bottom Navigation / Navigation Rail sesuai ukuran device.

Menu utama:

```text
Home
Kunjungan
Promosi
Setting
```

Menu tambahan dapat ditampilkan melalui:

- Drawer
- More menu
- Shortcut pada Home

---

# 8. HOME / DASHBOARD

Home merupakan halaman utama aplikasi.

Home harus menampilkan informasi yang relevan dengan role user.

## Informasi Dashboard Sales

Tampilkan:

### Omset

- Omset hari ini
- Omset minggu berjalan
- Omset bulan berjalan
- Omset tahun berjalan
- Target
- Achievement
- Persentase achievement

Contoh:

```text
Target Bulan
Rp 500.000.000

Achievement
Rp 375.000.000

75%
```

---

## Insentif

Tampilkan:

- Estimasi insentif
- Insentif periode berjalan
- Insentif periode sebelumnya
- Progress insentif
- Detail insentif

---

## Chart

Sediakan chart seperti:

- Omset harian
- Omset mingguan
- Omset bulanan
- Target vs achievement
- Produk terlaris
- Achievement per outlet
- Trend penjualan

Chart harus responsive dan dapat menampilkan informasi melalui tooltip.

---

# 9. Sales Activity

Home juga menampilkan aktivitas sales.

Contoh:

```text
Today's Activity

08:10  Mulai perjalanan
08:45  Check-in Outlet A
09:30  Membuat Sales Order
10:15  Checkout Outlet A
11:00  Check-in Outlet B
```

Informasi:

- Waktu
- Jenis aktivitas
- Outlet
- Status
- Lokasi jika diperlukan

---

# 10. Meeting Online

Home memiliki shortcut:

```text
Meeting Online
```

Fitur:

- Daftar meeting
- Meeting hari ini
- Jadwal meeting
- Link meeting
- Status meeting
- Tombol Join Meeting

Jika menggunakan external meeting provider, gunakan deep link.

---

# 11. PERJALANAN SALES

Sales dapat memulai perjalanan melalui Home.

Terdapat dua tipe perjalanan:

## 11.1 Dalam Kota

Perjalanan hanya berlaku satu hari.

Flow:

```text
Mulai Perjalanan
      ↓
Pilih Dalam Kota
      ↓
Konfirmasi
      ↓
Perjalanan aktif
      ↓
Kunjungan
      ↓
Selesai perjalanan
```

---

## 11.2 Luar Kota

Perjalanan dapat berlangsung beberapa hari.

Flow:

```text
Mulai Perjalanan
      ↓
Pilih Luar Kota
      ↓
Tanggal mulai
      ↓
Tanggal selesai
      ↓
Tujuan
      ↓
Konfirmasi
      ↓
Perjalanan aktif
```

Data perjalanan:

- Jenis perjalanan
- Tujuan
- Tanggal mulai
- Tanggal selesai
- Status
- Sales
- Surat jalan
- Approval

---

# 12. SURAT JALAN

Sales dapat membawa / menggunakan surat jalan.

Informasi:

- Nomor surat jalan
- Tanggal
- Sales
- Tujuan
- Outlet/customer
- Detail barang jika diperlukan
- Status approval
- Status penggunaan

Status:

```text
Draft
Submitted
Waiting Approval
Approved
Rejected
Completed
```

Branch Manager dapat melakukan approval surat jalan.

---

# 13. MENU KUNJUNGAN

Halaman Kunjungan merupakan fitur utama aplikasi.

Tampilkan:

- Map
- Current location sales
- Outlet
- Route
- Jarak
- Estimasi perjalanan
- Total outlet
- Total kunjungan
- Kunjungan dalam proses
- Kunjungan selesai
- Kunjungan tertunda
- Kunjungan dibatalkan

---

# 14. MAP KUNJUNGAN

Map menampilkan:

```text
Current Sales Location
        ↓
        📍 Sales

        ↓ Route

        🏪 Outlet
```

Informasi outlet:

- Nama outlet
- Alamat
- Tipe outlet
- Jarak
- Estimasi waktu
- Status kunjungan

Gunakan GPS/geolocation.

Pastikan permission lokasi ditangani dengan baik.

---

# 15. STATUS KUNJUNGAN

Status utama:

```text
Planned
On Route
In Progress
Completed
Pending
Cancelled
Failed
```

Dashboard kunjungan:

```text
Total Outlet       25
Completed          10
In Progress         1
Pending             8
Cancelled           2
Failed              4
```

---

# 16. CHECK-IN OUTLET

Sales dapat melakukan check-in ketika berada di outlet.

Flow:

```text
Pilih Outlet
    ↓
Validasi lokasi
    ↓
Check-in
    ↓
Outlet Detail
```

Validasi dapat mencakup:

- GPS aktif
- Jarak dari outlet
- Radius maksimal
- Timestamp
- User
- Outlet

Jika berada di luar radius:

```text
Anda berada di luar area outlet.
Silakan mendekati lokasi outlet.
```

Jika bisnis membutuhkan override:

```text
Check-in di luar radius
       ↓
Input alasan
       ↓
Submit
       ↓
Approval
```

---

# 17. HALAMAN DETAIL OUTLET

Setelah check-in, tampilkan halaman outlet.

Informasi:

### Informasi Outlet

- Nama outlet
- Kode outlet
- Alamat
- Tipe outlet
- Owner/contact
- Nomor telepon
- GPS
- Sales responsible

### Performance

- Target omset
- Achievement
- Persentase achievement
- Top product
- Produk belum terjual
- Produk dengan potensi

---

# 18. VISIT HISTORY

Tampilkan history kunjungan:

```text
12 Aug 2026
Visit Completed
Omset Rp 5.500.000

05 Aug 2026
Visit Completed
Omset Rp 4.800.000

29 Jul 2026
Visit Cancelled
Alasan: Outlet tutup
```

Detail history dapat dibuka.

---

# 19. FITUR OUTLET

Pada detail outlet tersedia menu:

```text
Informasi
Penjualan
Pembelian
Retur
Catatan
Piutang
Hadiah
Aktivitas
History Visit
Telepon
```

---

# 20. TELEPON

Tombol telepon harus membuka aplikasi telepon device.

Contoh:

```text
Call Outlet
```

Gunakan permission/device API yang sesuai.

---

# 21. PENJUALAN

Sales dapat membuat transaksi penjualan.

Informasi:

- Produk
- Quantity
- Harga
- Discount
- Total
- Catatan
- Tanggal transaksi

Flow:

```text
Outlet
 ↓
Penjualan
 ↓
Tambah Produk
 ↓
Quantity
 ↓
Harga
 ↓
Discount
 ↓
Total
 ↓
Submit
```

Jika offline:

```text
Save Local
↓
Pending Sync
```

---

# 22. PEMBELIAN

Tampilkan informasi pembelian outlet.

Dapat berupa:

- History pembelian
- Produk
- Quantity
- Harga
- Total
- Tanggal

Jika user memiliki permission untuk membuat pembelian, sediakan form transaksi.

---

# 23. RETUR

Sales dapat membuat retur.

Data:

- Produk
- Quantity
- Alasan retur
- Kondisi barang
- Foto jika diperlukan
- Catatan

Status:

```text
Draft
Submitted
Approved
Rejected
Completed
```

---

# 24. PIUTANG

Tampilkan:

- Total piutang
- Piutang jatuh tempo
- Piutang overdue
- Riwayat pembayaran
- Detail invoice

Contoh:

```text
Total Piutang
Rp 25.000.000

Jatuh Tempo
Rp 10.000.000

Overdue
Rp 5.000.000
```

---

# 25. PEMBERIAN HADIAH

Sales dapat mencatat pemberian hadiah kepada outlet.

Data:

- Jenis hadiah
- Quantity
- Alasan
- Program
- Tanggal
- Foto jika diperlukan
- Catatan

Data harus tersimpan secara offline jika internet tidak tersedia.

---

# 26. CATATAN OUTLET

Sales dapat membuat catatan.

Contoh:

```text
Catatan:
Owner meminta tambahan display produk.
```

Data:

- Catatan
- Tanggal
- User
- Outlet
- Foto/attachment jika diperlukan

---

# 27. AKTIVITAS KUNJUNGAN

Catat aktivitas selama visit.

Contoh:

```text
Check-in
Survey
Presentasi Produk
Order
Follow Up
Pemberian Hadiah
Catatan
Checkout
```

Aktivitas memiliki:

- Timestamp
- User
- Outlet
- GPS
- Activity type
- Description

---

# 28. CHECKOUT

Setelah aktivitas selesai:

```text
Checkout
    ↓
Validasi aktivitas
    ↓
Input catatan jika diperlukan
    ↓
Checkout
    ↓
Visit Completed
```

Simpan:

- Checkout time
- GPS
- User
- Outlet
- Visit ID

---

# 29. TUNDA KUNJUNGAN

Sales dapat menunda visit.

Form:

- Alasan
- Tanggal/waktu kunjungan berikutnya
- Catatan

Status:

```text
Pending / Rescheduled
```

---

# 30. BATALKAN KUNJUNGAN

Sales dapat membatalkan visit dengan alasan.

Alasan contoh:

- Outlet tutup
- Owner tidak berada di tempat
- Kendala kendaraan
- Cuaca
- Outlet tidak dapat dikunjungi
- Alasan lainnya

Field:

```text
Reason
Description
Photo evidence (optional)
```

Visit yang dibatalkan harus masuk ke daftar approval jika policy perusahaan mengharuskan approval.

---

# 31. APPROVAL KUNJUNGAN

Jika kunjungan tidak tercapai, sales harus memberikan alasan.

Flow:

```text
Visit Failed / Cancelled
        ↓
Reason
        ↓
Submit
        ↓
Waiting Approval
        ↓
Supervisor / Branch Manager
        ↓
Approve / Reject
```

Branch Manager memiliki permission untuk approval kunjungan yang tidak tercapai.

Approval harus menyimpan:

- Approver
- Timestamp
- Status
- Comment
- Reason
- Visit ID

---

# 32. MENU PROMOSI

Menu Promosi berisi informasi untuk membantu sales menjual produk.

Isi:

### Produk

- Daftar produk
- Nama produk
- SKU
- Kategori
- Harga
- Deskripsi
- Foto
- Informasi produk

### Banner

- Banner promo
- Campaign
- Periode promo
- Detail promo

### Program Promo

- Nama program
- Periode
- Syarat
- Benefit
- Produk terkait
- Outlet terkait

---

# 33. FILE PENTING UNTUK SALES

Sediakan section:

```text
File Penting
```

Contoh:

- Price list
- Product catalog
- SOP
- Sales guideline
- Promo document
- Form
- Materi training
- Dokumen perusahaan

File dapat:

- Dilihat
- Didownload
- Dibuka
- Dihapus dari local cache

Metadata:

- Nama file
- File type
- Size
- Version
- Last updated
- Download status

---

# 34. SETTINGS

Halaman Setting berisi:

```text
Account
Sync Data
Brightness
Delete All Data
Logout
Remote QuickSupport
App Version
```

---

# 35. DOWNLOAD ULANG DATA ONLINE

Fitur:

```text
Download Data Terbaru
```

Digunakan untuk mengambil master data terbaru dari server.

Flow:

```text
Setting
 ↓
Download Data Terbaru
 ↓
Check Internet
 ↓
Download
 ↓
Validate
 ↓
Update Local Database
 ↓
Success
```

Tampilkan:

- Progress
- Data yang sedang di-download
- Jumlah data
- Last sync
- Error jika terjadi

Jangan menghapus data lokal terlebih dahulu sebelum data baru berhasil divalidasi.

---

# 36. SYNC MANAGER

Buat komponen khusus:

```text
SyncManager
```

Tanggung jawab:

- Mendeteksi koneksi
- Mengirim pending transaction
- Mengambil data terbaru
- Retry failed request
- Menangani conflict
- Menyimpan sync log
- Menampilkan status sync

Contoh:

```text
Internet OFF
    ↓
Transaction → Local
    ↓
Pending

Internet ON
    ↓
SyncManager
    ↓
API
    ↓
Success
    ↓
Mark as Synced
```

Retry menggunakan mekanisme yang aman.

Jangan membuat duplicate transaction ketika request sebelumnya sebenarnya sudah berhasil tetapi response tidak diterima oleh device.

Gunakan:

- UUID
- Idempotency key
- Local transaction ID

---

# 37. NETWORK STATUS

Aplikasi harus mengetahui status:

```text
Online
Offline
Synchronizing
Sync Failed
```

Tampilkan indikator kecil jika diperlukan:

```text
Offline Mode
```

atau:

```text
Syncing...
```

---

# 38. DELETE ALL DATA

Setting menyediakan:

```text
Hapus Semua Data
```

Gunakan confirmation dialog.

Contoh:

```text
Apakah Anda yakin?

Semua data lokal akan dihapus dari perangkat.
Data yang belum tersinkronisasi dapat hilang.

[ Batal ] [ Hapus ]
```

Jika masih terdapat transaksi pending:

```text
Terdapat 5 transaksi yang belum tersinkronisasi.
Silakan sinkronisasi terlebih dahulu.
```

Jangan menghapus pending transaction tanpa konfirmasi eksplisit.

---

# 39. LOGOUT

Flow:

```text
Setting
 ↓
Logout
 ↓
Confirmation
 ↓
Clear Session
 ↓
Login
```

Data master lokal dapat dipertahankan atau dihapus sesuai policy.

Jangan otomatis menghapus transaksi pending ketika logout.

---

# 40. REMOTE QUICKSUPPORT

Sediakan menu:

```text
Remote QuickSupport
```

Tujuannya untuk membantu tim IT melakukan support kepada user.

Fitur dapat:

- Menampilkan informasi device
- App version
- OS version
- Device model
- User ID
- Branch
- Network status
- Support ID/session
- Membuka aplikasi remote support jika tersedia

Integrasi remote support harus menggunakan mekanisme resmi/provider yang digunakan perusahaan.

Jangan membuat akses remote device secara custom tanpa mekanisme keamanan dan persetujuan user.

---

# 41. LOCATION TRACKING

Karena aplikasi digunakan oleh sales lapangan, lokasi merupakan bagian penting.

Gunakan:

- GPS
- Latitude
- Longitude
- Accuracy
- Timestamp

Gunakan lokasi untuk:

- Check-in
- Checkout
- Visit
- Perjalanan
- Monitoring aktivitas jika diperlukan oleh business requirement

Background location hanya digunakan jika memang diperlukan oleh requirement perusahaan dan harus mengikuti permission Android/iOS.

---

# 42. CAMERA

Camera dapat digunakan untuk:

- Foto bukti kunjungan
- Foto retur
- Foto outlet
- Foto aktivitas
- Bukti pemberian hadiah
- Dokumentasi lainnya

Foto harus dapat disimpan sementara secara lokal ketika offline.

Setelah internet tersedia:

```text
Local Image
 ↓
Upload Queue
 ↓
Server
```

---

# 43. NOTIFICATION

Gunakan notification untuk:

- Meeting
- Approval
- Visit reminder
- Sync selesai
- Sync gagal
- Promo baru
- Informasi penting

---

# 44. GETX ARCHITECTURE

Gunakan GetX secara konsisten.

Contoh struktur:

```text
lib/
├── app/
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   │
│   ├── bindings/
│   │   └── initial_binding.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   │
│   └── constants/
│
├── core/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── network_info.dart
│   │   └── api_exception.dart
│   │
│   ├── storage/
│   │   ├── local_storage.dart
│   │   └── sync_storage.dart
│   │
│   ├── sync/
│   │   ├── sync_manager.dart
│   │   ├── sync_queue.dart
│   │   └── sync_worker.dart
│   │
│   ├── location/
│   ├── camera/
│   ├── permissions/
│   └── utils/
│
├── data/
│   ├── models/
│   ├── repositories/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   └── services/
│
├── modules/
│   ├── auth/
│   ├── home/
│   ├── visit/
│   ├── outlet/
│   ├── sales/
│   ├── purchase/
│   ├── return/
│   ├── receivable/
│   ├── gift/
│   ├── promotion/
│   ├── journey/
│   ├── delivery_note/
│   ├── approval/
│   ├── meeting/
│   ├── files/
│   ├── settings/
│   └── remote_support/
│
├── widgets/
│   ├── common/
│   ├── charts/
│   ├── cards/
│   ├── buttons/
│   └── dialogs/
│
└── main.dart
```

---

# 45. Pattern Controller

Setiap feature menggunakan pola:

```text
View
 ↓
Controller
 ↓
Repository
 ↓
Local / Remote Data Source
```

Contoh:

```text
VisitPage
   ↓
VisitController
   ↓
VisitRepository
   ↓
LocalDataSource
   +
RemoteDataSource
```

Controller tidak boleh langsung melakukan HTTP request.

---

# 46. Repository Pattern

Repository bertanggung jawab menentukan sumber data.

Contoh:

```dart
if (isOnline) {
    return remoteDataSource.getVisits();
}

return localDataSource.getVisits();
```

Untuk transaction:

```text
Create Transaction
      ↓
Save Local
      ↓
Add Sync Queue
      ↓
Return Success to UI
```

Kemudian:

```text
SyncManager
      ↓
Read Queue
      ↓
Send API
      ↓
Success
      ↓
Remove Queue
```

---

# 47. UI/UX

Desain harus:

- Modern
- Profesional
- Clean
- Mudah digunakan di lapangan
- Tombol utama mudah dijangkau
- Tidak terlalu banyak informasi dalam satu layar
- Menggunakan card untuk informasi penting
- Menggunakan warna status yang konsisten
- Loading state jelas
- Empty state jelas
- Error state jelas
- Offline state jelas

Gunakan responsive layout.

Hindari hardcoded:

```dart
width: 300
height: 500
```

Gunakan:

- MediaQuery
- LayoutBuilder
- Flexible
- Expanded
- Responsive utility

---

# 48. Loading State

Setiap proses network harus mempunyai state:

```text
Initial
Loading
Success
Empty
Error
Offline
Syncing
```

Hindari UI blank ketika API sedang loading.

Gunakan:

- Skeleton
- Progress indicator
- Empty state
- Error state

---

# 49. Error Handling

Error harus user-friendly.

Jangan tampilkan:

```text
SocketException: Failed host lookup...
```

Tampilkan:

```text
Tidak dapat terhubung ke server.
Silakan periksa koneksi internet Anda.
```

Untuk offline:

```text
Anda sedang offline.
Data akan disinkronkan ketika koneksi tersedia.
```

---

# 50. Security

Implementasikan:

- Secure token storage
- HTTPS
- Token expiration handling
- Logout ketika token invalid
- Permission based UI
- Role based access
- Jangan menyimpan password secara plain text
- Validasi input
- Jangan menampilkan data sensitif pada log production

---

# 51. API Layer

Buat API client terpusat.

Contoh:

```text
ApiClient
├── GET
├── POST
├── PUT
├── PATCH
└── DELETE
```

Tambahkan interceptor untuk:

- Authorization
- Token refresh
- Logging development
- Error handling

Base URL harus berasal dari configuration/env.

Jangan hardcode URL API di dalam controller.

---

# 52. Pagination

Data yang besar harus menggunakan pagination.

Contoh:

- Outlet
- Product
- Visit history
- Sales history
- Approval
- Activity
- Receivable
- Promotion

Gunakan:

```text
page
limit
offset
cursor
```

sesuai API backend.

---

# 53. Search & Filter

Tambahkan search/filter pada halaman yang membutuhkan.

Contoh:

### Outlet

- Nama
- Kode
- Area
- Tipe outlet
- Status

### Visit

- Tanggal
- Status
- Outlet
- Sales

### Product

- SKU
- Nama
- Kategori

### Approval

- Status
- Sales
- Tanggal
- Jenis approval

---

# 54. Approval Center

Untuk Supervisor / Branch Manager / role yang memiliki permission, sediakan:

```text
Approval Center
```

Kategori:

- Visit approval
- Surat jalan approval
- Transaction approval
- Return approval
- Other approval

Contoh:

```text
Pending Approval
----------------
Visit #VIS001
Outlet ABC
Reason: Outlet Tutup

[Reject] [Approve]
```

---

# 55. Audit Trail

Semua aktivitas penting harus memiliki audit information:

```text
createdBy
createdAt
updatedBy
updatedAt
approvedBy
approvedAt
```

Untuk transaksi penting tambahkan:

```text
deviceId
latitude
longitude
```

jika diperlukan oleh backend/business rule.

---

# 56. Sync Conflict

Jika data berubah baik di server maupun lokal:

```text
Local Version
Server Version
      ↓
Conflict Detection
      ↓
Business Rule
```

Jangan melakukan overwrite secara sembarangan.

Conflict resolution harus dapat dikonfigurasi sesuai jenis data.

---

# 57. App Lifecycle

Aplikasi harus menangani:

- App foreground
- App background
- App terminated
- Device restart
- Network reconnect

Ketika aplikasi kembali aktif:

```text
Check Network
     ↓
Check Pending Sync
     ↓
Sync
```

---

# 58. Performance

Aplikasi harus:

- Tidak melakukan API call berulang tanpa kebutuhan
- Menggunakan pagination
- Menggunakan cache
- Mengoptimalkan gambar
- Tidak melakukan rebuild widget secara berlebihan
- Menggunakan lazy loading
- Menghindari blocking main thread
- Menggunakan background processing jika diperlukan

---

# 59. Logging

Development:

```text
API Request
API Response
Sync
Database
Navigation
Error
```

Production:

- Jangan log token
- Jangan log password
- Jangan log data sensitif
- Gunakan crash/error reporting jika tersedia

---

# 60. Environment

Pisahkan environment:

```text
Development
Staging
Production
```

Contoh:

```text
.env.development
.env.staging
.env.production
```

Konfigurasi minimal:

```text
API_BASE_URL
APP_ENV
API_TIMEOUT
```

---

# 61. Deep Link

Jika diperlukan untuk:

- Meeting
- File
- Remote support
- Notification
- Approval

Aplikasi harus dapat menangani deep link.

---

# 62. Minimum Technical Requirements

Gunakan:

```text
Flutter
Dart
GetX
REST API
Offline First
Local Database
Repository Pattern
Dependency Injection
Responsive UI
```

Jangan menggunakan state management lain sebagai state management utama.

GetX digunakan untuk:

- Controller
- Reactive state
- Dependency injection
- Routing

---

# 63. Recommended GetX Controller Pattern

Contoh:

```dart
class VisitController extends GetxController {
  final isLoading = false.obs;
  final isSyncing = false.obs;

  final visits = <VisitModel>[].obs;

  Future<void> loadVisits() async {
    try {
      isLoading.value = true;

      final result = await repository.getVisits();

      visits.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }
}
```

Jangan menaruh business logic besar langsung di Widget.

---

# 64. Model Requirements

Gunakan model yang jelas.

Contoh:

```text
UserModel
SalesModel
OutletModel
ProductModel
VisitModel
JourneyModel
DeliveryNoteModel
SalesOrderModel
PurchaseModel
ReturnModel
ReceivableModel
GiftModel
PromotionModel
FileModel
ApprovalModel
ActivityModel
SyncQueueModel
```

---

# 65. ID Strategy

Setiap transaksi offline harus mempunyai local ID unik.

Contoh:

```text
UUID
```

Ketika sync berhasil:

```text
localId
serverId
```

keduanya dapat disimpan untuk mapping.

---

# 66. Acceptance Criteria

## Authentication

- [ ] User dapat login
- [ ] Role berhasil dikenali
- [ ] Session dapat dipertahankan
- [ ] Logout berhasil
- [ ] Token expired ditangani

## Dashboard

- [ ] Omset tampil
- [ ] Target tampil
- [ ] Achievement tampil
- [ ] Insentif tampil
- [ ] Chart tampil
- [ ] Activity tampil
- [ ] Meeting dapat diakses

## Journey

- [ ] Sales dapat memulai perjalanan
- [ ] Dalam kota dapat dibuat satu hari
- [ ] Luar kota dapat dibuat beberapa hari
- [ ] Status perjalanan tersimpan
- [ ] Surat jalan dapat digunakan
- [ ] Approval surat jalan tersedia

## Visit

- [ ] Outlet tampil di map
- [ ] Current location tampil
- [ ] Jarak tampil
- [ ] Estimasi tampil
- [ ] Check-in dapat dilakukan
- [ ] GPS validation berjalan
- [ ] Detail outlet tersedia
- [ ] Checkout berjalan
- [ ] Visit dapat ditunda
- [ ] Visit dapat dibatalkan
- [ ] Reason wajib ketika diperlukan
- [ ] Visit tidak tercapai dapat diajukan approval

## Outlet

- [ ] Informasi outlet tersedia
- [ ] Target tersedia
- [ ] Achievement tersedia
- [ ] Top product tersedia
- [ ] History visit tersedia
- [ ] Penjualan tersedia
- [ ] Pembelian tersedia
- [ ] Retur tersedia
- [ ] Piutang tersedia
- [ ] Hadiah tersedia
- [ ] Catatan tersedia
- [ ] Aktivitas tersedia
- [ ] Telepon tersedia

## Promotion

- [ ] Product information tersedia
- [ ] Banner tersedia
- [ ] Promo tersedia
- [ ] File penting tersedia
- [ ] File dapat di-download

## Offline

- [ ] Aplikasi dapat digunakan tanpa internet
- [ ] Data transaksi tersimpan lokal
- [ ] Pending transaction masuk queue
- [ ] Network reconnect terdeteksi
- [ ] Sync otomatis berjalan
- [ ] Retry berjalan ketika sync gagal
- [ ] Duplicate transaction dapat dicegah
- [ ] Sync status dapat dilihat

## Approval

- [ ] Approval center tersedia
- [ ] Branch Manager dapat approve visit
- [ ] Branch Manager dapat approve surat jalan
- [ ] Status approval dapat dilihat
- [ ] Reject membutuhkan alasan jika business rule mengharuskan
- [ ] Approval memiliki audit trail

## Settings

- [ ] Download data terbaru tersedia
- [ ] Brightness setting tersedia
- [ ] Delete local data tersedia
- [ ] Logout tersedia
- [ ] Remote QuickSupport tersedia
- [ ] App version tersedia

---

# 67. Development Rules untuk AI Agent

AI Agent yang mengimplementasikan project ini harus mengikuti aturan berikut:

1. Jangan mengubah arsitektur existing tanpa alasan yang jelas.
2. Jangan membuat business logic di Widget.
3. Gunakan GetX Controller untuk state management.
4. Gunakan Repository Pattern.
5. Pisahkan Local Data Source dan Remote Data Source.
6. Semua transaksi penting harus mendukung offline.
7. Jangan menghapus data lokal secara otomatis tanpa confirmation.
8. Jangan membuat API call langsung dari Widget.
9. Jangan hardcode API URL.
10. Jangan hardcode token.
11. Jangan menyimpan password secara plain text.
12. Gunakan reusable widget.
13. Gunakan model untuk representasi data.
14. Gunakan UUID untuk transaksi offline.
15. Setiap transaksi offline harus masuk Sync Queue.
16. Jangan membuat duplicate transaction ketika melakukan retry.
17. Semua halaman harus mempunyai loading, empty, error, dan offline state.
18. Gunakan responsive UI.
19. Jangan menggunakan nilai ukuran yang terlalu banyak di-hardcode.
20. Jangan menghapus existing feature ketika menambahkan feature baru.
21. Sebelum membuat perubahan besar, analisis struktur project terlebih dahulu.
22. Jika project existing memiliki convention tertentu, ikuti convention tersebut.
23. Jangan menambahkan dependency baru jika functionality dapat dibuat menggunakan dependency yang sudah tersedia.
24. Jika dependency baru benar-benar diperlukan, jelaskan alasan dan dampaknya.
25. Jangan mengubah Flutter SDK, Dart SDK, Android Gradle Plugin, Kotlin, minSdk, compileSdk, atau konfigurasi build lainnya tanpa kebutuhan teknis yang jelas.
26. Setelah implementasi, lakukan `flutter analyze`.
27. Jalankan test yang relevan.
28. Perbaiki error compilation sebelum menyelesaikan task.
29. Jangan menganggap task selesai hanya karena kode sudah dibuat.
30. Pastikan flow UI dapat digunakan end-to-end.

---

# 68. Development Priority

Implementasi dilakukan bertahap.

## Phase 1 — Foundation

- [ ] Project architecture
- [ ] Theme
- [ ] Routing
- [ ] GetX bindings
- [ ] API client
- [ ] Local storage
- [ ] Network detection
- [ ] Authentication
- [ ] Session management

## Phase 2 — Dashboard

- [ ] Home
- [ ] Omset
- [ ] Target
- [ ] Achievement
- [ ] Insentif
- [ ] Chart
- [ ] Sales activity
- [ ] Meeting

## Phase 3 — Journey

- [ ] Journey
- [ ] Dalam kota
- [ ] Luar kota
- [ ] Surat jalan
- [ ] Approval

## Phase 4 — Visit

- [ ] Map
- [ ] Outlet
- [ ] GPS
- [ ] Check-in
- [ ] Outlet detail
- [ ] Visit history
- [ ] Checkout
- [ ] Reschedule
- [ ] Cancel
- [ ] Approval

## Phase 5 — Outlet Transaction

- [ ] Sales
- [ ] Purchase
- [ ] Return
- [ ] Receivable
- [ ] Gift
- [ ] Notes
- [ ] Activity

## Phase 6 — Promotion

- [ ] Product
- [ ] Banner
- [ ] Promotion
- [ ] Important files

## Phase 7 — Offline & Sync

- [ ] Sync queue
- [ ] Automatic sync
- [ ] Retry
- [ ] Conflict handling
- [ ] Upload queue
- [ ] Sync monitoring

## Phase 8 — Settings

- [ ] Download latest data
- [ ] Brightness
- [ ] Delete data
- [ ] Logout
- [ ] Remote QuickSupport
- [ ] App information

## Phase 9 — Testing

- [ ] Unit test
- [ ] Controller test
- [ ] Repository test
- [ ] Offline test
- [ ] Sync test
- [ ] GPS test
- [ ] Approval test
- [ ] Integration test
- [ ] UI test

---

# 69. Final Expected Architecture

Target architecture:

```text
                         ┌──────────────────────┐
                         │      Flutter UI      │
                         │       GetX View      │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      GetX Controller │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │     Repository       │
                         └──────────┬───────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
          ┌──────────────────┐            ┌──────────────────┐
          │ Local DataSource │            │ Remote DataSource│
          │ Hive / SQLite    │            │ REST API         │
          └────────┬─────────┘            └────────┬─────────┘
                   │                               │
                   │                               ▼
                   │                     ┌──────────────────┐
                   │                     │    API Server    │
                   │                     └────────┬─────────┘
                   │                              │
                   │                              ▼
                   │                     ┌──────────────────┐
                   │                     │ Server Database  │
                   │                     └──────────────────┘
                   │
                   ▼
          ┌──────────────────┐
          │   Sync Manager   │
          │   Sync Queue     │
          └────────┬─────────┘
                   │
                   └──────────────► API Server
```

---

# 70. Definition of Done

Feature dianggap selesai apabila:

- UI sudah dibuat
- Navigation sudah terhubung
- GetX Controller sudah digunakan
- Repository sudah tersedia
- Local storage sudah tersedia jika feature membutuhkan offline
- API integration sudah tersedia atau menggunakan mock repository jika backend belum tersedia
- Loading state tersedia
- Empty state tersedia
- Error state tersedia
- Offline state tersedia
- Sync mechanism tersedia untuk transaksi offline
- Permission sudah ditangani
- Validation sudah tersedia
- Error handling sudah tersedia
- Tidak ada compilation error
- `flutter analyze` tidak menghasilkan error
- Test yang relevan berhasil
- Tidak merusak feature existing
- Flow dapat digunakan secara end-to-end

---

# 71. Instruksi Awal untuk AI Agent

Sebelum melakukan implementasi:

1. Analisis seluruh struktur project Flutter existing.
2. Identifikasi architecture yang sudah digunakan.
3. Identifikasi package/dependency yang sudah tersedia.
4. Identifikasi apakah GetX sudah digunakan.
5. Identifikasi local storage yang sudah digunakan.
6. Identifikasi API client yang sudah digunakan.
7. Identifikasi theme dan design system existing.
8. Identifikasi routing existing.
9. Identifikasi authentication existing.
10. Jangan langsung membuat ulang struktur project jika struktur existing sudah tersedia.
11. Buat implementation plan berdasarkan struktur existing.
12. Implementasikan secara bertahap berdasarkan Phase.
13. Setelah setiap phase selesai, lakukan validation.
14. Jangan mengubah konfigurasi build tanpa alasan.
15. Jika ada requirement yang belum jelas dari sisi backend/API, gunakan abstraction/mock repository terlebih dahulu dan dokumentasikan endpoint yang dibutuhkan.
16. Pastikan seluruh aplikasi nantinya dapat berjalan dalam kondisi online maupun offline.
17. Prioritaskan stabilitas, maintainability, performance, dan kemudahan pengembangan jangka panjang.

**Target akhir:** aplikasi Mobile SFA FMCG berbasis Flutter + GetX yang profesional, scalable, responsive, aman, dan memiliki kemampuan **offline-first dengan automatic synchronization ketika koneksi internet kembali tersedia**.