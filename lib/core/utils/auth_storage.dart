import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_mobile_pdam/core/auth/mobile_access.dart';

/// Persistent auth token storage using FlutterSecureStorage
class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  // In-memory cache for performance
  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    // Return cached token if available
    if (_cachedToken != null) {
      return _cachedToken;
    }
    // Otherwise read from secure storage
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// Synchronous token getter for RemoteDatasource (uses cache)
  static String? getTokenSync() {
    return _cachedToken;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    _cachedUser = user;
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    // Return cached user if available
    if (_cachedUser != null) {
      return _cachedUser;
    }
    // Otherwise read from secure storage
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      _cachedUser = jsonDecode(userJson) as Map<String, dynamic>;
    }
    return _cachedUser;
  }

  /// Synchronous user getter (uses cache)
  static Map<String, dynamic>? getUserSync() {
    return _cachedUser;
  }

  /// Kode jabatan user yang sedang login ('SPV', 'SENIOR_STAFF', 'STAFF', ...).
  /// Diturunkan dari nama/id jabatan via [JabatanKode] (lihat mobile_access.dart).
  static String? getJabatanKodeSync() => JabatanKode.fromUser(_cachedUser);

  /// Normalisasi objek `user` dari respons login ke bentuk kanonik yang dipakai
  /// seluruh aplikasi: tetap menyimpan field flat (role_id, departemen_*,
  /// jabatan_*) dan menambahkan `jabatan_kode` serta sub-map `employee` agar
  /// header/profil/resolver lama tetap menemukan datanya.
  ///
  /// Endpoint /me yang baru hanya mengembalikan kolom user tipis tanpa jabatan
  /// & departemen, jadi respons login adalah sumber data terkaya.
  static Map<String, dynamic> normalizeLoginUser(Map<String, dynamic> raw) {
    final kode = JabatanKode.fromUser(raw);
    return {
      ...raw,
      if (kode != null) 'jabatan_kode': kode,
      'employee': {
        'name': raw['name'],
        'id': raw['pegawai_id'],
        'department_id': raw['departemen_id'],
        'department_name': raw['departemen_nama'],
        'position_id': raw['jabatan_id'],
        'position_name': raw['jabatan_nama'],
        if (kode != null) 'jabatan_kode': kode,
      },
    };
  }

  /// Lengkapi sub-map `employee` pada user yang tersimpan dengan data pegawai
  /// penuh dari `/v1/pegawai/{id}` (mis. `nip`, `tanggal_lahir`, `alamat`) yang
  /// tidak ikut di respons login. Bersifat best-effort: bila belum ada user
  /// tersimpan, tidak melakukan apa-apa.
  static Future<void> enrichEmployeeFromPegawai(
    Map<String, dynamic> pegawai,
  ) async {
    final user = _cachedUser;
    if (user == null) return;

    final employee = <String, dynamic>{
      ...((user['employee'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{}),
      'nip': pegawai['nip'],
      'birth_date': pegawai['tanggal_lahir'],
      'gender': pegawai['jenis_kelamin'],
      'address': pegawai['alamat'],
      'phone': pegawai['telepon'],
    };

    await saveUser({...user, 'employee': employee});
  }

  static Future<void> clearAuth() async {
    _cachedToken = null;
    _cachedUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  static bool isLoggedIn() {
    return _cachedToken != null;
  }

  /// Initialize auth storage by loading cached values
  static Future<void> initialize() async {
    _cachedToken = await _storage.read(key: _tokenKey);
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      try {
        _cachedUser = jsonDecode(userJson) as Map<String, dynamic>;
      } catch (e) {
        // Invalid JSON, clear it
        await _storage.delete(key: _userKey);
      }
    }
  }
}
