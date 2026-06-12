import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static String? getJabatanKodeSync() {
    final user = _cachedUser;
    if (user == null) return null;

    final employee = user['employee'] as Map<String, dynamic>?;
    final fromEmployee = employee?['jabatan_kode'] as String?;
    if (fromEmployee != null && fromEmployee.isNotEmpty) return fromEmployee;

    final pegawai = user['pegawai'] as Map<String, dynamic>?;
    final jabatan = pegawai?['jabatan'] as Map<String, dynamic>?;
    final fromPegawai = jabatan?['kode'] as String?;
    if (fromPegawai != null && fromPegawai.isNotEmpty) return fromPegawai;

    final positionId = _toInt(employee?['position_id']);
    switch (positionId) {
      case 1:
        return 'MANAGER';
      case 2:
        return 'SPV';
      case 3:
        return 'SENIOR_STAFF';
      case 4:
        return 'STAFF';
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
