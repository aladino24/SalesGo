# QA end-to-end: Offline, Sync, GPS, dan Approval

Jalankan skenario ini pada perangkat fisik Android/iOS karena GPS, kamera, dan perubahan konektivitas tidak dapat tervalidasi penuh melalui widget test.

## Pra-kondisi

1. Login sebagai Sales dan unduh master data terbaru.
2. Pastikan ada outlet berkoordinat dan akun Supervisor/Branch Manager untuk approval.
3. Catat jumlah item pending pada halaman Sinkronisasi.

## Skenario

| Langkah | Aksi | Hasil yang diharapkan |
|---|---|---|
| Offline check-in | Matikan internet, buka outlet, ambil GPS dan foto, lalu check-in dalam radius. | Visit berstatus `In Progress` tersimpan lokal dan satu item `visit_check_in` muncul di sync queue. |
| GPS override | Dengan lokasi di luar radius, masukkan alasan override lalu kirim. | Check-in dan request approval tersimpan lokal; tidak ada visit kedua saat tombol ditekan ulang. |
| Reconnect & sync | Aktifkan internet lalu pilih Sinkronisasi. | Attachment diunggah lebih dahulu, item sukses hilang dari queue, audit sync bertambah, dan server menerima UUID/idempotency key yang sama. |
| Approval | Login sebagai Supervisor/Branch Manager, buka Approval, lalu approve/reject request override. | Status approval dan visit diperbarui pada server serta perangkat Sales setelah sync/refresh. Reject menampilkan alasan. |
| Pemulihan | Hapus data lokal melalui setting, lalu Pulihkan State dari Server. | Visit aktif, approval, dan riwayat server-confirmed kembali tanpa memasukkan item offline yang belum pernah tersinkron. |

## Bukti yang dicatat

- Screenshot status GPS/radius dan foto check-in.
- UUID queue, idempotency key, waktu sync, serta audit trail server.
- Status sebelum/sesudah approval pada kedua role.
- Hasil restore state pada perangkat kedua atau sesudah cache dihapus.
