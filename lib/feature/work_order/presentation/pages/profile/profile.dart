import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/auth/presentation/login.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/personal_data.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';

class ProfilePage extends StatelessWidget {
  final ProfileViewData? _data;

  const ProfilePage({super.key, required ProfileViewData data}) : _data = data;

  factory ProfilePage.safe({
    Key? key,
    ProfileViewData? data,
  }) {
    return ProfilePage(
      key: key,
      data: data ?? ProfileViewDataResolver.defaultProfileData,
    );
  }

  static const Color _purple = Color(0xff243a7c);
  static const Color _bgGray = Color(0xFFF4F6F9);
  static const Color _cardGray = Color(0xFFEDEFF4);
  static const Color _danger = Color(0xFFFF4D4F);

  ProfileViewData get data =>
      _data ?? ProfileViewDataResolver.defaultProfileData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _ProfileTopSection(
                fullName: data.fullName,
                roleName: data.roleName,
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'CONTACT',
                      children: [
                        _SectionRowItem(
                          icon: Icons.email,
                          text: data.email,
                          iconColor: _purple,
                          chevron: false,
                        ),
                        _SectionRowItem(
                          icon: Icons.location_on_rounded,
                          text: data.address,
                          iconColor: _purple,
                          chevron: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'ACCOUNT',
                      children: [
                        _SectionRowItem(
                          icon: Icons.person,
                          text: 'Personal Data',
                          iconColor: _purple,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PersonalDataPage.safe(data: data.personalData),
                            ),
                          ),
                        ),
                        _SectionRowItem(
                          icon: Icons.folder,
                          text: 'Office Assets',
                          iconColor: _purple,
                          onTap: () => _showComingSoon(
                            context,
                            'Office Assets belum tersedia.',
                          ),
                        ),
                        _SectionRowItem(
                          icon: Icons.account_balance_wallet,
                          text: 'Payroll & Tax',
                          iconColor: _purple,
                          onTap: () => _showComingSoon(
                            context,
                            'Payroll & Tax belum tersedia.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'SETTINGS',
                      children: [
                        _SectionRowItem(
                          icon: Icons.settings,
                          text: 'Change Password',
                          iconColor: _purple,
                          onTap: () => _showComingSoon(
                            context,
                            'Change Password belum tersedia.',
                          ),
                        ),
                        _SectionRowItem(
                          icon: Icons.developer_mode,
                          text: 'Versioning',
                          iconColor: _purple,
                          onTap: () => _showComingSoon(
                            context,
                            'Versioning belum tersedia.',
                          ),
                        ),
                        _SectionRowItem(
                          icon: Icons.message,
                          text: 'FAQ and Help',
                          iconColor: _purple,
                          onTap: () => _showComingSoon(
                            context,
                            'FAQ and Help belum tersedia.',
                          ),
                        ),
                        _SectionRowItem(
                          icon: Icons.logout,
                          text: 'Logout',
                          iconColor: _danger,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Clear the session from local storage
    await AuthStorage.clearAuth();
    debugPrint('🚪 User logged out, session cleared');

    // Navigate to LoginPage and clear the entire navigation stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleLogout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: _danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopSection extends StatelessWidget {
  final String fullName;
  final String roleName;
  final VoidCallback onBackTap;

  const _ProfileTopSection({
    required this.fullName,
    required this.roleName,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: ProfilePage._purple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  _CircleHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBackTap,
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
          ),
          Positioned(
            top: 178,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6C2EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: ProfilePage._purple,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  roleName,
                  style: const TextStyle(
                    color: ProfilePage._purple,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ProfilePage._cardGray,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SectionRowItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final bool chevron;
  final VoidCallback? onTap;

  const _SectionRowItem({
    required this.icon,
    required this.text,
    required this.iconColor,
    this.chevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4F5464),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (chevron)
            const Icon(
              Icons.chevron_right_rounded,
              size: 21,
              color: Color(0xFFB8C1D1),
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: ProfilePage._purple),
        ),
      ),
    );
  }
}
