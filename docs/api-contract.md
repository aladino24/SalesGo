# SalesGo API Contract v1

Dokumen ini adalah **single source of truth** antara aplikasi Flutter dan backend SalesGo. Backend baru wajib mengikuti path, HTTP method, field, dan status response di bawah ini. Perubahan yang breaking harus dibuat sebagai `/v2`, bukan mengubah kontrak v1.

Base URL: `https://<host>/v1`.

## Aturan umum

- Request dan response menggunakan JSON (`Content-Type` dan `Accept: application/json`).
- Endpoint selain login/refresh membutuhkan `Authorization: Bearer <accessToken>`.
- Semua waktu menggunakan ISO-8601 UTC, contoh `2026-08-20T12:00:00Z`.
- Semua operasi tulis (`POST`, `PUT`, `PATCH`) harus menerima `Idempotency-Key` UUID dan mengembalikan hasil yang sama untuk key yang sama.
- ID menggunakan string UUID atau ID server yang stabil.
- Sukses: `200`/`201`; input tidak valid: `400`/`422`; tidak login: `401`; tidak berhak: `403`; duplikat/conflict: `409`.

## Kode organisasi dan master data

Backend menyimpan `branchId` (UUID/internal ID) dan `branchCode` (tepat tiga digit) pada **setiap** user serta record master yang scoped per cabang: outlet, produk, kategori, harga, stok, promosi, file, target, dan assignment. `branchCode` adalah bagian dari response agar client dapat menampilkan dan memvalidasi scope cache offline, namun otorisasi tetap berasal dari token, bukan nilai dari client.

### Kode user/sales: `BBBRRRDDNN`

Kode user/sales selalu 10 digit tanpa pemisah:

| Bagian | Panjang | Contoh | Arti |
|---|---:|---|---|
| `BBB` | 3 | `001` | Kode cabang |
| `RRR` | 3 | `001` | Kode role dari master role |
| `DD` | 2 | `01` | Kode divisi sales dari master division |
| `NN` | 2 | `01` | Increment unik dalam kombinasi cabang-role-divisi |

Contoh `0010010101` berarti user Sales ke-01 pada divisi `01`, role `001`, cabang `001`. Role tidak boleh di-hardcode di client; mapping kode role dikelola backend (misalnya Sales `001`, Supervisor `002`, Branch Manager `003`, Key Account Manager `004`). Backend menolak kode yang tidak cocok dengan `branchId`, role, atau division user, dan menerapkan unique constraint untuk `(branch_id, role_code, division_code, increment_no)` serta `employee_code`. Bila increment telah melebihi `99`, backend mengembalikan `CODE_INCREMENT_EXHAUSTED`; perubahan format harus menjadi versi kontrak baru.

### Kode outlet dan master scoped branch

- Setiap `Outlet.code` **wajib diawali** `branchCode` tiga digit, contoh `001-OTL-0001`. Backend memvalidasi prefix tersebut sama dengan `outlet.branchCode`.
- Setiap produk dan master lain yang tersedia per cabang wajib memiliki `branchId` dan `branchCode`. Produk pusat yang dibagikan ke banyak cabang tetap diproyeksikan ke scope cabang melalui tabel assignment/harga/stok per cabang.
- `id` UUID tetap menjadi primary key dan referensi API. Kode bisnis tidak boleh menggantikan UUID pada payload transaksi offline.
- Client hanya boleh mengirim `branchCode` sebagai metadata tampilan; backend mengambil cabang efektif dari access token dan menolak mismatch dengan `BRANCH_SCOPE_MISMATCH`.

### Seed/dummy development

Backend wajib menyediakan seed data **hanya** untuk environment `local`/`development`/`staging` melalui command atau migration eksplisit. Seed minimal mencakup cabang, role, division, user/sales, outlet, produk, harga/stok, assignment, visit, dan approval contoh dengan kode yang mengikuti aturan di atas. Seed tidak boleh berjalan otomatis di production, tidak boleh menjadi fallback pada aplikasi Flutter, dan harus aman dijalankan ulang (idempotent/upsert).

Format error wajib:

```json
{ "message": "Pesan yang aman untuk pengguna", "code": "VALIDATION_ERROR", "errors": { "field": ["penjelasan"] } }
```

## Authentication

### `POST /auth/login`

```json
{ "username": "andi.pratama", "password": "secret" }
```

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "expiresAt": "2026-08-20T12:00:00Z",
  "user": { "id": "USR-001", "employeeCode": "0010010101", "branchId": "BR-001", "branchCode": "001", "divisionCode": "01", "name": "Andi Pratama", "role": "sales" }
}
```

Role yang valid: `sales`, `supervisor`, `branchManager`, `keyAccountManager`.

### `POST /auth/refresh`

```json
{ "refreshToken": "jwt-refresh-token" }
```

Response sama seperti login. Refresh token yang invalid harus merespons `401`.

### `POST /auth/logout`

Body opsional: `{ "refreshToken": "..." }`. Response `204` atau `{ "success": true }`.

## Master data

### `GET /master/products`

Mengembalikan array:

```json
[{ "id": "PRD-001", "branchId": "BR-001", "branchCode": "001", "name": "Susu Ultra", "sku": "001-PRD-0001", "category": "Minuman", "price": 18000, "stock": 120, "imageUrl": "https://..." }]
```

### `GET /master/outlets`

```json
[{ "id": "OUT-001", "branchId": "BR-001", "branchCode": "001", "name": "Toko Sumber Rejeki", "code": "001-OTL-0001", "address": "Jl. Melati No. 12", "type": "Grosir", "ownerName": "Bapak Joko", "contactName": "Bapak Joko", "phone": "+628123456789", "latitude": -7.2575, "longitude": 112.7521, "salesResponsible": "Andi Pratama", "status": "Active" }]
```

### `GET /master/outlets/{id}/performance`

Mengembalikan performance outlet dalam scope user yang login. Nominal berupa number tanpa format mata uang.

```json
{ "target": 10000000, "achievement": 6250000, "topProducts": [{ "id": "PRD-001", "name": "Susu Ultra" }], "unsoldProducts": [{ "id": "PRD-009", "name": "Produk Baru" }], "potentialProducts": [{ "id": "PRD-010", "name": "Kopi Kemasan" }] }
```

`ownerName`, `contactName`, dan `phone` pada outlet bersifat opsional untuk kompatibilitas data lama. Nomor telepon harus hanya diberikan kepada role yang berhak dan tidak boleh dicatat sebagai data sensitif pada log production.

### `GET /master/snapshot`

Endpoint khusus untuk **Download Data Terbaru**. Mengembalikan seluruh master data yang saat ini dipakai client dalam satu snapshot konsisten; client memvalidasi seluruh payload dahulu dan baru mengganti cache lokal.

```json
{
  "revision": "master-2026-08-20T02:00:00Z",
  "generatedAt": "2026-08-20T02:00:00Z",
  "datasets": {
    "products": [{ "id": "PRD-001", "branchId": "BR-001", "branchCode": "001", "name": "Susu Ultra", "sku": "001-PRD-0001", "category": "Minuman", "price": 18000, "stock": 120, "imageUrl": "https://..." }],
    "outlets": [{ "id": "OUT-001", "branchId": "BR-001", "branchCode": "001", "name": "Toko Sumber Rejeki", "code": "001-OTL-0001", "address": "Jl. Melati No. 12", "type": "Grosir", "latitude": -7.2575, "longitude": 112.7521, "salesResponsible": "Andi Pratama", "status": "Active" }]
  }
}
```

`products` dan `outlets` wajib selalu ada, termasuk saat kosong. Backend harus membangun snapshot dari revision/database state yang sama, menerapkan scope user/branch, dan tidak mengirim payload parsial dengan status `200`. Endpoint ini hanya memperbarui master cache; tidak memodifikasi atau menghapus antrean transaksi offline.

## Dashboard

### `GET /dashboard`

```json
{ "monthlyRevenue": 48750000, "monthlyTarget": 70000000, "visitedOutlets": 32, "totalOutlets": 45, "incentive": 5250000, "revenueGrowth": 12.5 }
```

Nilai nominal berupa number tanpa format mata uang. Backend menerapkan scope role dan branch user yang sedang login.

## Monitoring dan laporan manajemen

Endpoint di bagian ini hanya untuk role `supervisor` dan `branchManager`. Semua hasil harus dibatasi oleh branch/assignment dari access token; parameter user/branch dari client tidak boleh dipakai untuk memperluas scope.

### `GET /monitoring/sales-activities`

```json
{ "generatedAt": "2026-08-20T02:00:00Z", "activities": [{ "id": "ACT-001", "salesId": "USR-010", "salesName": "Budi", "activity": "check_in", "description": "Check-in Toko Maju Jaya", "occurredAt": "2026-08-20T01:15:00Z" }] }
```

### `GET /monitoring/visits`

```json
{ "generatedAt": "2026-08-20T02:00:00Z", "visits": [{ "id": "VIS-001", "salesId": "USR-010", "salesName": "Budi", "outletId": "OUT-001", "outletName": "Toko Maju Jaya", "status": "In Progress", "updatedAt": "2026-08-20T01:15:00Z" }] }
```

### `GET /monitoring/performance`

```json
{ "period": "current_month", "members": [{ "salesId": "USR-010", "salesName": "Budi", "revenue": 6250000, "target": 10000000, "visitCount": 12 }] }
```

### `GET /reports/summary?type=revenue|visits|transactions&period=current_month`

```json
{ "type": "revenue", "period": "current_month", "generatedAt": "2026-08-20T02:00:00Z", "rows": [{ "label": "Budi", "subtitle": "12 visit", "value": 6250000 }] }
```

`type` wajib salah satu dari `revenue`, `visits`, atau `transactions`. Nilai monetary tetap number tanpa format. Response boleh di-cache client untuk penggunaan offline, namun harus menyertakan `generatedAt` agar UI dapat menjelaskan kesegaran data.

## Visit dan lokasi

### `GET /visits`

```json
[{ "id": "VIS-001", "outletId": "OUT-001", "outletName": "Toko Sumber Rejeki", "status": "Planned", "distanceKm": 1.2, "latitude": -7.2575, "longitude": 112.7521, "salesName": "Andi Pratama", "createdAt": "2026-08-20T01:15:00Z" }]
```

Status: `Planned`, `On Route`, `In Progress`, `Completed`, `Pending`, `Cancelled`, `Failed`.

### `POST /visits/check-in`

```json
{
  "visitId": "VIS-001",
  "outletId": "OUT-001",
  "notes": "Display sudah dicek",
  "photoId": "ATT-001",
  "location": { "latitude": -7.2575, "longitude": 112.7521, "accuracy": 8.5, "capturedAt": "2026-08-20T01:15:00Z" },
  "distanceMeters": 18
}
```

Backend wajib memvalidasi outlet, role, GPS, dan radius bisnis. Response mengembalikan visit terbaru.

Jika check-in di luar radius diizinkan oleh policy, request wajib memuat:

```json
{ "outOfRadiusOverride": { "reason": "Titik GPS outlet tidak akurat", "requestedAt": "2026-08-20T01:15:00Z" } }
```

Backend membuat visit berstatus `Pending`, membuat approval visit, dan tidak mengubahnya menjadi `In Progress` sebelum approval disetujui.

### `GET /routes/estimate`

Query wajib: `originLat`, `originLng`, `destinationLat`, `destinationLng`. Backend dapat memakai provider routing yang disetujui perusahaan dan mengembalikan jarak jalan serta durasi:

```json
{ "distanceMeters": 2350, "durationSeconds": 420, "provider": "routing-provider", "generatedAt": "2026-08-20T01:10:00Z" }
```

Saat endpoint tidak tersedia/offline, client boleh menampilkan jarak garis lurus dengan label **perkiraan**; jangan menampilkan angka tersebut sebagai rute jalan aktual.

### `POST /attachments`

Request `multipart/form-data` dengan field `file`. Endpoint mengembalikan attachment yang sudah tersimpan di object storage privat:

```json
{ "id": "ATT-001", "contentType": "image/jpeg", "size": 245678, "createdAt": "2026-08-20T01:14:50Z" }
```

Client offline menyimpan path file lokal sementara. Saat sync, client wajib mengunggah lampiran lebih dulu, mengganti `photoPath` lokal dengan `photoId`, lalu mengirim transaksi check-in memakai `photoId`. Backend harus memvalidasi ownership attachment terhadap user/branch yang sama dan menolak attachment yang belum selesai diproses.

### `POST /visits/check-out`

Body: `visitId`, `outletId`, `notes`, dan `location`. Response mengubah status visit menjadi `Completed`.

### `POST /visits/defer`

Body: `outletId`, `reason`, `followUpAt`. `followUpAt` wajib ISO-8601.

### `POST /visits/cancel`

Body: `outletId`, `reason`.

### `POST /approvals/visits`

Body: `outletId`, `reason`. Backend membuat approval berstatus `Pending` dan menetapkan approver berdasarkan role/branch.

### `POST /visit-activities`

Mencatat timeline aktivitas visit yang dilakukan offline/online. Body: `id`, `visitId` opsional, `outletId`, `activity`, `description`, `location` opsional, dan `createdAt`. Jika `location` tersedia, formatnya sama seperti lokasi check-in. Backend menyimpan koordinat secara aman dan hanya menampilkannya kepada role yang berhak.

### `GET /outlets/{outletId}/visit-activities?from=&to=`

Mengembalikan timeline visit outlet secara urut waktu menurun. Setiap item memuat `id`, `visitId`, `activity`, `description`, `location` opsional, `createdAt`, dan status sinkron. Koordinat presisi hanya dikembalikan untuk user/role yang memiliki akses ke outlet tersebut.

## Journey

### `GET /journeys`

Mengembalikan perjalanan milik user pada scope branch aktif, termasuk status dan approval terakhir. Response berbentuk array dengan field yang sama seperti payload pembuatan.

### `POST /journeys`

```json
{ "id": "client-uuid", "type": "in_city", "destination": "Surabaya Barat", "startAt": "2026-08-20T01:00:00Z", "endAt": "2026-08-20T15:00:00Z", "status": "Planned", "salesName": "Andi Pratama", "approvalStatus": "Not Required", "createdAt": "2026-08-20T01:00:00Z" }
```

`type` bernilai `in_city` atau `out_of_town`. Perjalanan luar kota dapat memiliki `approvalStatus: Waiting Approval`. Status lifecycle: `Planned`, `Active`, `Completed`, `Cancelled`.

### `PATCH /journeys/{id}/status`

Body `{ "status": "Active" }` atau `{ "status": "Completed" }`. Backend memvalidasi owner journey, approval luar kota, dan transisi status.

## Surat Jalan

### `GET /delivery-notes`

Mengembalikan surat jalan milik user/branch yang berhak dilihat, beserta seluruh `items`, status penggunaan, dan status approval terakhir.

### `POST /delivery-notes`

```json
{ "id": "client-uuid", "number": "SJ-2026-001", "journeyId": "JRN-001", "date": "2026-08-20T01:00:00Z", "salesName": "Andi Pratama", "destination": "Toko Maju Jaya", "outletId": "OUT-001", "items": [{ "productId": "PRD-001", "productName": "Susu Ultra", "quantity": 10, "unit": "karton" }], "status": "Draft", "approvalStatus": "Not Submitted", "createdAt": "2026-08-20T01:00:00Z" }
```

Status: `Draft`, `Submitted`, `Waiting Approval`, `Approved`, `Rejected`, `Completed`.

### `PATCH /delivery-notes/{id}/status`

Mengajukan (`Submitted`) atau menandai pemakaian (`Completed`) surat jalan. Saat `Submitted`, backend membuat approval untuk Branch Manager pada `GET /approvals` dan menyimpan audit approval. Surat jalan hanya dapat digunakan setelah status `Approved`.

## Promotion dan file penting

### `GET /promotions`

Mengembalikan promosi sesuai scope sales/branch, termasuk promosi yang masih aktif dan yang akan datang.

```json
[{ "id": "PROMO-001", "title": "Promo Agustus Spesial", "description": "Bonus pembelian produk tertentu.", "startAt": "2026-08-01T00:00:00Z", "endAt": "2026-08-31T23:59:59Z", "status": "Aktif", "imageUrl": "https://..." }]
```

### `GET /promotions/{id}`

Mengembalikan detail satu promosi dengan field minimal yang sama seperti daftar, serta syarat, produk yang berlaku, dan lampiran bila tersedia.

### `GET /files`

Mengembalikan metadata file penting yang boleh tersedia offline:

```json
[{ "id": "FILE-001", "name": "Katalog Agustus.pdf", "type": "pdf", "size": 2345678, "version": "3", "updatedAt": "2026-08-20T01:00:00Z" }]
```

`size` adalah byte. Jika versi file berubah, client wajib menganggap cache lama usang dan meminta unduhan baru.

### `POST /files/{id}/download`

Membuat URL unduhan sementara untuk file yang user berhak akses.

```json
{ "downloadUrl": "https://storage.example/signed-url", "expiresAt": "2026-08-20T02:00:00Z" }
```

URL harus HTTPS, berlaku singkat, bersifat terotorisasi, dan tidak boleh dapat digunakan untuk file di luar scope user. Client menyimpan binary di direktori aplikasi; file tidak diunggah kembali melalui endpoint ini.

Client menampilkan `updatedAt`, ukuran, versi, dan status cache. Cache file dapat dihapus hanya di perangkat dan tidak memerlukan request delete ke server. Client membatasi total cache file offline menjadi 100 MB; jika quota tidak cukup, unduhan ditolak sampai user menghapus cache file lain.

### `GET /approvals?status=Pending`

Mengembalikan array approval dengan `id`, `type`, `entityId`, `requestedBy`, `reason`, `status`, dan `createdAt`.

### `POST /approvals/{id}/decision`

```json
{ "status": "Approved", "comment": "" }
```

Status hanya `Approved` atau `Rejected`; backend wajib memeriksa permission approver dan menyimpan audit trail.

## Transaksi outlet

Semua endpoint berikut menerima `outletId`, `notes`, `createdAt`, dan ID transaksi lokal bila tersedia. Payload transaksi menyertakan lokasi opsional untuk audit aktivitas lapangan.

| Method | Endpoint | Queue type | Keterangan |
|---|---|---|---|
| POST | `/sales-orders` | `sales_order_create` | Order penjualan |
| POST | `/purchases` | `purchase_create` | Pembelian outlet |
| POST | `/returns` | `return_create` | Retur produk |
| POST | `/gifts` | `gift_create` | Pemberian hadiah |
| POST | `/outlet-notes` | `outlet_note_create` | Catatan outlet |
| POST | `/receivable-payments` | `receivable_payment_create` | Pembayaran piutang |

Contoh sales order:

```json
{ "id": "SO-local-id", "outletName": "Toko Sumber Rejeki", "items": [{ "productId": "PRD-001", "productName": "Susu Ultra", "quantity": 10, "unitPrice": 12000, "discount": 5000, "subtotal": 115000 }], "discount": 5000, "total": 115000, "status": "Pending Sync", "createdAt": "2026-08-20T01:30:00Z" }
```

Backend wajib memvalidasi harga dan stok terhadap master/version server; client hanya memakai harga/stok cache sebagai informasi saat offline. Diskon harus divalidasi terhadap policy promo/role sebelum order menjadi final.

Payload retur wajib memuat `item`, `quantity`, `returnReason`, `itemCondition`, dan `photoId` setelah attachment tersinkron. Retur berstatus `Waiting Approval` sampai approver yang berwenang memutuskan.

Payload pembayaran piutang wajib memuat `invoiceNumber`, `amount`, dan `dueDate` bila tersedia. Response riwayat pembayaran harus dapat dilacak per invoice, menyertakan `paidAt`, sisa piutang, serta penanda `isOverdue` yang dihitung server.

### `GET /outlets/{outletId}/transactions?type=&from=&to=&page=&limit=`

Riwayat transaksi outlet ber-paginasi. `type` opsional: `sales_order`, `purchase`, `return`, `gift`, `note`, atau `receivable_payment`. Item memuat ID, type, status, amount, detail item, approval status bila ada, createdAt, dan attachment metadata yang diizinkan.

### `GET /outlets/{outletId}/receivables?status=open|overdue|paid`

Daftar invoice piutang outlet berisi `invoiceNumber`, `invoiceDate`, `dueDate`, `originalAmount`, `paidAmount`, `outstandingAmount`, `isOverdue`, dan `payments`. Backend menghitung overdue menggunakan waktu server UTC dan mengotorisasi scope outlet/branch.

## Notifikasi

### `GET /notifications?cursor=&limit=&unreadOnly=`

Mengembalikan notifikasi user: `id`, `type`, `title`, `message`, `entityType`, `entityId`, `isRead`, `createdAt`, serta `deepLink` opsional. Tipe minimal: `sync`, `approval`, `visit`, `journey`, dan `meeting`.

### `POST /notifications/{id}/read`

Menandai satu notifikasi sebagai sudah dibaca. Backend hanya boleh mengubah notifikasi milik user token.

## Meeting Online

### `GET /meetings?from=&to=&status=`

Mengembalikan meeting dalam scope user/branch: `id`, `title`, `startsAt`, `endsAt`, `status`, `provider`, `joinUrl`, dan peserta ringkas. `joinUrl` harus HTTPS atau deep link provider yang tervalidasi.

### `POST /meetings/{id}/join`

Mencatat intent bergabung untuk audit lalu mengembalikan `{ "joinUrl": "..." }`. Backend memeriksa bahwa user adalah peserta dan meeting dapat diakses.

### `POST /meetings`

Membuat jadwal meeting oleh role yang memiliki izin. Request minimal:

```json
{
  "id": "uuid-client",
  "title": "Briefing Pagi Sales",
  "description": "Target dan aktivitas hari ini",
  "startsAt": "2026-08-21T09:00:00+07:00",
  "endsAt": "2026-08-21T10:00:00+07:00",
  "participantIds": []
}
```

Backend menentukan `hostName`, scope branch, provider, dan `joinUrl`; mencatat audit penjadwalan; serta wajib menghormati `Idempotency-Key`. Response mengikuti field `GET /meetings`, dengan `agenda` opsional (`title`, `time`).

### `POST /meetings/join-by-code`

Menerima `{ "meetingId": "123 456 7890" }`, memverifikasi peserta serta status rapat, mencatat audit join, dan mengembalikan `{ "joinUrl": "https://..." }`. Kode atau URL tidak boleh dipakai untuk melewati scope branch/peserta.

## Offline sync

Client menyimpan transaksi di Hive dan mengirim ulang saat online. Backend wajib menyimpan `Idempotency-Key` beserta response untuk mencegah duplikasi. Jika konflik bisnis terjadi, respons harus `409` dengan `code` yang jelas. Jangan membuat transaksi kedua untuk key yang sama.

Client melakukan retry eksponensial untuk error jaringan/timeout/5xx (maksimal 5 percobaan otomatis; 1, 2, 4, 8, 16 menit, dibatasi 30 menit). Error `409` menjadi conflict dan tidak boleh dicoba ulang otomatis. Response `409` wajib memuat `code`, `message`, dan informasi versi/state server yang cukup untuk UI conflict resolution. Audit server wajib mencatat setiap upload lampiran, penerimaan ulang idempotency key, retry, conflict, serta keputusan resolusinya.

## Keputusan background location

Versi aplikasi saat ini memakai lokasi **foreground/on-demand** untuk peta, check-in, dan checkout. Background location tidak diaktifkan secara default karena memerlukan kebijakan perusahaan, tujuan pemrosesan, consent eksplisit, masa retensi, dan permission Android/iOS tambahan.

Jika perusahaan menyetujui monitoring background, backend wajib menyediakan endpoint batch lokasi dengan `salesId` dari token, latitude, longitude, accuracy, capturedAt, source, dan journey/visit ID opsional. Client hanya boleh mengirim ketika perjalanan aktif, menampilkan indikator tracking yang jelas, menyediakan tombol berhenti, dan tidak mengirim lokasi di luar jam/konteks kerja yang disetujui.

## Pemulihan state perangkat

### `GET /sync/state`

Mengembalikan snapshot **server-confirmed** milik user dan scope branch yang sedang login. Endpoint ini digunakan ketika data lokal perangkat hilang atau user memilih **Pulihkan State dari Server**. Endpoint ini tidak boleh memasukkan perubahan yang masih ada pada antrean offline client dan belum diterima server.

```json
{
  "revision": "state-2026-08-20T01:45:00Z",
  "generatedAt": "2026-08-20T01:45:00Z",
  "activeVisit": {
    "id": "VIS-001",
    "outletId": "OUT-001",
    "outletName": "Toko Sumber Rejeki",
    "status": "In Progress",
    "distanceKm": 0.02,
    "salesName": "Andi Pratama",
    "createdAt": "2026-08-20T01:15:00Z"
  },
  "dashboard": {
    "monthlyRevenue": 48750000,
    "monthlyTarget": 70000000,
    "visitedOutlets": 32,
    "totalOutlets": 45,
    "incentive": 5250000,
    "revenueGrowth": 12.5
  },
  "datasets": {
    "products": [], "outlets": [], "visits": [], "salesOrders": [],
    "outletTransactions": [], "visitActions": [], "visitTimeline": [], "journeys": [], "deliveryNotes": [], "meetings": [], "approvals": [],
    "promotions": [], "files": []
  }
}
```

- `activeVisit` bernilai `null` jika tidak ada visit `In Progress`; jika ada, objek itu **wajib juga muncul** di `datasets.visits`.
- Tiap record dataset wajib memiliki `id` stabil dan mengikuti field endpoint modulnya. Field baru harus opsional bagi client lama.
- Array kosong berarti data lokal dataset itu dikosongkan; dataset yang tidak dikirim tidak boleh diubah client.
- Backend menerapkan scope user/role/branch, mencatat audit akses pemulihan, dan tidak mengembalikan token, password, path foto lokal, atau data user lain.

## Aturan perubahan contract

1. Tambahan field response harus nullable/opsional bagi client lama.
2. Field yang disebut wajib di dokumen ini tidak boleh diubah nama atau tipe pada `/v1`.
3. Perubahan request wajib ditambahkan ke dokumen ini dan diuji dengan contoh payload di atas sebelum backend dirilis.
4. Endpoint baru harus ditambahkan ke `lib/core/network/api_endpoints.dart` pada aplikasi dan tabel endpoint ini dalam pull request yang sama.
