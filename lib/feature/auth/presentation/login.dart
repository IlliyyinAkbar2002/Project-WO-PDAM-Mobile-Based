import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/config/app_config.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/auth/data/remote/auth_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/landing/landing_page.dart'
    as admin;
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/manajer/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/register.dart';

class _LoginTokens {
  static const Color bgGradientStart = Color(0xFFCEFAFE); // rgb(206,250,254)
  static const Color bgGradientMid = Color(0xFFF0FDFA); // rgb(240,253,250)
  static const Color bgGradientEnd = Color(0xFFDCFCE7); // rgb(220,252,231)

  static const Color blobCyan = Color(0x80A2F4FD); // rgba(162,244,253,0.5)
  static const Color blobGreen = Color(0x80B9F8CF); // rgba(185,248,207,0.5)
  static const Color blobTeal = Color(0x8096F7E4); // rgba(150,247,228,0.5)

  static const Color textPrimary = Color(0xFF022F2E); // dark teal/green
  static const Color textSecondary = Color(0xFF6A7282); // slate-500
  static const Color hintColor = Color(0xFF99A1AF); // slate-400
  static const Color accentGreen = Color(0xFF16A34A); // green-600
  static const Color footerTeal = Color(0xFF0B4F4A); // dark teal

  static const Color buttonStart = Color(0xFFFB923C); // orange-400
  static const Color buttonEnd = Color(0xFFFB7185); // rose-400

  static const Color glassWhite70 = Color(0xB3FFFFFF);
  static const Color glassWhite50 = Color(0x80FFFFFF);
  static const Color glassWhite30 = Color(0x4DFFFFFF);
  static const Color glassBorder80 = Color(0xCCFFFFFF);
  static const Color glassBorder70 = Color(0xB3FFFFFF);
  static const Color glassBorder50 = Color(0x80FFFFFF);
}

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildGradientBackground(),
          _buildDecorativeBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      64,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLoginCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Background gradien cyan -> mint -> light green (114°)
  Widget _buildGradientBackground() {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -0.45),
            end: Alignment(0.9, 0.45),
            colors: [
              _LoginTokens.bgGradientStart,
              _LoginTokens.bgGradientMid,
              _LoginTokens.bgGradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  /// Tiga bola warna buram sebagai efek dekoratif ala Figma
  Widget _buildDecorativeBlobs() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -90,
              left: -40,
              child: _buildBlob(size: 320, color: _LoginTokens.blobCyan),
            ),
            Positioned(
              top: 160,
              left: 20,
              child: _buildBlob(size: 260, color: _LoginTokens.blobGreen),
            ),
            Positioned(
              top: 260,
              right: -80,
              child: _buildBlob(size: 380, color: _LoginTokens.blobTeal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob({required double size, required Color color}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  /// Kartu utama dengan efek glassmorphism.
  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: _LoginTokens.glassWhite50,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _LoginTokens.glassBorder70, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1F2687), // rgba(31,38,135,0.05)
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildLogo(),
                const SizedBox(height: 20),
                _buildCompanyInfo(),
                const SizedBox(height: 28),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 12),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildForgotPasswordLink(),
                const SizedBox(height: 16),
                _buildRegisterLink(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Center(
          child: ClipOval(
            child: SizedBox(
              width: 68.56,
              height: 68.56,
              child: Image.asset(
                'assets/images/logo_pdam.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.water_drop_rounded,
                  color: _LoginTokens.footerTeal,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
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
            color: _LoginTokens.textPrimary,
            letterSpacing: -0.6,
            height: 1.33,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          'Portal Work Order',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _LoginTokens.textSecondary,
            height: 1.43,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return _GlassTextField(
      controller: _usernameController,
      hintText: 'Masukkan email',
      prefixIcon: Icons.person_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email harus diisi';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _GlassTextField(
      controller: _passwordController,
      hintText: 'Masukkan password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !_isPasswordVisible,
      suffixIcon: IconButton(
        splashRadius: 20,
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _LoginTokens.hintColor,
          size: 22,
        ),
        onPressed: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password harus diisi';
        }
        return null;
      },
    );
  }

  /// Gradient pill button (orange -> pink) dengan soft shadow
  Widget _buildLoginButton() {
    final bool disabled = _isLoading;
    const borderRadius = BorderRadius.all(Radius.circular(999));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnimatedOpacity(
        opacity: disabled ? 0.8 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 54.46,
          decoration: const BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Color(0x80FB7185), // rgba(251,113,133,0.5)
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_LoginTokens.buttonStart, _LoginTokens.buttonEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: borderRadius,
              ),
              child: InkWell(
                onTap: disabled ? null : _handleLogin,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.375,
                            height: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleForgotPassword,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            'Lupa Password?',
            style: TextStyle(
              color: _LoginTokens.accentGreen,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
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
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: _LoginTokens.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Belum punya akun?  '),
                TextSpan(
                  text: 'Daftar Sekarang',
                  style: TextStyle(
                    color: _LoginTokens.accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Footer: glass pill button untuk Test Koneksi + copyright uppercase
  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _testConnection,
                child: Container(
                  decoration: BoxDecoration(
                    color: _LoginTokens.glassWhite30,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _LoginTokens.glassBorder50,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monitor_heart_outlined,
                        color: _LoginTokens.footerTeal,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Test Koneksi API',
                        style: TextStyle(
                          color: _LoginTokens.footerTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.325,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '© 2024 PDAM SURYA SEMBADA. SEMUA HAK DILINDUNGI.',
          style: TextStyle(
            color: Color(0x660B4F4A), // rgba(11,79,74,0.4)
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.55,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

          if (authResponse.token != null) {
            await AuthStorage.saveToken(authResponse.token!);
            debugPrint(
              '🔐 Token saved: ${authResponse.token!.substring(0, 10)}...',
            );
          }

          final meResult = await authDataSource.fetchMe();

          int? roleId = authResponse.user?['role_id'];

          if (meResult is DataSuccess) {
            final userData = meResult.data!;
            await AuthStorage.saveUser(userData);
            debugPrint('👤 User saved: ${userData['email']}');
            roleId = userData['role_id'] as int?;
          } else {
            if (authResponse.user != null) {
              await AuthStorage.saveUser(authResponse.user!);
              debugPrint(
                '👤 User saved (fallback): ${authResponse.user!['email']}',
              );
            }
          }

          if (!mounted) return;

          final message = authResponse.message ?? 'Login berhasil!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          Widget targetPage;

          int? positionId;
          if (meResult is DataSuccess<Map<String, dynamic>>) {
            positionId = meResult.data?['employee']?['position_id'] as int?;
          }

          debugPrint('🎭 Role ID: $roleId');
          debugPrint('👔 Position ID: $positionId');

          if (roleId == 1) {
            targetPage = const admin.LandingPage();
          } else if (roleId == 2) {
            targetPage = const ManajerLandingPage();
          } else if (roleId == 3) {
            if (positionId == 4) {
              targetPage = const SpvLandingPage();
            } else {
              targetPage = const StaffLandingPage();
            }
          } else {
            targetPage = const admin.LandingPage();
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => targetPage),
          );
        } else if (result is DataFailed) {
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
                behavior: SnackBarBehavior.floating,
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
              behavior: SnackBarBehavior.floating,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur lupa password akan segera tersedia'),
        backgroundColor: Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _testConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menguji koneksi ke server...'),
        backgroundColor: Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'ngrok-skip-browser-warning': 'true'},
        ),
      );

      debugPrint('🧪 Testing connection to API server...');
      final response = await dio.get('${AppConfig.backendDomain}/api/ping');

      debugPrint('✅ Connection successful!');
      debugPrint('📥 Response: ${response.data}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Koneksi berhasil!\nStatus: ${response.statusCode}'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } on DioException catch (e) {
      debugPrint('❌ Connection test failed!');
      debugPrint('Type: ${e.type}');
      debugPrint('Message: ${e.message}');

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
          behavior: SnackBarBehavior.floating,
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

/// Glassmorphism text field - bg rgba(255,255,255,0.7), border putih 1.5px,
/// radius 20px, tinggi 59.45px. Sesuai spec Figma.
class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _LoginTokens.glassWhite70,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _LoginTokens.glassBorder80, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _LoginTokens.textPrimary,
            ),
            cursorColor: _LoginTokens.accentGreen,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: _LoginTokens.hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 18, right: 10),
                child: Icon(
                  prefixIcon,
                  color: _LoginTokens.hintColor,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 22,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
