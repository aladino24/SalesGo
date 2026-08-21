# Backend Implementation Guide — SalesGo

Gunakan [API Contract v1](api-contract.md) sebagai spesifikasi publik. Dokumen ini adalah panduan implementasi, bukan kontrak alternatif.

## Urutan implementasi backend

1. Authentication: login, refresh, logout, JWT, role dan branch scope.
2. Master data: products dan outlets dengan pagination/filter bila datanya besar.
3. Visit: daftar visit, check-in, checkout, tunda, batal, dan approval.
4. Transaksi outlet: sales order, purchase, return, gift, note, receivable payment.
5. Journey dan surat jalan: lifecycle, approval, dan penggunaan barang.
6. Informasi: promosi, metadata file penting, dan signed download URL.
7. Notifikasi dan meeting online: feed user, unread state, deep link aman, dan audit join meeting.
8. Monitoring supervisor/branch manager dan laporan cabang.
9. Sync/idempotency, state recovery, audit trail, serta observability.

## Tabel data minimum

- `users`, `roles`, `branches`, `refresh_tokens`
- `products`, `outlets`, `sales_assignments`
- `visits`, `visit_checkins`, `visit_checkouts`, `visit_actions`
- `visit_activities` (timeline, lokasi, dan audit aktivitas)
- `sales_orders`, `purchases`, `returns`, `gifts`, `outlet_notes`, `receivable_payments`
- `sales_order_items`, `receivable_invoices`, `receivable_payment_allocations`, `return_attachments`
- `journeys`, `delivery_notes`, `delivery_note_items`
- `notifications`, `notification_reads`, `meetings`, `meeting_attendees`, `meeting_join_audits`
- `approvals`, `approval_actions`
- `idempotency_records`, `audit_logs`

Setiap tabel transaksi perlu memiliki: `id`, `local_transaction_id`/`client_uuid`, `created_at`, `updated_at`, `created_by`, `branch_id`, dan status.

## Kode cabang, user, outlet, dan seed development

- Buat master `branches(code CHAR(3) UNIQUE)`, `roles(code CHAR(3) UNIQUE)`, dan `sales_divisions(code CHAR(2) UNIQUE)`. Simpan `branch_id` dan `branch_code` pada semua master yang scoped cabang; master pusat memakai assignment/projection per cabang untuk harga, stok, dan visibilitas.
- User/sales mempunyai `employee_code CHAR(10) UNIQUE` dengan format `BBBRRRDDNN`: branch 3 digit, role 3 digit, divisi sales 2 digit, dan increment 2 digit. Gunakan transaction/row lock saat mengalokasikan increment, unique constraint `(branch_id, role_code, division_code, increment_no)`, dan jangan mendaur ulang increment user nonaktif.
- Outlet mempunyai `code` unik minimal per cabang dan wajib berformat `BBB-OTL-NNNN`; prefix `BBB` harus sama dengan `branch_code`. Produk perlu `branch_id`, `branch_code`, dan SKU yang scoped branch seperti `BBB-PRD-NNNN` bila SKU tidak dikelola pusat.
- Jadikan `branch_id` sebagai sumber scope otorisasi. `branch_code` dan kode bisnis hanya atribut yang tervalidasi; client tidak dapat memilih cabang melalui body request.
- Sediakan command idempotent, misalnya `seed:development`, untuk membuat data dummy cabang, role, divisi, user, outlet, produk, harga/stok, assignment, visit, dan approval. Command hanya diizinkan pada local/development/staging dan harus gagal pada production. Jangan mengirim seed sebagai fallback aplikasi Flutter.

## Idempotency dan sync

Simpan pasangan `(user_id, idempotency_key, endpoint)` dengan response sukses selama periode retensi yang disepakati. Jika request yang sama datang ulang, kembalikan response pertama tanpa menulis data baru. Jika body berbeda dengan key yang sama, respons `409`.

Jangan menganggap urutan sync selalu sama. Backend harus menerima operasi yang terlambat, memverifikasi versi/status data, lalu mengembalikan `409` bila perlu conflict resolution manual.

## Download data master terbaru

Implementasikan `GET /master/snapshot` sesuai [API Contract v1](api-contract.md#master-data). Bangun produk dan outlet dari revision database yang konsisten, lalu kirim `revision` dan `generatedAt`. Jangan men-stream satu dataset sukses lalu menanggapi dataset berikutnya gagal sebagai snapshot `200`; client perlu dapat mempertahankan cache lama bila snapshot tidak lengkap atau tidak valid.

- Scope produk/outlet mengikuti user, role, branch, dan sales assignment pada access token.
- Selalu kirim `products` dan `outlets` sebagai array, bahkan jika kosong.
- Endpoint read-only ini tidak boleh menyentuh queue transaksi, state visit aktif, atau audit write transaksi.
- Buat test snapshot untuk data kosong, schema invalid, scope branch, dan konsistensi revision ketika master berubah bersamaan.

## Detail outlet dan performance

- Tambahkan owner/contact/phone pada master outlet sesuai izin akses dan perbarui `GET /master/outlets` tanpa breaking client lama.
- `GET /master/outlets/{id}/performance` harus menghitung target dan achievement berdasarkan scope/periode bisnis yang jelas, serta menyediakan top product, produk belum terjual, dan produk potensial.
- Cache performance per outlet boleh digunakan oleh client offline, tetapi response harus hanya memuat data outlet pada assignment user/branch. Terapkan audit akses untuk data performance bila kebijakan perusahaan mewajibkan.

## Journey dan surat jalan

- Journey dalam kota hanya dapat berada pada satu tanggal; perjalanan luar kota wajib menyimpan tujuan, tanggal mulai/selesai, dan dapat memerlukan approval sebelum menjadi `Active`.
- Terapkan transisi status yang ketat untuk journey dan surat jalan; jangan mengizinkan `Completed` langsung dari `Draft`.
- Saat surat jalan `Submitted`, buat approval Branch Manager dengan entity ID surat jalan. Hanya surat jalan `Approved` yang dapat dipakai/ditandai `Completed`.
- Simpan detail item, user, branch, journey terkait bila ada, waktu mulai/selesai, dan audit approval/penggunaan.
- Sertakan `journeys` dan `deliveryNotes` pada `GET /sync/state` agar perangkat baru dapat memulihkan perjalanan aktif serta surat jalan yang masih menunggu approval/pemakaian.

## Transaksi outlet, timeline, dan piutang

- Sales order harus menyimpan header dan `sales_order_items` atomically. Harga, stok, promo, diskon, dan total wajib divalidasi server menggunakan revision master/policy saat transaksi diterima; jangan percaya nominal client sebagai sumber kebenaran.
- Retur memerlukan alasan, kondisi barang, attachment yang sudah finalized, dan workflow approval. Simpan relasi `return_attachments`, keputusan approval, serta perubahan status sebagai audit trail.
- Kelola invoice/piutang sebagai entitas server terpisah. Setiap pembayaran harus dialokasikan ke invoice, tidak melebihi outstanding, dan riwayat pembayaran mengembalikan saldo tersisa serta overdue yang dihitung waktu server.
- Simpan `visit_activities` append-only untuk check-in, checkout, tunda, batal, approval request, dan aktivitas lain. Lokasi opsional wajib dibatasi scope/retensi; response timeline tidak boleh membocorkan koordinat ke role tanpa izin.

## Notifikasi dan meeting online

- Bangun notifikasi dari event domain (sync result, approval, perubahan visit/journey, meeting). Simpan unread/read per user dan gunakan cursor pagination; jangan mengandalkan daftar notifikasi statis di client.
- `deepLink` dan `joinUrl` harus divalidasi allowlist HTTPS/provider. Endpoint join meeting perlu audit user, meeting, waktu, dan outcome; jangan menyimpan token meeting pada audit.
- Meeting harus mengikuti scope branch/assignment dan tidak membocorkan tautan rapat kepada user yang bukan peserta.
- Endpoint `POST /meetings` harus memvalidasi hak penjadwal, waktu selesai setelah waktu mulai, peserta dalam scope branch, serta menyimpan audit create/update/cancel. URL provider hanya dikirim kepada peserta yang berhak.
- `POST /meetings/join-by-code` harus rate-limit percobaan kode, tidak membedakan respons untuk kode yang tidak ada vs. user yang tidak berhak, serta menyimpan outcome audit tanpa menyimpan token provider.

## Attachment, retry, conflict, dan audit sync

- Implementasikan `POST /attachments` sebagai multipart upload ke object storage privat. Scan/validasi MIME dan ukuran file, simpan owner user/branch, dan kembalikan `id` attachment stabil. Jangan menerima path lokal dari perangkat sebagai referensi server.
- Transaksi check-in dan entitas lain yang memakai lampiran hanya menerima `photoId`/attachment ID yang sudah selesai dan dimiliki user pada scope yang sama. Buat proses ini idempotent melalui `Idempotency-Key`.
- Client melakukan retry maksimal lima kali dengan exponential backoff. Backend harus tetap aman bila upload/transaction terkirim ulang, sebagian berhasil, atau urutannya terlambat.
- Untuk conflict bisnis, kirim `409` dengan `code`, `message`, `serverVersion`, dan `serverState` minimum yang diperlukan untuk resolusi. Jangan mengubah state secara diam-diam saat version conflict.
- Simpan audit append-only untuk upload attachment, request sync, idempotency replay, retry, conflict, dan resolusi: correlation/client UUID, user, branch, endpoint, status, waktu UTC, dan alasan. Hindari menyimpan binary foto atau token pada audit log.

## State recovery perangkat

Implementasikan `GET /sync/state` persis seperti [API Contract v1](api-contract.md#pemulihan-state-perangkat). Snapshot dibuat dari database server yang sudah committed, untuk user dan branch dari access token. Jangan membuat tabel snapshot terpisah bila state bisa dihitung konsisten dari tabel utama; jika memakai materialized snapshot, perbarui secara atomik pada setiap commit transaksi.

- Sertakan seluruh dataset contract serta `dashboard`; `visits` harus memuat visit aktif `In Progress` dengan `outletId`. Sertakan `visitTimeline`, `journeys`, dan `deliveryNotes` bila client mengaktifkan restore modul tersebut.
- Selesaikan commit transaksi/check-in/check-out, lalu naikkan `revision` dan `generatedAt`. Snapshot tidak boleh menampilkan check-in tanpa status visit aktif atau sebaliknya.
- Endpoint read-only dan perlu audit log: user, branch, revision, waktu, metadata request aman, serta outcome.
- Terapkan authorization/scope yang sama seperti endpoint asal.
- Snapshot hanya berisi perubahan tersinkron; jangan menebak perubahan offline yang belum diterima server.

## Promosi dan file offline

- `GET /promotions` dan `GET /files` harus dapat dipanggil berulang untuk menyegarkan cache Hive di perangkat. Batasi hasil pada sales/branch/role yang berhak melihatnya.
- File binary disimpan pada object storage privat. `POST /files/{id}/download` memvalidasi scope, membuat signed URL HTTPS berumur pendek, lalu mencatat audit download.
- `version` harus berubah setiap kali konten file berubah. Jangan menimpa konten versi lama pada object storage karena perangkat dapat masih menyimpan URL sementara yang valid.
- Jangan mengirim binary file sebagai JSON atau menaruh URL storage permanen pada `GET /files`.
- Kirim `updatedAt` UTC dan ukuran byte yang akurat agar client dapat menampilkan metadata serta melakukan preflight quota cache. Penghapusan cache di perangkat tidak menghapus dokumen sumber pada server.

## Monitoring dan laporan manajemen

- Implementasikan empat endpoint monitoring/laporan dari [API Contract v1](api-contract.md#monitoring-dan-laporan-manajemen) sebagai read model yang terindeks, bukan query agregasi mahal langsung pada setiap request.
- Authorization wajib di backend: hanya Supervisor dan Branch Manager, dengan scope branch/assignment dari token. Jangan percaya `salesId`, `branchId`, atau role yang dikirim client sebagai filter otorisasi.
- Data check-in/checkout/transaksi yang baru committed harus memperbarui read model secara konsisten. Sertakan `generatedAt` dan gunakan waktu UTC.
- Audit setiap akses laporan dengan user, branch, tipe laporan, periode, waktu, dan outcome. Hindari memasukkan koordinat presisi atau PII berlebihan pada response aktivitas.

## Keamanan

- Hash password menggunakan Argon2id atau bcrypt.
- Access token singkat; refresh token harus dapat di-revoke dan disimpan hash.
- Terapkan scope branch/role pada setiap query, bukan hanya UI.
- Jangan log password, token, koordinat presisi, atau path foto mentah pada production log.
- File foto harus di-upload ke object storage; API mengembalikan `fileId`/URL terotorisasi. `photoPath` lokal tidak boleh dijadikan referensi final server.

## Validasi bisnis visit

- Outlet harus berada pada assignment user/branch.
- Check-in dan checkout mencatat lokasi, akurasi, waktu server, dan waktu device.
- Radius default 100 meter harus menjadi konfigurasi backend per outlet/branch.
- Aksi tunda/batal dan reject approval wajib menyimpan alasan.
- Approval harus menghasilkan audit trail: requester, approver, waktu, status, dan komentar.
- Endpoint route estimate harus memakai provider routing yang disetujui, mencatat provider/revision bila diperlukan, dan mengembalikan jarak jalan/durasi—not straight-line distance. Terapkan rate limit/cache untuk menghindari biaya routing berlebih.
- Override check-in di luar radius harus selalu membuat approval dan mempertahankan visit `Pending` sampai keputusan approver. Simpan jarak, GPS, alasan, policy/radius yang berlaku, dan audit trail.

## Keputusan background location

Jangan mengaktifkan background location hanya karena monitoring tersedia. Tahap ini membutuhkan keputusan tertulis perusahaan mengenai tujuan, basis consent, jam tracking, retensi, akses Supervisor/Branch Manager, serta prosedur berhenti/penghapusan data. Setelah disetujui, implementasikan worker terpisah, batch upload hemat baterai, indikator status yang terlihat, dan endpoint backend terautorisasi; jangan memakai tracking kontinu tanpa konteks perjalanan/visit aktif.

## Definition of done backend

- Semua endpoint contract memiliki test request/response dan test authorization.
- Test idempotency dan retry dipenuhi untuk seluruh transaksi tulis.
- Test attachment/sync: perangkat offline dapat mengunggah foto lalu check-in saat online, upload yang diputar ulang tidak menduplikasi file, retry berhenti setelah batas, dan `409` tersimpan sebagai conflict beserta audit trail.
- Test `GET /sync/state`: data lokal yang dihapus dapat direstore, visit aktif kembali `In Progress`, scope branch terisolasi, dan dataset kosong mengosongkan cache client.
- Test promosi/file: metadata dapat di-cache, file hanya dapat diunduh oleh scope yang berhak, signed URL kadaluarsa ditolak, dan kenaikan `version` memaksa client mengunduh ulang.
- Test monitoring/laporan: role sales menerima `403`, scope antar-branch terisolasi, angka agregat sesuai transaksi committed, dan response kosong tetap berbentuk array yang valid.
- Konflik menghasilkan `409`, validasi menghasilkan `422`/`400`, dan error tidak membocorkan detail internal.
- OpenAPI/Swagger dihasilkan dari contract yang sama; CI memverifikasi contoh payload contract.
