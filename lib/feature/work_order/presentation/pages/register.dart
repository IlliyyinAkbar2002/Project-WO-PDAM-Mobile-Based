import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/auth_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/landing_page.dart'
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
  static const Color _navy = Color(0xFF1A3C5E);
  static const Color _teal = Color(0xFF0097A7);
  static const Color _inputFill = Color(0xFFF5F9FC);
  static const Color _inputBorder = Color(0xFFDDDDDD);
  static const Color _orange = Color(0xFFFF6B2B);
  static const Color _orangeDark = Color(0xFFF44336);
  static const Color _hint = Color(0xFF9AA6B2);
  static const Color _muted = Color(0xFF7A8894);

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildRegisterCard(),
                    const SizedBox(height: 16),
                    _buildFooter(),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _teal,
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PDAM Surya Sembada',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recruitment Karyawan',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(
              label: 'Nama Lengkap',
              controller: _nameController,
              hint: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama lengkap harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Email',
              controller: _emailController,
              hint: 'contoh@email.com',
              prefixIcon: Icons.mail_outline,
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
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Nomor Telepon',
              controller: _phoneController,
              hint: '08xxxxxxxxxx',
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
            const SizedBox(height: 16),
            _buildGenderField(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
            const SizedBox(height: 16),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _navy,
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
      hintStyle: const TextStyle(color: _hint, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: _teal, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: _buildInputDecoration(
            hint: hint,
            prefixIcon: prefixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Password'),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: _buildInputDecoration(
            hint: 'Masukkan password (min. 8 karakter)',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              splashRadius: 20,
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _teal,
                size: 20,
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
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Jenis Kelamin'),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _teal,
            size: 22,
          ),
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: _buildInputDecoration(
            hint: 'Pilih jenis kelamin',
            prefixIcon: Icons.wc_outlined,
          ),
          hint: const Text(
            'Pilih jenis kelamin',
            style: TextStyle(color: _hint, fontSize: 13),
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
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tanggal Lahir'),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDate,
          style: const TextStyle(fontSize: 14, color: _navy),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_orange, _orangeDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _orange.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isLoading ? null : _handleRegister,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Daftar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
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
            style: TextStyle(fontSize: 13, color: _muted),
            children: [
              TextSpan(text: 'Sudah punya akun? '),
              TextSpan(
                text: 'Masuk Sekarang',
                style: TextStyle(
                  color: _teal,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        '© 2024 PDAM Surya Sembada. Semua hak dilindungi.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Submit handler
  // ---------------------------------------------------------------------------

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

      // -------- Register sukses, coba auto-login --------
      final loginResult = await authDataSource.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (loginResult is DataFailed) {
        setState(() => _isLoading = false);
        // Login gagal walau register sukses → kemungkinan backend block
        // pending users. Tampilkan dialog info, minta user login manual nanti.
        await _showPendingApprovalDialog();
        if (!mounted) return;
        Navigator.of(context).pop(); // back to login page
        return;
      }

      final authResponse = (loginResult as DataSuccess).data!;

      // Simpan token sementara agar bisa fetch /me
      if (authResponse.token != null) {
        await AuthStorage.saveToken(authResponse.token!);
      }

      // Ambil full profile untuk cek apakah sudah di-ACC Super Admin
      // (position_id != null berarti Super Admin sudah meng-assign jabatan).
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

      print('🎭 After-register Role ID: $roleId');
      print('👔 After-register Position ID: $positionId');

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

      final targetPage = _resolveLandingPage(roleId: roleId, positionId: positionId);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetPage),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showErrorDialog(
        title: 'Terjadi Kesalahan',
        message: e.toString(),
      );
    }
  }

  Widget _resolveLandingPage({required int? roleId, required int? positionId}) {
    if (roleId == 1) {
      return const admin.LandingPage();
    } else if (roleId == 2) {
      return const ManajerLandingPage();
    } else if (roleId == 3) {
      if (positionId == 4) {
        return const SpvLandingPage();
      }
      return const StaffLandingPage();
    }
    return const admin.LandingPage();
  }

  // ---------------------------------------------------------------------------
  // Alert dialogs
  // ---------------------------------------------------------------------------

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56),
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
        icon: const Icon(Icons.error_outline, color: _orangeDark, size: 56),
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
              backgroundColor: _orangeDark,
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

  // ---------------------------------------------------------------------------
  // Error-message resolver (maps Laravel 422 payload into readable text)
  // ---------------------------------------------------------------------------

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
