import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/core/resource/api_exception.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/auth/data/remote/auth_remote_data_source.dart';

/// Design tokens shared by the forgot-password flow. Mirrors the glassmorphism
/// look of [LoginPage] / [RegisterPage] so the screens feel like one family.
class _AuthTokens {
  static const Color bgGradientStart = Color(0xFFCEFAFE);
  static const Color bgGradientMid = Color(0xFFF0FDFA);
  static const Color bgGradientEnd = Color(0xFFDCFCE7);

  static const Color blobCyan = Color(0x80A2F4FD);
  static const Color blobGreen = Color(0x80B9F8CF);
  static const Color blobTeal = Color(0x8096F7E4);

  static const Color textPrimary = Color(0xFF022F2E);
  static const Color textSecondary = Color(0xFF6A7282);
  static const Color hintColor = Color(0xFF99A1AF);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color footerTeal = Color(0xFF0B4F4A);

  static const Color buttonStart = Color(0xFFFB923C);
  static const Color buttonEnd = Color(0xFFFB7185);

  static const Color glassWhite70 = Color(0xB3FFFFFF);
  static const Color glassWhite50 = Color(0x80FFFFFF);
  static const Color glassBorder80 = Color(0xCCFFFFFF);
  static const Color glassBorder70 = Color(0xB3FFFFFF);
}

// ===========================================================================
// Screen 1 — enter email
// ===========================================================================

/// Screen 1 of the forgot-password flow: the user enters their email so the
/// backend can confirm it is registered before letting them set a new password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    try {
      final result = await AuthRemoteDataSource().forgotPassword(email: email);

      if (!mounted) return;

      if (result is DataSuccess<String>) {
        // Email terdaftar → tampilkan alert lalu lanjut ke screen set password.
        await _AuthDialogs.showSuccess(
          context,
          title: 'Email Terdaftar',
          message: 'Email Anda terdaftar. Silakan atur password baru.',
          buttonLabel: 'Atur Password',
        );

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(email: result.data!),
          ),
        );
      } else if (result is DataFailed<String>) {
        final apiException = _extractApiException(result.error);

        if (apiException != null && apiException.isForbidden) {
          // 403 → email terdaftar tapi akunnya non-aktif.
          await _AuthDialogs.showError(
            context,
            title: 'Akun Tidak Aktif',
            message: _resolveErrorMessage(
              result.error,
              fallback: 'Akun Anda tidak aktif. Silakan hubungi admin.',
            ),
          );
        } else {
          await _AuthDialogs.showError(
            context,
            title: 'Email Tidak Ditemukan',
            message: _resolveErrorMessage(
              result.error,
              fallback: 'Email tidak terdaftar.',
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      isLoading: _isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AuthHeader(
              icon: Icons.lock_reset_rounded,
              title: 'Lupa Password?',
              subtitle:
                  'Masukkan email Anda yang terdaftar untuk mengatur ulang password.',
            ),
            const SizedBox(height: 28),
            _GlassTextField(
              controller: _emailController,
              hintText: 'Masukkan email',
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
            const SizedBox(height: 20),
            _GradientButton(
              label: 'Lanjutkan',
              isLoading: _isLoading,
              onTap: _handleSubmit,
            ),
            const SizedBox(height: 20),
            _BackToLoginLink(
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Screen 2 — set new password
// ===========================================================================

/// Screen 2 of the forgot-password flow: with the email already verified in
/// screen 1, the user sets a new password and is sent back to login.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthRemoteDataSource().resetPassword(
        email: widget.email,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result is DataSuccess<String>) {
        await _AuthDialogs.showSuccess(
          context,
          title: 'Password Berhasil Diatur',
          message:
              'Password berhasil diatur ulang. Silakan login dengan password baru Anda.',
          buttonLabel: 'Kembali ke Login',
        );

        if (!mounted) return;
        // Buang seluruh stack auth, kembali ke halaman login pertama.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (result is DataFailed<String>) {
        await _AuthDialogs.showError(
          context,
          title: 'Gagal Mengatur Password',
          message: _resolveErrorMessage(
            result.error,
            fallback: 'Gagal mengatur ulang password. Silakan coba lagi.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      isLoading: _isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _AuthHeader(
              icon: Icons.password_rounded,
              title: 'Atur Password Baru',
              subtitle: 'Buat password baru untuk ${widget.email}.',
            ),
            const SizedBox(height: 28),
            _GlassTextField(
              controller: _passwordController,
              hintText: 'Password baru (min. 8 karakter)',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_isPasswordVisible,
              suffixIcon: _VisibilityToggle(
                isVisible: _isPasswordVisible,
                onPressed: () => setState(
                  () => _isPasswordVisible = !_isPasswordVisible,
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
            const SizedBox(height: 16),
            _GlassTextField(
              controller: _confirmController,
              hintText: 'Konfirmasi password baru',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_isConfirmVisible,
              suffixIcon: _VisibilityToggle(
                isVisible: _isConfirmVisible,
                onPressed: () => setState(
                  () => _isConfirmVisible = !_isConfirmVisible,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password harus diisi';
                }
                if (value != _passwordController.text) {
                  return 'Konfirmasi password tidak sama';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _GradientButton(
              label: 'Simpan Password',
              isLoading: _isLoading,
              onTap: _handleSubmit,
            ),
            const SizedBox(height: 20),
            _BackToLoginLink(
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Shared helpers / widgets
// ===========================================================================

/// Unwrap the [ApiException] the [ApiErrorInterceptor] attaches to a
/// [DioException.error], if present. Lets callers branch on `statusCode`
/// (e.g. [ApiException.isForbidden] vs [ApiException.isNotFound]) instead of
/// pattern-matching on the error message text.
ApiException? _extractApiException(dynamic error) {
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return null;
}

/// Extract a user-friendly message from the [DataFailed] error. The
/// [ApiErrorInterceptor] wraps backend errors into an [ApiException] whose
/// `message` already holds the Laravel `message` field (e.g. "Email tidak
/// terdaftar"); fall back to network-specific hints otherwise.
String _resolveErrorMessage(dynamic error, {required String fallback}) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException && inner.message.isNotEmpty) {
      return inner.allErrorsJoined();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Koneksi timeout, periksa koneksi internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server.';
      default:
        return error.message ?? fallback;
    }
  }
  return fallback;
}

/// Gradient background + decorative blobs + glass card scaffold shared by both
/// screens of the flow.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child, required this.isLoading});

  final Widget child;
  final bool isLoading;

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
          const _GradientBackground(),
          const _DecorativeBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      64,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_GlassCard(child: child)],
                ),
              ),
            ),
          ),
          if (isLoading)
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
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -0.45),
            end: Alignment(0.9, 0.45),
            colors: [
              _AuthTokens.bgGradientStart,
              _AuthTokens.bgGradientMid,
              _AuthTokens.bgGradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _DecorativeBlobs extends StatelessWidget {
  const _DecorativeBlobs();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -90,
              left: -40,
              child: _Blob(size: 320, color: _AuthTokens.blobCyan),
            ),
            Positioned(
              top: 160,
              left: 20,
              child: _Blob(size: 260, color: _AuthTokens.blobGreen),
            ),
            Positioned(
              top: 260,
              right: -80,
              child: _Blob(size: 380, color: _AuthTokens.blobTeal),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: _AuthTokens.glassWhite50,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: _AuthTokens.glassBorder70, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1F2687),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
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
          child: Icon(icon, color: _AuthTokens.footerTeal, size: 38),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _AuthTokens.textPrimary,
            letterSpacing: -0.6,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _AuthTokens.textSecondary,
            height: 1.43,
          ),
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.isVisible, required this.onPressed});

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 20,
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: _AuthTokens.hintColor,
        size: 22,
      ),
      onPressed: onPressed,
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(999));

    return AnimatedOpacity(
      opacity: isLoading ? 0.8 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        height: 54.46,
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
                colors: [_AuthTokens.buttonStart, _AuthTokens.buttonEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: borderRadius,
            ),
            child: InkWell(
              onTap: isLoading ? null : onTap,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
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
    );
  }
}

class _BackToLoginLink extends StatelessWidget {
  const _BackToLoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                color: _AuthTokens.accentGreen,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Kembali ke Login',
                style: TextStyle(
                  color: _AuthTokens.accentGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism text field matching the login screen spec.
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
            color: _AuthTokens.glassWhite70,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AuthTokens.glassBorder80, width: 1.5),
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
              color: _AuthTokens.textPrimary,
            ),
            cursorColor: _AuthTokens.accentGreen,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: _AuthTokens.hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 18, right: 10),
                child: Icon(
                  prefixIcon,
                  color: _AuthTokens.hintColor,
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

/// Success / error alert dialogs shared across the flow.
class _AuthDialogs {
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    required String buttonLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _AuthTokens.textPrimary,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _AuthTokens.textSecondary, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              backgroundColor: _AuthTokens.footerTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.error_outline,
          color: _AuthTokens.buttonEnd,
          size: 56,
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _AuthTokens.textPrimary,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _AuthTokens.textSecondary, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              backgroundColor: _AuthTokens.buttonEnd,
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
}
