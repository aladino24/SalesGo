# Firebase Cloud Messaging (FCM)

Integrasi Flutter untuk menerima push notification sudah tersedia melalui
`firebase_core` dan `firebase_messaging`. Aplikasi mendaftarkan token perangkat
yang telah login ke `POST /v1/notifications/devices`, menangani token yang
berubah, menghapus registrasi saat logout, serta membuka deep link yang dikirim
server.

## Yang sudah ada di repository

- `firebase_core` dan `firebase_messaging` pada `pubspec.yaml`.
- Inisialisasi Firebase dan background message handler pada `lib/main.dart`.
- Permission Android 13+ `POST_NOTIFICATIONS` pada Android manifest.
- Registrasi/unregistrasi perangkat pada
  `lib/core/notifications/push_notification_service.dart`.
- Handler deep link terbatas untuk route internal yang aman pada
  `lib/core/notifications/notification_deep_link_handler.dart`.

## Konfigurasi Firebase Android

Integrasi saat ini ditujukan untuk Android; iOS tidak perlu dikonfigurasi.

1. File `android/app/google-services.json` sudah tersedia dan cocok dengan
   application ID saat ini, `com.example.salesgo`.
2. Google Services Gradle plugin sudah ditambahkan pada `android/settings.gradle.kts`
   dan `android/app/build.gradle.kts`, sehingga file JSON diproses saat build.
3. Jika application ID diganti untuk rilis, daftarkan ID baru pada Firebase lalu
   unduh ulang `google-services.json` yang cocok. Package name bersifat peka
   huruf besar-kecil dan harus sama persis.
4. Aktifkan Windows Developer Mode bila build Flutter mengeluarkan pesan bahwa
   plugin memerlukan symbolic-link support.

Tidak ada kebutuhan untuk `GoogleService-Info.plist` maupun konfigurasi APNs
selama aplikasi tidak menargetkan iOS.

## Status konfigurasi dan langkah berikutnya

- [x] `google-services.json` tersedia di `android/app/`.
- [x] Package name pada JSON cocok dengan `applicationId`: `com.example.salesgo`.
- [x] Google Services Gradle plugin telah dipasang.
- [x] Dependensi Flutter, permission Android, registrasi device, cache feed,
  unread badge, dan deep link internal telah diimplementasikan.
- [x] **Developer Mode** Windows telah aktif. Flutter plugin dapat memakai
  symbolic-link support; restart terminal/IDE bila proses Flutter lama masih
  menahan cache atau daemon.
- [ ] Jalankan `flutter pub get`, lalu uji pada perangkat Android fisik dengan
  `flutter run`. Izinkan permission notifikasi ketika aplikasi memintanya.
- [x] Service-account Firebase telah dirujuk dari environment Laravel lokal;
  OAuth token FCM berhasil divalidasi. File key tidak berada di repository.
- [ ] Saat deployment, pasang service-account yang sama/khusus production pada
  server Laravel dan isi `FCM_ENABLED`, `FIREBASE_PROJECT_ID`, serta
  `GOOGLE_APPLICATION_CREDENTIALS` melalui secret/environment server.
- [ ] Jalankan worker Laravel dan lakukan uji notifikasi dari event approval,
  transaksi, visit, atau meeting.

## Konfigurasi pengirim di backend

Laravel mengirim langsung ke Firebase Cloud Messaging HTTP v1. Buat private
key service account melalui Firebase Console > Project settings > Service
accounts, lalu simpan file JSON di path aman pada server Laravel. Isi
environment berikut, lalu jalankan queue worker:

```powershell
FCM_ENABLED=true
FIREBASE_PROJECT_ID=salesgo-dca78
GOOGLE_APPLICATION_CREDENTIALS=C:/secure/firebase-service-account.json
php artisan queue:work
```

Untuk server Linux gunakan path absolut Linux pada `GOOGLE_APPLICATION_CREDENTIALS`.
Laravel membentuk access token OAuth pendek dari key tersebut dan payload
mempertahankan `data.deepLink`, misalnya
`/approval?id=...`, agar aplikasi membuka halaman yang sesuai saat notifikasi
ditekan.


## Uji penerimaan notifikasi

1. Login pada perangkat fisik dan izinkan notifikasi.
2. Pastikan endpoint device backend menerima token FCM dan platform.
3. Buat event backend, misalnya approval atau perubahan status transaksi.
4. Ketuk notifikasi saat aplikasi di background/terminated dan pastikan deep
   link membuka route yang diizinkan.
5. Uji refresh token dan logout untuk memastikan device registration diperbarui
   atau dihapus.

Jangan menyimpan service-account key atau token gateway pada source code maupun
commit repository.
