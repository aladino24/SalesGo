# Status integrasi Flutter ke SalesGo API

Dokumen ini mencatat batas tegas antara data yang sudah dibaca dari API dan
fitur yang masih menunggu perluasan kontrak backend. Aplikasi tidak boleh
menampilkan angka contoh sebagai pengganti data server.

## Sudah cache-first dan memakai API

- Dashboard: `GET /dashboard`, termasuk omset, target, insentif, visit, dan
  grafik harian transaksi committed.
- Master produk/outlet, promosi, file penting, meeting, notifikasi, approval,
  dan kunjungan.
- Journey: `GET/POST /journeys` dan `PATCH /journeys/{id}/status`.
- Surat jalan: `GET/POST /delivery-notes` dan aksi `submit`, `use`, `cancel`.
- Riwayat transaksi outlet: `GET /outlets/{outletId}/transactions` dengan
  data lokal yang belum tersinkron sebagai fallback.
- Timeline visit: `GET /outlets/{outletId}/visit-activities`; server menjadi
  sumber aktivitas append-only setelah check-in/out/tunda/batal berhasil.
- Monitoring: `GET /monitoring/team` untuk lokasi terakhir dan visit aktif.
- Laporan: `GET /reports/summary` dengan angka committed dan agregasi tipe.

## Kontrak yang masih perlu ditambah di backend

- Kinerja per anggota tim (omset, target, jumlah visit) untuk tab Monitoring
  Kinerja. Flutter menampilkan empty state sampai endpoint ini tersedia.
- Profil `GET /auth/me` yang mengembalikan kode pegawai, cabang, divisi,
  avatar, serta grant cabang. Saat ini Flutter hanya menyimpan nama dan role
  dari respons login.
- Endpoint daftar invoice piutang untuk memilih invoice sebelum mengirim
  pembayaran ke `POST /receivables/{invoiceId}/payments`.
- Endpoint produk untuk form purchase/return/gift yang menyertakan pilihan
  produk, harga, dan stok; form lama masih perlu dimigrasikan dari input nama
  produk ke item `productId` sebelum dikirim.
- Filter/pagination UI untuk transaksi outlet, laporan, monitoring history,
  dan riwayat timeline.

## Aturan sinkronisasi

1. Saat online, respons server mengganti cache untuk dataset yang lengkap.
2. Saat request gagal/offline, cache tetap dibaca dan mutasi dimasukkan ke
   antrean sync dengan idempotency key.
3. Jangan mengirim event timeline terpisah: backend membuat audit/timeline
   dari endpoint lifecycle visit sehingga event tidak terduplikasi.
4. Empty state lebih benar daripada data contoh ketika respons server kosong.
