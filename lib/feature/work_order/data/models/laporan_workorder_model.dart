/// Data laporan PDF hasil endpoint `GET /api/v1/workorder/history/{id}`.
///
/// Menggabungkan field dari `workorder`, `assignment`, `members`, dan `laporan`
/// menjadi bentuk datar yang siap dirender pada [LaporanWorkorderPage].
class LaporanReportMember {
  final String nama;
  final String nip;
  final bool isPic;

  const LaporanReportMember({
    required this.nama,
    required this.nip,
    required this.isPic,
  });
}

class LaporanReportModel {
  final int? workorderId;
  final String nomorLaporan;
  final String kodePengaduan;
  final String lokasi;
  final String status;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String spvNama;
  final String spvNip;
  final List<LaporanReportMember> members;
  final String catatanSpv;
  final String hasilAkhir;
  final bool isLembur;

  const LaporanReportModel({
    required this.workorderId,
    required this.nomorLaporan,
    required this.kodePengaduan,
    required this.lokasi,
    required this.status,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.spvNama,
    required this.spvNip,
    required this.members,
    required this.catatanSpv,
    required this.hasilAkhir,
    required this.isLembur,
  });

  /// PIC pertama (untuk tanda tangan petugas pelaksana).
  LaporanReportMember? get pic {
    for (final m in members) {
      if (m.isPic) return m;
    }
    return members.isNotEmpty ? members.first : null;
  }

  factory LaporanReportModel.fromMap(
    Map<String, dynamic> root, {
    required int workorderId,
  }) {
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    String asString(dynamic v) {
      if (v == null) return '';
      final s = v.toString().trim();
      return s;
    }

    DateTime? asDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String && v.trim().isNotEmpty) {
        String raw = v.trim();
        if (!raw.endsWith('Z') && !raw.contains('+')) {
          raw = '${raw.replaceAll(' ', 'T')}Z';
        }
        return DateTime.tryParse(raw)?.toLocal();
      }
      return null;
    }

    String namaOf(Map<String, dynamic>? m) =>
        asString(m?['nama'] ?? m?['name']);
    String nipOf(Map<String, dynamic>? m) => asString(m?['nip']);

    final workorder = asMap(root['workorder']) ?? const {};
    final assignment =
        asMap(root['assignment']) ?? asMap(workorder['workorder_assignment']);
    final laporan =
        asMap(root['laporan']) ?? asMap(workorder['laporan_workorder']);
    final pengaduan = asMap(workorder['pengaduan']);

    // Kode pengaduan & lokasi.
    final kodePengaduan = asString(
      workorder['kode_pengaduan'] ?? pengaduan?['kode_pengaduan'],
    );
    final lokasi = asString(workorder['lokasi'] ?? pengaduan?['lokasi']);

    // Tanggal: mulai dari assignment, selesai = waktu laporan terbit (aktual).
    final tanggalMulai = asDate(assignment?['tanggal_mulai']);
    final tanggalSelesai =
        asDate(laporan?['tanggal_terbit']) ??
        asDate(assignment?['tanggal_selesai']);

    // SPV: dari assignment.spv, fallback workorder.assigned_to (relasi pegawai).
    final spv = asMap(assignment?['spv']) ?? asMap(workorder['assigned_to']);

    // Anggota petugas (+ tanda PIC).
    // Sumber utama: snapshot beku di laporan (nama/nip/is_pic level atas);
    // fallback ke relasi members bila laporan belum ada.
    final rawMembers =
        laporan?['petugas_snapshot'] ??
        root['members'] ??
        assignment?['members'] ??
        const <dynamic>[];
    final members = <LaporanReportMember>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        final m = asMap(item);
        if (m == null) continue;
        final pegawai = asMap(m['pegawai']) ?? asMap(m['user']) ?? m;
        final isPic =
            m['is_pic'] == true ||
            m['is_pic'] == 1 ||
            m['is_pic']?.toString() == '1' ||
            asString(m['peran']).toLowerCase() == 'koordinator';
        final nama = namaOf(pegawai);
        if (nama.isEmpty) continue;
        members.add(
          LaporanReportMember(nama: nama, nip: nipOf(pegawai), isPic: isPic),
        );
      }
    }

    return LaporanReportModel(
      workorderId: workorder['id'] is int ? workorder['id'] as int : workorderId,
      nomorLaporan: asString(laporan?['nomor_laporan']).isNotEmpty
          ? asString(laporan?['nomor_laporan'])
          : 'LP-$workorderId',
      kodePengaduan: kodePengaduan,
      lokasi: lokasi,
      status: asString(workorder['status']),
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      spvNama: namaOf(spv),
      spvNip: nipOf(spv),
      members: members,
      catatanSpv: asString(laporan?['catatan_spv']),
      hasilAkhir: asString(
        laporan?['ringkasan_pekerjaan'] ??
            workorder['nama_workorder'] ??
            workorder['judul_pekerjaan'],
      ),
      isLembur: workorder['lembur_spl_id'] != null,
    );
  }
}
