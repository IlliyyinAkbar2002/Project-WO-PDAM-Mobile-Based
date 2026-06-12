const List<String> kTahapanGeneric = [
  'Persiapan',
  'Pengerjaan',
  'Pengujian',
  'Dokumentasi',
];

/// Keyed by jenis pekerjaan name as returned by the API.
const Map<String, List<String>> kTahapanByJenis = {
  'Kalibrasi Meteran': [
    'Cek fisik & catat stand awal',
    'Uji akurasi / kalibrasi',
    'Verifikasi hasil',
    'Segel ulang + foto',
  ],
  'Penggantian Meteran': [
    'Catat stand meter lama',
    'Lepas & pasang meteran baru',
    'Cek kebocoran sambungan',
    'Segel + dokumentasi',
  ],
  'Pemasangan Meteran': [
    'Survei titik pemasangan',
    'Pasang meteran & fitting',
    'Uji aliran air',
    'Segel + catat stand awal',
  ],
  'Penanganan Kebocoran': [
    'Lokalisir titik bocor',
    'Penggalian & penambalan',
    'Uji aliran',
    'Penimbunan + dokumentasi',
  ],
  'Perbaikan Pipa': [
    'Identifikasi & isolasi aliran',
    'Ganti / perbaiki pipa',
    'Buka aliran & uji',
    'Pemulihan lokasi + dokumentasi',
  ],
  'Pembersihan Saluran': [
    'Identifikasi titik sumbatan',
    'Flushing / pembersihan',
    'Cek kelancaran aliran',
    'Dokumentasi',
  ],
  'Inspeksi Jaringan': [
    'Tentukan rute inspeksi',
    'Cek tekanan & kondisi jaringan',
    'Verifikasi temuan',
    'Laporan hasil inspeksi',
  ],
  'Pemeliharaan Pompa': [
    'Cek kondisi pompa',
    'Servis / ganti part',
    'Uji running pompa',
    'Catat hasil pemeliharaan',
  ],
  'Instalasi Baru': [
    'Survei & persiapan material',
    'Pemasangan / instalasi',
    'Uji fungsi',
    'Serah terima + dokumentasi',
  ],
};

List<String> tahapanLabelsFor(String? jenisNama) =>
    kTahapanByJenis[jenisNama] ?? kTahapanGeneric;
