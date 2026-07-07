import 'package:project_mobile_pdam/core/auth/mobile_access.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';

class ProfileViewData {
  final String fullName;
  final String email;
  final String address;
  final String roleName;
  final PersonalDataViewData personalData;

  const ProfileViewData({
    required this.fullName,
    required this.email,
    required this.address,
    required this.roleName,
    required this.personalData,
  });
}

class PersonalDataViewData {
  final String firstName;
  final String lastName;
  final String nip;
  final String birthDate;
  final String position;
  final String department;
  // final String country;
  // final String state;
  // final String city;
  final String address;

  const PersonalDataViewData({
    required this.firstName,
    required this.lastName,
    required this.nip,
    required this.birthDate,
    required this.position,
    required this.department,
    // required this.country,
    // required this.state,
    // required this.city,
    required this.address,
  });
}

class ProfileViewDataResolver {
  static const PersonalDataViewData defaultPersonalData = PersonalDataViewData(
    firstName: '-',
    lastName: '-',
    nip: '-',
    birthDate: '-',
    position: 'Staff',
    department: '-',
    address: '-',
  );

  static const ProfileViewData defaultProfileData = ProfileViewData(
    fullName: '-',
    email: '-',
    address: '-',
    roleName: 'Staff',
    personalData: defaultPersonalData,
  );

  static ProfileViewData resolveOrDefault() {
    try {
      return fromCurrentUser();
    } catch (_) {
      return defaultProfileData;
    }
  }

  static ProfileViewData fromCurrentUser() {
    final user = AuthStorage.getUserSync() ?? <String, dynamic>{};
    final employee =
        (user['employee'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final fullName = (employee['name'] ?? user['name'] ?? '-').toString();
    final email = (user['email'] ?? '-').toString();
    final address = (employee['address'] ?? '-').toString();

    final split = _splitName(fullName);
    final roleName = resolvePositionLabel(user);
    final department = resolveDepartmentLabel(user);
    final birthDate = _formatBirthDate(employee['birth_date']);
    final nip = resolveNip(user);

    return ProfileViewData(
      fullName: fullName,
      email: email,
      address: address,
      roleName: roleName,
      personalData: PersonalDataViewData(
        firstName: split.$1,
        lastName: split.$2,
        nip: nip,
        birthDate: birthDate,
        position: roleName,
        department: department,
        // country: address == '-' ? '-' : 'Indonesia',
        // state: address == '-' ? '-' : 'DKI Jakarta',
        // city: address == '-' ? '-' : 'Jakarta Selatan',
        address: address,
      ),
    );
  }

  static (String, String) _splitName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty || trimmed == '-') return ('-', '-');
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 1) return (words.first, '-');
    return (words.first, words.sublist(1).join(' '));
  }

  /// NIP pegawai dari data pegawai (bukan dari user/login), '-' bila kosong.
  static String resolveNip(Map<String, dynamic> user) {
    final employee = user['employee'] as Map<String, dynamic>?;
    final nip = (employee?['nip'] ?? employee?['employee_id'])?.toString();
    if (nip != null && nip.trim().isNotEmpty) return nip.trim();
    return '-';
  }

  /// Nama departemen pegawai (mis. 'Operasional'), '-' bila tidak tersedia.
  static String resolveDepartmentLabel(Map<String, dynamic> user) {
    final employee = user['employee'] as Map<String, dynamic>?;
    final nama = (user['departemen_nama'] ?? employee?['department_name'])
        ?.toString();
    if (nama != null && nama.trim().isNotEmpty) return nama.trim();
    return '-';
  }

  static String resolvePositionLabel(Map<String, dynamic> user) {
    // Utamakan nama jabatan asli dari backend bila tersedia.
    final employee = user['employee'] as Map<String, dynamic>?;
    final nama = (user['jabatan_nama'] ?? employee?['position_name'])
        ?.toString();
    if (nama != null && nama.trim().isNotEmpty) return nama.trim();

    final kode = JabatanKode.fromUser(user) ?? AuthStorage.getJabatanKodeSync();
    switch (kode) {
      case JabatanKode.spv:
        return 'Supervisor';
      case JabatanKode.seniorStaff:
        return 'Senior Staff';
      case JabatanKode.manager:
        return 'Manager';
      case JabatanKode.kadep:
        return 'Kepala Departemen';
      default:
        return 'Staff';
    }
  }

  static String _formatBirthDate(dynamic rawBirthDate) {
    final value = (rawBirthDate ?? '').toString();
    if (value.isEmpty) return '-';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
