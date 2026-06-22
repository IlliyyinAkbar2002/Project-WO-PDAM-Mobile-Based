import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/auth/model/auth_response_model.dart';

class AuthRemoteDataSource extends RemoteDatasource {
  AuthRemoteDataSource() : super();

  Future<DataState<AuthResponseModel>> register({
    required String name,
    required String email,
    required String password,
    required String telepon,
    required String jenisKelamin,
    required String tanggalLahir,
  }) async {
    try {

      final response = await post(
        path: '/v1/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'telepon': telepon,
          'jenis_kelamin': jenisKelamin,
          'tanggal_lahir': tanggalLahir,
        },
      );


      final data = AuthResponseModel.fromMap(response.data);
      return DataSuccess(data);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      debugPrint('❌ Unexpected Error during registration: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/auth/register'),
        ),
      );
    }
  }

  Future<DataState<AuthResponseModel>> login({
    required String email,
    required String password,
  }) async {
    try {

      final response = await post(
        path: '/v1/auth/login',
        data: {'email': email, 'password': password},
      );


      final data = AuthResponseModel.fromMap(response.data);
      return DataSuccess(data);
    } on DioException catch (e) {
      debugPrint('❌ DioException during login: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      debugPrint('❌ Unexpected Error during login: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/auth/login'),
        ),
      );
    }
  }

  /// Forgot password — screen 1.
  /// Cek apakah email terdaftar. Endpoint publik (tanpa auth).
  /// 200 → kembalikan email ternormalisasi dari server (fallback ke input).
  /// 404 → DataFailed (ApiException "Email tidak terdaftar").
  Future<DataState<String>> forgotPassword({required String email}) async {
    try {
      final response = await post(
        path: '/v1/auth/forgot-password',
        data: {'email': email},
      );

      final data = response.data;
      final resolvedEmail = (data is Map && data['email'] is String)
          ? data['email'] as String
          : email;
      return DataSuccess(resolvedEmail);
    } on DioException catch (e) {
      debugPrint('❌ DioException during forgotPassword: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      debugPrint('❌ Unexpected Error during forgotPassword: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/auth/forgot-password'),
        ),
      );
    }
  }

  /// Forgot password — screen 2.
  /// Set password baru untuk email yang sudah diverifikasi di screen 1.
  /// 200 → kembalikan pesan sukses dari server.
  Future<DataState<String>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await post(
        path: '/v1/auth/reset-password',
        data: {'email': email, 'new_password': newPassword},
      );

      final data = response.data;
      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Password berhasil diatur ulang.';
      return DataSuccess(message);
    } on DioException catch (e) {
      debugPrint('❌ DioException during resetPassword: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      debugPrint('❌ Unexpected Error during resetPassword: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/auth/reset-password'),
        ),
      );
    }
  }

  /// Ambil data pegawai lengkap dari `/v1/pegawai/{id}`.
  ///
  /// Respons login hanya mengirim kolom user tipis (tanpa `nip`,
  /// `tanggal_lahir`, `alamat`), jadi profil mengambil sisa data pegawai
  /// dari endpoint ini. Lihat [PegawaiController::show] di backend.
  Future<DataState<Map<String, dynamic>>> fetchPegawaiProfile(
    int pegawaiId,
  ) async {
    try {
      final response = await get(path: '/v1/pegawai/$pegawaiId');
      final data = response.data;
      if (data is Map) {
        return DataSuccess(Map<String, dynamic>.from(data));
      }
      return DataFailed(
        DioException(
          error: 'Format respons pegawai tidak valid',
          requestOptions: RequestOptions(path: '/v1/pegawai/$pegawaiId'),
        ),
      );
    } on DioException catch (e) {
      debugPrint('❌ fetchPegawaiProfile DioException: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      debugPrint('❌ fetchPegawaiProfile Unexpected Error: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/pegawai/$pegawaiId'),
        ),
      );
    }
  }

  /// Fetch current user profile from /me endpoint
  /// Returns user data transformed to standard format
  Future<DataState<Map<String, dynamic>>> fetchMe() async {
    try {
      debugPrint('🔍 Fetching user profile from /v1/auth/me');

      final response = await get(path: '/v1/auth/me');

      debugPrint('✅ Me response status: ${response.statusCode}');
      debugPrint('📥 Me response data: ${response.data}');

      final data = response.data as Map<String, dynamic>;

      final pegawai = data['pegawai'] as Map<String, dynamic>?;
      final jabatan = pegawai?['jabatan'] as Map<String, dynamic>?;
      final transformedData = {
        'id': data['id'],
        'email': data['email'],
        'name': data['name'],
        'role_id': data['role_id'],
        'employee': pegawai != null
            ? {
                'name': pegawai['nama'],
                'employee_id': pegawai['nip'],
                'id': pegawai['id'],
                'birth_date': pegawai['tanggal_lahir'],
                'gender': pegawai['jenis_kelamin'],
                'address': pegawai['alamat'],
                'phone': pegawai['telepon'],
                'department_id': pegawai['departemen_id'],
                'position_id': pegawai['jabatan_id'],
                'jabatan_kode': jabatan?['kode'],
              }
            : null,
      };

      return DataSuccess(transformedData);
    } on DioException catch (e) {
      debugPrint('❌ Me DioException Type: ${e.type}');
      debugPrint('❌ Me Error Message: ${e.message}');
      debugPrint('❌ Me Response Status: ${e.response?.statusCode}');
      debugPrint('❌ Me Response Data: ${e.response?.data}');
      return DataFailed(e);
    } catch (e) {
      debugPrint('❌ Me Unexpected Error: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/auth/me'),
        ),
      );
    }
  }
}
