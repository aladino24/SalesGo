# Checklist Promosi SFA FMCG

Pemetaan terhadap `REQUIREMENT_FITUR_PROMOSI_SFA_FMCG.md`.
Legenda: `[x]` tersedia, `[~]` fondasi tersedia, `[ ]` belum tersedia.

## Tahap 1 — inti promosi

- [x] Cache promosi online/offline melalui Hive dan unduhan data terbaru.
- [x] Daftar program dasar pada Informasi dan metadata program diperluas: kode, periode, minimum order, jenis, nilai, limit diskon, status, aturan kelayakan/manfaat/stacking, kuota, dan anggaran.
- [x] Promosi dapat dipilih pada halaman Buat Order dan kode program ikut antrean offline/idempotensi.
- [x] Server menghitung ulang diskon persentase/nominal dan menolak program yang tidak aktif atau di luar periode.
- [x] Detail order menyimpan kode promosi agar riwayat dapat ditelusuri.
- [~] Kelompok produk/SKU, diskon bertingkat, bonus produk, bundle, konflik stacking, kuota dan anggaran telah memiliki kolom aturan, tetapi mesin keputusan lengkap serta UI simulasi/rincian belum tersedia.

## Tahap 2 — kontrol

- [ ] Reservasi/pemakaian kuota dan anggaran atomik, pelepasan saat pembatalan, serta conflict offline.
- [ ] Pengajuan promosi khusus, approval berjenjang, bukti display/merchandising, dan notifikasi khusus.
- [ ] Monitoring penggunaan promosi, outlet/sales, dan dashboard SPV/BM.

## Tahap 3 — klaim dan analitik

- [ ] Cashback, voucher, poin, hadiah, klaim, status pembayaran klaim, dan rekonsiliasi Finance.
- [ ] Analitik efektivitas/baseline/cannibalization serta integrasi ERP/DMS/gateway.

## Verifikasi yang perlu dilakukan

- [ ] Uji diskon nominal/persentase, minimum pembelian, dan periode berakhir.
- [ ] Uji order offline lalu sinkron ulang ketika promo berubah.
- [ ] Uji kuota terakhir, stacking konflik, bonus stok habis, pembatalan/retur.

## Status implementasi Tahap 2 (2 September 2026)

- [x] Reservasi penggunaan promosi dibuat saat sales order tersimpan.
  Reference order unik sehingga retry tidak menggandakan kuota atau anggaran.
- [x] Reservasi menjadi `Consumed` saat order committed/completed, serta
  dilepas saat order dibatalkan sebelum committed.
- [x] Server memeriksa kuota pusat/per-outlet, anggaran, minimal order,
  cakupan outlet dan peran sebelum reservasi dibuat.
- [~] Aturan stacking tersimpan di `stacking_rules`. Rilis ini hanya menerima
  satu promosi/order sehingga tidak ada diskon ganda; engine multi-program
  dan pemilihan kombinasi terbaik masih belum tersedia.
- [x] Pengajuan promosi khusus mencakup outlet, program acuan, jenis/nilai,
  jumlah, potensi omzet, alasan, periode, dan lampiran tervalidasi.
- [x] Pengajuan khusus masuk approval Branch Manager, memberi notifikasi ke
  pengaju setelah diputuskan, serta masuk audit trail.
- [x] Endpoint bukti merchandising menyimpan outlet, pengguna, waktu, GPS,
  catatan, dan ID foto `Finalized`.
- [x] Dashboard ringkas SPV/BM/Marketing/IT tersedia: program aktif, manfaat
  dicadangkan/dikonsumsi, outlet berpartisipasi, pengajuan dan bukti pending.
- [x] Mobile menyediakan menu **Kontrol Promosi** dan form pengajuan khusus.
- [ ] UI mobile bukti merchandising dan verifikasi SPV/Trade Marketing.
- [ ] Approval bertingkat berdasarkan nominal (SPV → BM → Trade
  Marketing/Finance), notifikasi kuota hampir habis/berakhir, serta dashboard
  per sales/outlet yang lebih rinci.
