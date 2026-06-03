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
  final String birthDate;
  final String position;
  final String country;
  final String state;
  final String city;
  final String address;

  const PersonalDataViewData({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.position,
    required this.country,
    required this.state,
    required this.city,
    required this.address,
  });
}

class ProfileViewDataResolver {
  static const PersonalDataViewData defaultPersonalData = PersonalDataViewData(
    firstName: '-',
    lastName: '-',
    birthDate: '-',
    position: 'Staff',
    country: '-',
    state: '-',
    city: '-',
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
    final birthDate = _formatBirthDate(employee['birth_date']);

    return ProfileViewData(
      fullName: fullName,
      email: email,
      address: address,
      roleName: roleName,
      personalData: PersonalDataViewData(
        firstName: split.$1,
        lastName: split.$2,
        birthDate: birthDate,
        position: roleName,
        country: address == '-' ? '-' : 'Indonesia',
        state: address == '-' ? '-' : 'DKI Jakarta',
        city: address == '-' ? '-' : 'Jakarta Selatan',
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

  static String resolvePositionLabel(Map<String, dynamic> user) {
    final employee = user['employee'] as Map<String, dynamic>?;
    final fromEmployee = employee?['jabatan_kode'] as String?;

    final pegawai = user['pegawai'] as Map<String, dynamic>?;
    final jabatan = pegawai?['jabatan'] as Map<String, dynamic>?;
    final fromPegawai = jabatan?['kode'] as String?;

    final positionId = _toInt(employee?['position_id']);
    String? legacyJabatan;
    switch (positionId) {
      case 2:
        legacyJabatan = 'SPV';
        break;
      case 3:
        legacyJabatan = 'SENIOR_STAFF';
        break;
      case 4:
        legacyJabatan = 'STAFF';
        break;
    }

    final kode =
        fromEmployee ??
        fromPegawai ??
        legacyJabatan ??
        AuthStorage.getJabatanKodeSync();

    if (kode == 'SPV') return 'Supervisor';
    if (kode == 'SENIOR_STAFF') return 'Senior Staff';
    return 'Staff';
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
