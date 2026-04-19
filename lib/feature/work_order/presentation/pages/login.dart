import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/config/app_config.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/auth_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/landing_page.dart'
    as admin;
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/manajer/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C4A5A), // Dark teal-blue background
              Color(0xFF1A3A4A), // Slightly darker bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    _buildLoginCard(),
                    const Spacer(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: 24),
            _buildCompanyInfo(),
            const SizedBox(height: 32),
            _buildUsernameField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 16),
            _buildForgotPasswordLink(),
            const SizedBox(height: 16),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2C4A5A), width: 3),
          color: const Color(0xFF4DD0E1), // Light teal-blue
        ),
        child: const Icon(Icons.security, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return const Column(
      children: [
        Text(
          'PDAM Surya Sembada',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C4A5A),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Portal Work Order',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C4A5A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Masukkan email',
            hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF4DD0E1),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4DD0E1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email harus diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C4A5A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Masukkan password',
            hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF4DD0E1),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF4DD0E1),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4DD0E1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password harus diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF9800), // Orange
                Color(0xFFF44336), // Red
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Masuk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: const Text(
          'Lupa Password?',
          style: TextStyle(
            color: Color(0xFF00897B), // Teal-green
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterPage()),
          );
        },
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            children: [
              TextSpan(text: 'Belum punya akun? '),
              TextSpan(
                text: 'Daftar Sekarang',
                style: TextStyle(
                  color: Color(0xFF00897B), // Teal-green
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.network_check, color: Color(0xFF4DD0E1)),
            label: const Text(
              'Test Koneksi API',
              style: TextStyle(color: Color(0xFF4DD0E1), fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '© 2024 PDAM Surya Sembada. Semua hak dilindungi.',
            style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authDataSource = AuthRemoteDataSource();
        final result = await authDataSource.login(
          email: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (result is DataSuccess) {
          final authResponse = result.data!;

          // Save token first (await to ensure persistence)
          if (authResponse.token != null) {
            await AuthStorage.saveToken(authResponse.token!);
            print('🔐 Token saved: ${authResponse.token!.substring(0, 10)}...');
          }

          // Fetch full user profile from /me endpoint
          final meResult = await authDataSource.fetchMe();

          int? roleId = authResponse.user?['role_id'];

          if (meResult is DataSuccess) {
            final userData = meResult.data!;
            await AuthStorage.saveUser(userData);
            print('👤 User saved with name: ${userData['name']}');
            roleId = userData['role_id'] as int?;
          } else {
            // Fallback to basic user data if /me fails
            if (authResponse.user != null) {
              await AuthStorage.saveUser(authResponse.user!);
              print('👤 User saved (fallback): ${authResponse.user!['email']}');
            }
          }

          if (!mounted) return;

          // Show success message
          final message = authResponse.message ?? 'Login berhasil!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to main page based on role AND position (jabatan)
          Widget targetPage;

          int? positionId;
          if (meResult is DataSuccess<Map<String, dynamic>>) {
            positionId = meResult.data?['employee']?['position_id'] as int?;
          }

          print('🎭 Role ID: $roleId');
          print('👔 Position ID: $positionId');

          if (roleId == 1) {
            // Superadmin
            targetPage = const admin.LandingPage();
          } else if (roleId == 2) {
            // Manager role - langsung ke Manajer Landing Page
            targetPage = const ManajerLandingPage();
          } else if (roleId == 3) {
            // Employee role - cek jabatan_id
            if (positionId == 4) {
              // Supervisor
              targetPage = const SpvLandingPage();
            } else {
              // Staff Senior (5) atau Staff (6)
              targetPage = const StaffLandingPage();
            }
          } else {
            // Default fallback
            targetPage = const admin.LandingPage();
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => targetPage),
          );
        } else if (result is DataFailed) {
          // Handle login failure
          String errorMessage = 'Email atau password salah';

          if (result.error is DioException) {
            final dioError = result.error as DioException;
            final resolvedMessage = _resolveLoginErrorMessage(
              dioError.response?.data,
            );

            if (resolvedMessage != null && resolvedMessage.isNotEmpty) {
              errorMessage = resolvedMessage;
            } else if (dioError.type == DioExceptionType.connectionTimeout ||
                dioError.type == DioExceptionType.receiveTimeout) {
              errorMessage = 'Koneksi timeout, periksa koneksi internet Anda';
            } else if (dioError.type == DioExceptionType.connectionError) {
              errorMessage = 'Tidak dapat terhubung ke server';
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: const Color(0xFFF44336),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: const Color(0xFFF44336),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleForgotPassword() {
    // TODO: Implement forgot password logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur lupa password akan segera tersedia'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _testConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menguji koneksi ke server...'),
        backgroundColor: Color(0xFF2196F3),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      print('🧪 Testing connection to API server...');
      final response = await dio.get('${AppConfig.backendDomain}/api/ping');

      print('✅ Connection successful!');
      print('📥 Response: ${response.data}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Koneksi berhasil!\nStatus: ${response.statusCode}'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );
    } on DioException catch (e) {
      print('❌ Connection test failed!');
      print('Type: ${e.type}');
      print('Message: ${e.message}');

      final targetUrl = '${AppConfig.backendDomain}/api/ping';
      String errorMsg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMsg = 'Timeout - Server tidak merespon\n$targetUrl';
          break;
        case DioExceptionType.receiveTimeout:
          errorMsg = 'Timeout - Server lambat merespon\n$targetUrl';
          break;
        case DioExceptionType.sendTimeout:
          errorMsg = 'Timeout - Gagal mengirim request\n$targetUrl';
          break;
        case DioExceptionType.connectionError:
          errorMsg =
              'Tidak dapat terhubung ke server\n$targetUrl\n'
              'Cek koneksi internet device & status server.\n'
              'Detail: ${e.message ?? '-'}';
          break;
        case DioExceptionType.badResponse:
          errorMsg =
              'Server merespon dengan error\n'
              'Status: ${e.response?.statusCode}\n$targetUrl';
          break;
        case DioExceptionType.cancel:
          errorMsg = 'Request dibatalkan';
          break;
        case DioExceptionType.badCertificate:
          errorMsg = 'Sertifikat SSL tidak valid\n$targetUrl';
          break;
        case DioExceptionType.unknown:
          errorMsg =
              'Gagal terhubung ke server\n$targetUrl\n'
              'Detail: ${e.message ?? '-'}';
          break;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMsg'),
          backgroundColor: const Color(0xFFF44336),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String? _resolveLoginErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    if (responseData is Map) {
      final data = responseData.cast<String, dynamic>();

      final errors = data['errors'];
      if (errors is Map) {
        final emailError = _firstErrorMessage(errors['email']);
        if (emailError != null) {
          return _normalizeFieldError(emailError, fieldLabel: 'Email');
        }

        final passwordError = _firstErrorMessage(errors['password']);
        if (passwordError != null) {
          return _normalizeFieldError(passwordError, fieldLabel: 'Password');
        }
      }

      final errorText = data['error'];
      if (errorText is String && errorText.isNotEmpty) {
        final lower = errorText.toLowerCase();
        if (lower.contains('email')) {
          return _normalizeFieldError(errorText, fieldLabel: 'Email');
        } else if (lower.contains('password')) {
          return _normalizeFieldError(errorText, fieldLabel: 'Password');
        }
        return errorText;
      }

      final messageText = data['message'];
      if (messageText is String && messageText.isNotEmpty) {
        return messageText;
      }
    }

    return null;
  }

  String? _firstErrorMessage(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  String _normalizeFieldError(String message, {required String fieldLabel}) {
    final lower = message.toLowerCase();
    final isEmptyField =
        lower.contains('harus diisi') ||
        lower.contains('tidak boleh kosong') ||
        lower.contains('required') ||
        lower.contains('tidak diisi') ||
        lower.contains('kosong');

    if (isEmptyField) {
      return '$fieldLabel harus diisi';
    }

    return message;
  }
}
