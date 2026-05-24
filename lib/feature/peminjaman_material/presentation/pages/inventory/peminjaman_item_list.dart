import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/pengajuan_item.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';

class PeminjamanItemListPage extends StatelessWidget {
  const PeminjamanItemListPage({super.key});

  bool get _isStaff {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'] as int?;
    return roleId == 3 && AuthStorage.getJabatanKodeSync() != 'SPV';
  }

  bool get _isSpv {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'] as int?;
    return roleId == 3 && AuthStorage.getJabatanKodeSync() == 'SPV';
  }

  void _navigateToRoleDashboard(BuildContext context) {
    final targetPage = _isSpv
        ? const SpvLandingPage()
        : const StaffLandingPage();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetPage),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = _isStaff;
    final colors = Theme.of(context).extension<AppColor>()!;
    final items = <BorrowItemData>[
      const BorrowItemData(
        brand: 'APPLE',
        name: 'MacBook Pro 16"',
        description:
            'M2 Max chip, 32GB RAM, 1TB SSD. Perfect for heavy video editing.',
        availableCount: 4,
        imageUrl:
            'https://www.figma.com/api/mcp/asset/98963021-41f9-494e-b719-9fe028b772da',
      ),
      const BorrowItemData(
        brand: 'SONY',
        name: 'Sony Alpha A7 III',
        description:
            '24.2-megapixel full-frame CMOS sensor. Includes 28-70mm lens kit.',
        availableCount: 2,
        imageUrl:
            'https://www.figma.com/api/mcp/asset/ab9c5259-26cd-4f7d-81b4-b66b169e5ae9',
      ),
      const BorrowItemData(
        brand: 'APPLE',
        name: 'iPad Pro 12.9"',
        description:
            'M2 chip, Liquid Retina XDR display. Apple Pencil 2 included.',
        availableCount: 6,
        imageUrl:
            'https://www.figma.com/api/mcp/asset/2de7bd5e-34b5-4145-b78a-e66795e2d307',
      ),
      const BorrowItemData(
        brand: 'EPSON',
        name: 'Epson Pro EX9220',
        description:
            '1080p+ WUXGA, 3,600 lumens color/white brightness. Wireless.',
        availableCount: 1,
        imageUrl:
            'https://www.figma.com/api/mcp/asset/270f7bbf-1ee1-4a1f-9f53-1c6855cb3641',
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              _InventoryHeader(
                onBackToDashboard: () => _navigateToRoleDashboard(context),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _InventoryCard(
                      item: items[index],
                      isStaff: isStaff,
                      onRequestBorrow: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PengajuanItemPage(item: items[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (!isStaff)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  color: Colors.white,
                  child: Text(
                    'Mode SPV: hanya melihat stok item.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.foreground[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  final VoidCallback onBackToDashboard;

  const _InventoryHeader({required this.onBackToDashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF6A7282),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'PDAM Surabaya Office',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6A7282),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onBackToDashboard,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 18,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Inventory',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Color(0xFF99A1AF)),
                      const SizedBox(width: 8),
                      Text(
                        'Search equipment...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF99A1AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF101828),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _ChipTab(label: 'All', isActive: true),
                SizedBox(width: 8),
                _ChipTab(label: 'Laptops'),
                SizedBox(width: 8),
                _ChipTab(label: 'Cameras'),
                SizedBox(width: 8),
                _ChipTab(label: 'Tablets'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFD1D5DC)),
        ],
      ),
    );
  }
}

class _ChipTab extends StatelessWidget {
  final String label;
  final bool isActive;

  const _ChipTab({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF155DFC) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? Colors.transparent : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isActive ? Colors.white : const Color(0xFF4A5565),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final BorrowItemData item;
  final bool isStaff;
  final VoidCallback onRequestBorrow;

  const _InventoryCard({
    required this.item,
    required this.isStaff,
    required this.onRequestBorrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      item.imageUrl,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 112,
                        height: 112,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          item.brand,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF364153),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6A7282),
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFF00C950),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.availableCount} available',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF4A5565),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isStaff) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _AnimatedRequestButton(onPressed: onRequestBorrow),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedRequestButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedRequestButton({required this.onPressed});

  @override
  State<_AnimatedRequestButton> createState() => _AnimatedRequestButtonState();
}

class _AnimatedRequestButtonState extends State<_AnimatedRequestButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _isPressed
                ? const Color(0xFFD9E9FF)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isPressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x1A155DFC),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Request to Borrow',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1447E6),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
