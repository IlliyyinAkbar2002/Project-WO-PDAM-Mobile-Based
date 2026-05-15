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

  /// Fetch current user profile from /me endpoint
  /// Returns user data transformed to standard format
  Future<DataState<Map<String, dynamic>>> fetchMe() async {
    try {
      debugPrint('🔍 Fetching user profile from /v1/auth/me');

      final response = await get(path: '/v1/auth/me');

      debugPrint('✅ Me response status: ${response.statusCode}');
      debugPrint('📥 Me response data: ${response.data}');

      final data = response.data as Map<String, dynamic>;

      // Transform API response to standard format for UI
      // API returns: { id, name, email, role_id, pegawai: { nama, nip, ... } }
      // UI expects: { id, email, role_id, employee: { name, employee_id, ... } }
      final transformedData = {
        'id': data['id'],
        'email': data['email'],
        'name': data['name'],
        'role_id': data['role_id'],
        'employee': data['pegawai'] != null
            ? {
                'name': data['pegawai']['nama'],
                'employee_id': data['pegawai']['nip'],
                'id': data['pegawai']['id'],
                'birth_date': data['pegawai']['tanggal_lahir'],
                'gender': data['pegawai']['jenis_kelamin'],
                'address': data['pegawai']['alamat'],
                'phone': data['pegawai']['telepon'],
                'department_id': data['pegawai']['departemen_id'],
                'position_id': data['pegawai']['jabatan_id'],
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
