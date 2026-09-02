# Checklist Fitur Pembayaran dan Penagihan SFA FMCG

Dokumen ini memetakan implementasi terhadap `REQUIREMENT_FITUR_PEMBAYARAN_SFA_FMCG.md`.
Legenda: `[x]` tersedia, `[~]` fondasi tersedia namun memerlukan integrasi/kebijakan lanjutan, `[ ]` belum tersedia.

## Tahap 1 — Fitur inti

- [x] Menu **Piutang & Pembayaran** hanya dapat dibuka dari detail outlet setelah check-in aktif.
- [x] Ringkasan outlet: total piutang, overdue, batas kredit, sisa limit, jumlah faktur terbuka, dan waktu pembaruan.
- [x] Daftar faktur dengan nomor, tanggal, jatuh tempo, nilai awal, dibayar, sisa, hari overdue, dan status Bahasa Indonesia.
- [x] Pilih beberapa faktur dan alokasi otomatis menurut jatuh tempo tertua.
- [x] Validasi server untuk outlet/faktur cabang, nilai positif, total komponen, sisa faktur, dan idempotency.
- [x] Pembayaran tunai dan transfer bank; transfer mewajibkan bukti foto.
- [~] Pembayaran gabungan didukung pada kontrak backend melalui beberapa komponen pembayaran; UI mobile saat ini menyajikan satu metode per transaksi (tunai atau transfer).
- [x] Kelebihan pembayaran disimpan sebagai nilai belum dialokasikan, tidak dihilangkan.
- [x] Pembayaran tersimpan offline di Hive dan masuk antrean sinkronisasi dengan UUID/idempotency key.
- [x] Snapshot faktur/piutang diunduh bersama master data terbaru sehingga formulir pembayaran dapat dibuka saat offline menggunakan cache terakhir.
- [x] Bukti transfer lokal diunggah/finalisasi sebelum request pembayaran dikirim saat sinkronisasi.
- [x] Status server `WAITING_SETTLEMENT`, `WAITING_VERIFICATION`, `VERIFIED`, dan `REJECTED`; UI offline memakai `PENDING_SYNC`.
- [x] Verifikasi/penolakan oleh Finance/BM/IT; faktur hanya bertambah nilai dibayarnya setelah terverifikasi.
- [x] Audit pembayaran dibuat saat submit dan verifikasi/penolakan; notifikasi dikirim ke petugas penerima.
- [x] Riwayat faktur lama tetap dipertahankan melalui `receivable_payments`.

## Tahap 2 — Kontrol keuangan

- [~] Janji bayar, penagihan gagal, dan sengketa telah memiliki endpoint/penyimpanan `collection_activities`; UI tugas, daftar alasan lengkap, dan notifikasi jatuh tempo belum dibuat.
- [ ] Penyetoran tunai/instrumen, penerimaan kasir, selisih, dan approval setoran.
- [ ] Deposit dan nota kredit sebagai saldo yang dapat diverifikasi/dipakai.
- [ ] Deteksi dugaan pembayaran ganda berbasis fingerprint referensi/bukti.
- [ ] Pembalikan pembayaran terverifikasi dan pengembalian saldo faktur.
- [ ] Dashboard KPI penagihan/piutang per Sales, SPV, BM, Finance.
- [ ] Permission dan data-scope generik (`PRIBADI`, `TIM`, `CABANG`, dan seterusnya); implementasi saat ini masih mengikuti role/cabang aplikasi yang ada.

## Tahap 3 — Otomatisasi dan integrasi

- [ ] Virtual Account dan QRIS dinamis beserta callback idempoten.
- [ ] Giro/cek dan lifecycle pencairan.
- [ ] Integrasi ERP/Finance sebagai sumber resmi faktur, saldo, limit kredit, dan posting.
- [ ] Rekonsiliasi bank/payment gateway, antrean retry, dead-letter, dan monitoring integrasi.
- [ ] Perubahan otomatis status blokir kredit serta credit-control workflow.
- [ ] PDF tanda terima pembayaran, QR verifikasi, WhatsApp/email, Bluetooth print.

## Data dan API yang ditambahkan

- [x] `payment_transactions`: header dan lifecycle pembayaran immutable.
- [x] `payment_components`: tunai/transfer dan fondasi metode gabungan.
- [x] `payment_allocations`: satu pembayaran ke banyak faktur.
- [x] `collection_activities`: janji bayar, gagal tagih, dan sengketa.
- [x] `outlets.credit_limit` serta `outlets.credit_status`.
- [x] `GET /outlets/{outlet}/payment-summary`.
- [x] `GET /payments`, `POST /payments`, `POST /payments/{payment}/verify`.
- [x] `POST /collection-activities`.

## Verifikasi yang masih perlu dilakukan

- [ ] Uji tunai satu faktur, sebagian, dan beberapa faktur.
- [ ] Uji transfer dengan bukti foto online/offline dan retry attachment.
- [ ] Uji konflik: faktur berubah/lunas sebelum transaksi offline tersinkron.
- [ ] Uji idempotency: request dan callback dikirim dua kali.
- [ ] Uji otorisasi Finance/BM/IT serta batas cakupan cabang.
