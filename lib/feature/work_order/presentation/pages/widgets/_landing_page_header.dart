part of '../landing_page.dart';

class _LandingPageHeader extends StatelessWidget {
  const _LandingPageHeader();



  String _getEmployeeName() {
    final user = AuthStorage.getUserSync();
    return user?['employee']?['name'] ?? 'Unknown User';
  }

  String _getEmployeeId() {
    final user = AuthStorage.getUserSync();
    return user?['employee']?['employee_id'] ?? '';
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
              color: Theme.of(dialogContext).extension<AppColor>()!.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await AuthStorage.clearAuth();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffff574d),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>()!;
    final textTheme = Theme.of(context).textTheme;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24 + statusBarHeight, 24, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary[500]!, colors.primary[700]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PDAM Surya Sembada',
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.background[100],
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getEmployeeName(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.background[100]!.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_getEmployeeId().isNotEmpty)
                      Text(
                        _getEmployeeId(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.background[100]!.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Logout Button - matching Figma design
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xffff574d),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleLogout(context),
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 3.5,
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.background[100]!.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: colors.primary[300],
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: colors.background[100],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xffff574d),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primary[500]!,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
