# Analisa Error 422 Progress Work Order

## Ringkasan Masalah
- Mobile menerima response `422 Unprocessable Entity`.
- Pesan validasi backend: `tipe_progress_kode` wajib diisi.
- Payload FE saat ini pada endpoint progress masih mengirim `tipe_progress`.

## Bukti dari Sisi FE
- Lokasi builder payload:
  - `lib/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart`
- Endpoint yang dipakai:
  - `POST /v1/progress-workorder/start`
  - `POST /v1/progress-workorder/submit`
- Field yang saat ini dikirim FE:
  - `tipe_progress = MULAI | PROGRESS | SELESAI`

## Analisa Akar Masalah
- Terjadi mismatch kontrak request antara FE dan BE:
  - BE memvalidasi `tipe_progress_kode`.
  - FE mengirim `tipe_progress`.
- Karena key yang diharapkan tidak ada, request ditolak di layer validasi (422).

## Kesimpulan
- Ini bukan bug UI murni.
- Ini issue integrasi kontrak API FE-BE.
- Jika kontrak backend terbaru memang `tipe_progress_kode`, maka FE perlu menyesuaikan key request.

## Rekomendasi
1. **Jangka pendek (aman lintas environment)**  
   FE kirim dua key sementara:
   - `tipe_progress_kode` (sesuai kontrak baru)
   - `tipe_progress` (fallback untuk backend lama)
2. **Jangka menengah (rapikan kontrak)**  
   Sinkronkan API spec agar hanya satu key yang resmi dipakai.
3. **Jangka panjang**  
   Tambah contract test BE/FE untuk endpoint progress supaya mismatch key bisa terdeteksi sebelum release.
