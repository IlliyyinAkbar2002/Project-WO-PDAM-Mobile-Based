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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color _navy = Color(0xFF022F2E);
  static const Color _teal = Color(0xFF0B4F4A);
  static const Color _accentGreen = Color(0xFF16A34A);
  static const Color _buttonStart = Color(0xFFFB923C);
  static const Color _buttonEnd = Color(0xFFFB7185);
  static const Color _hint = Color(0xFF99A1AF);
  static const Color _muted = Color(0xFF6A7282);
  static const Color _glassWhite70 = Color(0xB3FFFFFF);
  static const Color _glassWhite50 = Color(0x80FFFFFF);
  static const Color _glassWhite30 = Color(0x4DFFFFFF);
  static const Color _glassBorder80 = Color(0xCCFFFFFF);
  static const Color _glassBorder70 = Color(0xB3FFFFFF);
  static const Color _glassBorder50 = Color(0x80FFFFFF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedGender;

  /// Store the picked date (for ISO formatting when submitting).
  DateTime? _pickedDob;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRegisterCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -0.45),
            end: Alignment(0.9, 0.45),
            colors: [Color(0xFFCEFAFE), Color(0xFFF0FDFA), Color(0xFFDCFCE7)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeBlobs() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -90,
              left: -40,
              child: _buildBlob(size: 320, color: const Color(0x80A2F4FD)),
            ),
            Positioned(
              top: 170,
              left: 10,
              child: _buildBlob(size: 260, color: const Color(0x80B9F8CF)),
            ),
            Positioned(
              top: 330,
              right: -100,
              child: _buildBlob(size: 390, color: const Color(0x8096F7E4)),
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

  Widget _buildRegisterCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
          decoration: BoxDecoration(
            color: _glassWhite50,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _glassBorder70, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1F2687),
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
                _buildLogo(),
                const SizedBox(height: 18),
                _buildCompanyInfo(),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  hint: 'Masukkan nama lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'contoh@email.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email harus diisi';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildPasswordField(),
                const SizedBox(height: 14),
                _buildInputField(
                  label: 'Nomor Telepon',
                  controller: _phoneController,
                  hint: '08xxxxxxxxxxx',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor telepon harus diisi';
                    }
                    if (value.trim().length < 9) {
                      return 'Nomor telepon tidak valid';
                    }
                    if (value.trim().length > 20) {
                      return 'Nomor telepon maksimal 20 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildGenderField(),
                const SizedBox(height: 14),
                _buildDateField(),
                const SizedBox(height: 22),
                _buildRegisterButton(),
                const SizedBox(height: 18),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.74),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.92),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: ClipOval(
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.asset(
                'assets/images/logo_pdam.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.water_drop_rounded,
                  color: _teal,
                  size: 38,
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
            color: _navy,
            letterSpacing: -0.6,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          'Recruitment Karyawan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _muted,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _teal.withValues(alpha: 0.92),
          letterSpacing: -0.15,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _hint,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 18, right: 10),
        child: Icon(prefixIcon, color: _hint, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 22),
      suffixIcon: suffixIcon,
      isDense: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      errorStyle: const TextStyle(
        color: Color(0xFFDC2626),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFieldShell({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: _glassWhite70,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder80, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        _buildFieldShell(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
            cursorColor: _accentGreen,
            decoration: _buildInputDecoration(
              hint: hint,
              prefixIcon: prefixIcon,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Password'),
        _buildFieldShell(
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
            cursorColor: _accentGreen,
            decoration: _buildInputDecoration(
              hint: 'Masukkan password (min. 8 karakter)',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                splashRadius: 20,
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _hint,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password harus diisi';
              }
              if (value.length < 8) {
                return 'Password minimal 8 karakter';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Jenis Kelamin'),
        _buildFieldShell(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _hint,
                size: 24,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
            decoration: _buildInputDecoration(
              hint: 'Pilih jenis kelamin',
              prefixIcon: Icons.wc_outlined,
            ),
            hint: const Text(
              'Pilih jenis kelamin',
              style: TextStyle(
                color: _hint,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Backend expects literal "Laki-laki" / "Perempuan"
            items: const [
              DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jenis kelamin harus dipilih';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tanggal Lahir'),
        _buildFieldShell(
          child: TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _pickDate,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _navy,
            ),
            cursorColor: _accentGreen,
            decoration: _buildInputDecoration(
              hint: 'DD/MM/YYYY',
              prefixIcon: Icons.calendar_today_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Tanggal lahir harus diisi';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _pickedDob ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _teal,
              onPrimary: Colors.white,
              onSurface: _navy,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _teal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      final yyyy = picked.year.toString();
      setState(() {
        _pickedDob = picked;
        _dobController.text = '$dd/$mm/$yyyy';
      });
    }
  }

  Widget _buildRegisterButton() {
    final bool disabled = _isLoading;
    const borderRadius = BorderRadius.all(Radius.circular(999));

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AnimatedOpacity(
        opacity: disabled ? 0.8 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 54,
          decoration: const BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Color(0x80FB7185),
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
                  colors: [_buttonStart, _buttonEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: borderRadius,
              ),
              child: InkWell(
                onTap: disabled ? null : _handleRegister,
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
                          'Daftar',
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

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: _muted,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            children: [
              TextSpan(text: 'Sudah punya akun? '),
              TextSpan(
                text: 'Masuk Sekarang',
                style: TextStyle(
                  color: _accentGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    color: _glassWhite30,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _glassBorder50, width: 1.5),
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
                        color: _teal,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Test Koneksi API',
                        style: TextStyle(
                          color: _teal,
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
          '© 2024 PDAM Surya Sembada. Semua hak dilindungi.',
          style: TextStyle(
            color: Color(0x660B4F4A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

      final response = await dio.get('${AppConfig.backendDomain}/api/ping');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koneksi berhasil!\nStatus: ${response.statusCode}'),
          backgroundColor: _accentGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } on DioException catch (e) {
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
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFFB7185),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedDob == null) return;

    setState(() {
      _isLoading = true;
    });

    final authDataSource = AuthRemoteDataSource();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Format date to ISO YYYY-MM-DD (backend expects `date` rule).
    final yyyy = _pickedDob!.year.toString().padLeft(4, '0');
    final mm = _pickedDob!.month.toString().padLeft(2, '0');
    final dd = _pickedDob!.day.toString().padLeft(2, '0');
    final tanggalLahir = '$yyyy-$mm-$dd';

    try {
      final registerResult = await authDataSource.register(
        name: _nameController.text.trim(),
        email: email,
        password: password,
        telepon: _phoneController.text.trim(),
        jenisKelamin: _selectedGender!,
        tanggalLahir: tanggalLahir,
      );

      if (!mounted) return;

      if (registerResult is DataFailed) {
        setState(() => _isLoading = false);
        await _showErrorDialog(
          title: 'Pendaftaran Gagal',
          message: _resolveRegisterErrorMessage(registerResult.error),
        );
        return;
      }

      final loginResult = await authDataSource.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (loginResult is DataFailed) {
        setState(() => _isLoading = false);

        await _showPendingApprovalDialog();
        if (!mounted) return;
        Navigator.of(context).pop(); // back to login page
        return;
      }

      final authResponse = (loginResult as DataSuccess).data!;

      if (authResponse.token != null) {
        await AuthStorage.saveToken(authResponse.token!);
      }

      final meResult = await authDataSource.fetchMe();

      if (!mounted) return;

      int? roleId = authResponse.user?['role_id'];
      int? positionId;

      if (meResult is DataSuccess<Map<String, dynamic>>) {
        final userData = meResult.data!;
        roleId = userData['role_id'] as int? ?? roleId;
        positionId = userData['employee']?['position_id'] as int?;
        await AuthStorage.saveUser(userData);
      } else if (authResponse.user != null) {
        await AuthStorage.saveUser(authResponse.user!);
      }

      debugPrint('🎭 After-register Role ID: $roleId');
      debugPrint('👔 After-register Position ID: $positionId');

      // Jika pegawai belum di-ACC (position_id masih null) → jangan auto-masuk.
      if (positionId == null) {
        // Clear token supaya user harus re-login setelah di-ACC.
        await AuthStorage.clearAuth();

        setState(() => _isLoading = false);
        await _showPendingApprovalDialog();
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      // -------- Sudah di-ACC Super Admin → auto-login --------
      setState(() => _isLoading = false);
      await _showSuccessDialog();
      if (!mounted) return;

      final targetPage = _resolveLandingPage(roleId: roleId);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetPage),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showErrorDialog(title: 'Terjadi Kesalahan', message: e.toString());
    }
  }

  Widget _resolveLandingPage({required int? roleId}) {
    if (roleId == 1) {
      return const admin.LandingPage();
    } else if (roleId == 2) {
      return const ManajerLandingPage();
    } else if (roleId == 3) {
      if (AuthStorage.getJabatanKodeSync() == 'SPV') {
        return const SpvLandingPage();
      }
      return const StaffLandingPage();
    }
    return const admin.LandingPage();
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.check_circle,
          color: Color(0xFF4CAF50),
          size: 56,
        ),
        title: const Text(
          'Pendaftaran Berhasil',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: _navy),
        ),
        content: const Text(
          'Akun Anda sudah disetujui Super Admin.\nAnda akan langsung diarahkan ke halaman utama.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPendingApprovalDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.hourglass_top_rounded,
          color: Color(0xFFFFA726),
          size: 56,
        ),
        title: const Text(
          'Menunggu Persetujuan',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: _navy),
        ),
        content: const Text(
          'Pendaftaran Anda berhasil dikirim.\n\n'
          'Akun akan aktif setelah disetujui oleh Super Admin. '
          'Silakan login kembali setelah mendapat konfirmasi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK, Kembali ke Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.error_outline, color: _buttonEnd, size: 56),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _navy),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              backgroundColor: _buttonEnd,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _resolveRegisterErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final buffer = StringBuffer();
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              buffer.writeln('• ${value.first}');
            }
          });
          final msg = buffer.toString().trim();
          if (msg.isNotEmpty) return msg;
        }
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi timeout, periksa koneksi internet Anda.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server.';
      }
      return error.message ?? 'Pendaftaran gagal. Silakan coba lagi.';
    }
    return 'Pendaftaran gagal. Silakan coba lagi.';
  }
}
