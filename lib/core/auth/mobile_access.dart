class JabatanKode {
  JabatanKode._();

  static const String spv = 'SPV';
  static const String seniorStaff = 'SENIOR_STAFF';
  static const String staff = 'STAFF';
  static const String manager = 'MANAGER';
  static const String kadep = 'KADEP';

  static String? fromUser(Map<String, dynamic>? user) {
    if (user == null) return null;

    final employee = user['employee'] as Map<String, dynamic>?;
    final pegawai = user['pegawai'] as Map<String, dynamic>?;
    final pegawaiJabatan = pegawai?['jabatan'] as Map<String, dynamic>?;

    final explicit = _firstNonEmpty([
      employee?['jabatan_kode'],
      pegawaiJabatan?['kode'],
    ]);
    if (explicit != null) return explicit;

    final fromNama = _fromNama(
      _firstNonEmpty([
        user['jabatan_nama'],
        employee?['position_name'],
        pegawaiJabatan?['nama'],
      ]),
    );
    if (fromNama != null) return fromNama;

    return _fromId(_toInt(user['jabatan_id'] ?? employee?['position_id']));
  }

  static String? _fromNama(String? nama) {
    if (nama == null) return null;
    final n = nama.toUpperCase();
    if (n.contains('SUPERVISOR') || n == 'SPV') return spv;
    if (n.contains('SENIOR') && n.contains('STAFF')) return seniorStaff;
    if (n.contains('STAFF')) return staff;
    if (n.contains('MANAGER') || n.contains('MANAJER')) return manager;
    if (n.contains('KEPALA')) return kadep;
    return null;
  }

  static String? _fromId(int? id) {
    switch (id) {
      case 1:
        return kadep;
      case 2:
      case 3:
        return manager;
      case 4:
        return spv;
      case 5:
        return seniorStaff;
      case 6:
        return staff;
    }
    return null;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

enum MobileAccessResult { allowed, deniedRole, deniedDepartemen, deniedJabatan }

class MobileAccess {
  MobileAccess._();

  /// Role pada `m_role` (1 superadmin, 2 admin, 3 manager, 4/5 employee/spv).
  static const Set<int> allowedRoleIds = {4, 5};

  /// Departemen yang diizinkan: Operasional (1) & Pelayanan (2). Keuangan (3) ditolak.
  static const Set<int> allowedDepartemenIds = {1, 2};

  /// Jabatan yang diizinkan masuk aplikasi Mobile.
  static const Set<String> allowedJabatanKode = {
    JabatanKode.spv,
    JabatanKode.seniorStaff,
    JabatanKode.staff,
  };

  /// Evaluasi berurutan: role -> departemen -> jabatan. Berhenti di gerbang
  /// pertama yang gagal supaya pesan penolakan bisa spesifik.
  static MobileAccessResult evaluate(Map<String, dynamic>? user) {
    if (user == null) return MobileAccessResult.deniedRole;

    // Gerbang 1 — role harus employee/spv.
    if (!allowedRoleIds.contains(_toInt(user['role_id']))) {
      return MobileAccessResult.deniedRole;
    }

    // Gerbang 2 — departemen harus Operasional/Pelayanan.
    final employee = user['employee'] as Map<String, dynamic>?;
    final departemenId = _toInt(
      user['departemen_id'] ?? employee?['department_id'],
    );
    if (departemenId == null || !allowedDepartemenIds.contains(departemenId)) {
      return MobileAccessResult.deniedDepartemen;
    }

    // Gerbang 3 — jabatan harus SPV/Staff Senior/Staff.
    final kode = JabatanKode.fromUser(user);
    if (kode == null || !allowedJabatanKode.contains(kode)) {
      return MobileAccessResult.deniedJabatan;
    }

    return MobileAccessResult.allowed;
  }

  static bool isAllowed(Map<String, dynamic>? user) =>
      evaluate(user) == MobileAccessResult.allowed;

  /// Pesan penolakan (Bahasa Indonesia) sesuai gerbang yang gagal.
  static String denyMessage(MobileAccessResult result) {
    switch (result) {
      case MobileAccessResult.deniedRole:
        return 'Aplikasi ini hanya untuk pegawai lapangan (Staff/Supervisor).';
      case MobileAccessResult.deniedDepartemen:
        return 'Aplikasi hanya tersedia untuk departemen Operasional dan Pelayanan.';
      case MobileAccessResult.deniedJabatan:
        return 'Aplikasi hanya tersedia untuk jabatan Staff, Staff Senior, dan Supervisor.';
      case MobileAccessResult.allowed:
        return '';
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
