# Checklist Debug BE: Error `invalid input syntax for type bigint: "start"`

## Tujuan
- Menemukan titik backend yang mengirim/menyimpan string (`start`) ke kolom numerik (`bigint`), kemungkinan besar `tipe_progress_id`.
- Menentukan apakah kontrak endpoint progress harus menerima kode string, id integer, atau keduanya.

## Gejala yang Terlihat
- API mengembalikan `500` dengan pesan:
  - `SQLSTATE[22P02]: Invalid text representation: 7 ERROR: invalid input syntax for type bigint: "start"`
- Dari sisi mobile, flow progress memakai endpoint:
  - `POST /v1/progress-workorder/start`
  - `POST /v1/progress-workorder/submit`

## Hipotesis Utama
- Backend sedang mengisi field FK numerik (mis. `tipe_progress_id`) menggunakan string mode/action (`start`, `progress`, `finish`) tanpa mapping ke integer dari tabel master (`m_tipe_progress`).

## Checklist Investigasi (Laravel)

### 1) Pastikan kontrak request endpoint
- [ ] Buka `FormRequest`/validator untuk:
  - [ ] `POST /v1/progress-workorder/start`
  - [ ] `POST /v1/progress-workorder/submit`
- [ ] Catat field mana yang diwajibkan:
  - [ ] `workorder_id`
  - [ ] `tipe_progress` (string kode?) atau `tipe_progress_id` (int?)
- [ ] Jika `tipe_progress_id` yang dipakai untuk insert:
  - [ ] validasi harus `integer|exists:m_tipe_progress,id`
- [ ] Jika `tipe_progress` (string) yang dipakai:
  - [ ] validasi harus `in:MULAI,PROGRESS,SELESAI` (atau set kode yang dipakai backend)

### 2) Verifikasi mapping payload -> data insert/update
- [ ] Buka controller/service action progress (`start` dan `submit`).
- [ ] Temukan assignment field sebelum `create()`/`update()` model progress.
- [ ] Pastikan tidak ada assignment langsung seperti:
  - [ ] `$payload['tipe_progress_id'] = $request->tipe_progress` saat `tipe_progress` bernilai string.
- [ ] Jika request menerima string kode:
  - [ ] Lakukan mapping kode -> id:
    - [ ] cari id di `m_tipe_progress` berdasarkan `kode`.
    - [ ] simpan hasil id ke `tipe_progress_id`.

### 3) Audit enum/constant dan normalisasi nilai
- [ ] Cari semua referensi literal `'start'`, `'progress'`, `'finish'`, `'MULAI'`, `'PROGRESS'`, `'SELESAI'`.
- [ ] Pastikan satu sumber kebenaran kode progress (constant/enum), hindari campur lowercase-English dan uppercase-DB-code.
- [ ] Tambahkan normalisasi input (mis. `strtoupper(trim(...))`) sebelum mapping.

### 4) Audit model, mutator, dan cast
- [ ] Cek model progress:
  - [ ] `fillable`/`guarded`
  - [ ] `casts` untuk `tipe_progress_id` harus integer.
- [ ] Cek mutator/accessor yang mungkin menulis `tipe_progress_id` dari field string.
- [ ] Cek observer/event model (`creating`, `updating`) yang mungkin override field.

### 5) Tambahkan logging terarah (sementara)
- [ ] Log payload request mentah untuk endpoint progress.
- [ ] Log nilai final sebelum query DB:
  - [ ] `workorder_id`
  - [ ] `tipe_progress` (jika ada)
  - [ ] `tipe_progress_id` (harus integer/null)
- [ ] Log hasil mapping kode -> id (termasuk kasus gagal map).

### 6) Reproduksi minimal via API client
- [ ] Uji `POST /start` dengan payload valid minimal.
- [ ] Uji `POST /submit` untuk mode progress/selesai.
- [ ] Konfirmasi:
  - [ ] tidak ada 500 SQL error
  - [ ] response invalid input menjadi 422 dengan pesan validasi yang jelas

### 7) Hardening error handling
- [ ] Bungkus mapping gagal dengan exception domain yang jelas (jangan biarkan jatuh ke SQL error mentah).
- [ ] Kembalikan response 422/400 saat kode progress tidak dikenal.

## Checklist Fix Cepat (Rekomendasi)
- [ ] Tentukan kontrak final:
  - [ ] Opsi A: endpoint menerima `tipe_progress_id` (int) saja.
  - [ ] Opsi B: endpoint menerima `tipe_progress` (kode string) lalu backend map ke id.
- [ ] Implementasi konsisten di kedua endpoint (`start`, `submit`), jangan beda perilaku.
- [ ] Tambah test feature:
  - [ ] `start` sukses dengan payload valid.
  - [ ] `submit` sukses dengan payload valid.
  - [ ] payload string tidak valid -> 422.
  - [ ] payload numeric invalid -> 422.

## Definition of Done
- [ ] Error `SQLSTATE[22P02] ... "start"` tidak muncul lagi.
- [ ] Field `tipe_progress_id` selalu tersimpan sebagai integer valid.
- [ ] Semua endpoint progress mengembalikan error validasi yang terstruktur (bukan 500) untuk payload salah.
- [ ] Test API untuk kasus di atas lulus.
