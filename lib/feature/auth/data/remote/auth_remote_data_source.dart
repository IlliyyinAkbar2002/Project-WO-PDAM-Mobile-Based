import 'package:dio/dio.dart';
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
      print('📝 Attempting register for: $email');
      print('📡 Full URL: ${dio.options.baseUrl}/v1/auth/register');

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

      print('✅ Register response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      final data = AuthResponseModel.fromMap(response.data);
      return DataSuccess(data);
    } on DioException catch (e) {
      print('❌ Register DioException Type: ${e.type}');
      print('❌ Error Message: ${e.message}');
      print('❌ Response Status: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      return DataFailed(e);
    } catch (e) {
      print('❌ Register Unexpected Error: $e');
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
      print('🔐 Attempting login for: $email');
      print('📡 Full URL: ${dio.options.baseUrl}/v1/auth/login');
      print('📡 Headers: ${dio.options.headers}');
      print(
        '📤 Sending data: {email: $email, password: ${password.replaceAll(RegExp(r'.'), '*')}}',
      );

      final response = await post(
        path: '/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      print('✅ Login response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response data: ${response.data}');

      final data = AuthResponseModel.fromMap(response.data);
      return DataSuccess(data);
    } on DioException catch (e) {
      print('❌ DioException Type: ${e.type}');
      print('❌ Error Message: ${e.message}');
      print('❌ Response Status: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      print('❌ Response Headers: ${e.response?.headers}');
      print('❌ Request URL: ${e.requestOptions.uri}');
      print('❌ Request Headers: ${e.requestOptions.headers}');
      return DataFailed(e);
    } catch (e) {
      print('❌ Unexpected Error: $e');
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
      print('👤 Fetching user profile from /me...');

      final response = await get(path: '/v1/auth/me');

      print('✅ Me response status: ${response.statusCode}');
      print('📥 Me response data: ${response.data}');

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
      print('❌ Me DioException Type: ${e.type}');
      print('❌ Me Error Message: ${e.message}');
      print('❌ Me Response Status: ${e.response?.statusCode}');
      print('❌ Me Response Data: ${e.response?.data}');
      return DataFailed(e);
    } catch (e) {
      print('❌ Me Unexpected Error: $e');
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/auth/me'),
        ),
      );
    }
  }
}
