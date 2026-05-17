import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/manajer/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';

/// Status of a borrow approval request.
enum ApprovalStatus { pending, approved, rejected }

/// Visual badge shown on the right of a request card.
enum RequestBadge { none, newRequest, urgent }

class ApprovalRequestData {
  final String id;
  final String staffName;
  final String staffRole;
  final String assetName;
  final String assetImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String justification;
  final ApprovalStatus status;
  final RequestBadge badge;
  final DateTime requestedAt;

  const ApprovalRequestData({
    required this.id,
    required this.staffName,
    required this.staffRole,
    required this.assetName,
    required this.assetImageUrl,
    required this.startDate,
    required this.endDate,
    required this.justification,
    required this.status,
    required this.badge,
    required this.requestedAt,
  });

  ApprovalRequestData copyWith({ApprovalStatus? status, RequestBadge? badge}) {
    return ApprovalRequestData(
      id: id,
      staffName: staffName,
      staffRole: staffRole,
      assetName: assetName,
      assetImageUrl: assetImageUrl,
      startDate: startDate,
      endDate: endDate,
      justification: justification,
      status: status ?? this.status,
      badge: badge ?? this.badge,
      requestedAt: requestedAt,
    );
  }
}

class PersetujuanPeminjamanBarangPage extends StatefulWidget {
  const PersetujuanPeminjamanBarangPage({super.key});

  @override
  State<PersetujuanPeminjamanBarangPage> createState() =>
      _PersetujuanPeminjamanBarangPageState();
}

class _PersetujuanPeminjamanBarangPageState
    extends State<PersetujuanPeminjamanBarangPage> {
  final TextEditingController _searchController = TextEditingController();
  ApprovalStatus _activeTab = ApprovalStatus.pending;
  String _query = '';

  late final List<ApprovalRequestData> _requests = _seedRequests();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final value = _searchController.text.trim().toLowerCase();
      if (value == _query) return;
      setState(() => _query = value);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToRoleDashboard() {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'] as int?;
    final positionId = user?['employee']?['position_id'] as int?;

    Widget target;
    if (roleId == 2) {
      target = const ManajerLandingPage();
    } else if (roleId == 3 && positionId == 4) {
      target = const SpvLandingPage();
    } else {
      target = const StaffLandingPage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  List<ApprovalRequestData> get _filteredRequests {
    return _requests.where((r) {
      if (r.status != _activeTab) return false;
      if (_query.isEmpty) return true;
      return r.staffName.toLowerCase().contains(_query) ||
          r.assetName.toLowerCase().contains(_query);
    }).toList();
  }

  int get _pendingCount =>
      _requests.where((r) => r.status == ApprovalStatus.pending).length;

  Future<void> _openDetail(ApprovalRequestData request) async {
    final result = await showModalBottomSheet<ApprovalStatus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _ApprovalDetailSheet(request: request),
    );

    if (result == null) return;
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index == -1) return;
      _requests[index] =
          _requests[index].copyWith(status: result, badge: RequestBadge.none);
    });

    if (!mounted) return;
    final isApproved = result == ApprovalStatus.approved;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor:
            isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isApproved
                    ? 'Permintaan ${request.staffName} disetujui'
                    : 'Permintaan ${request.staffName} ditolak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

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
              _ApprovalHeader(
                searchController: _searchController,
                pendingCount: _pendingCount,
                activeTab: _activeTab,
                onTabChanged: (tab) => setState(() => _activeTab = tab),
                onBackToDashboard: _navigateToRoleDashboard,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(activeTab: _activeTab)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _ApprovalCard(
                            request: filtered[index],
                            onTap: () => _openDetail(filtered[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ApprovalRequestData> _seedRequests() {
    final today = DateTime.now();
    return [
      ApprovalRequestData(
        id: 'REQ-001',
        staffName: 'Andi Prasetyo',
        staffRole: 'Field Technician',
        assetName: 'MacBook Pro 16"',
        assetImageUrl:
            'https://www.figma.com/api/mcp/asset/98963021-41f9-494e-b719-9fe028b772da',
        startDate: today,
        endDate: today.add(const Duration(days: 2)),
        justification:
            'Edit dokumentasi proyek lapangan area Surabaya Barat selama dua hari.',
        status: ApprovalStatus.pending,
        badge: RequestBadge.urgent,
        requestedAt: today.subtract(const Duration(hours: 2)),
      ),
      ApprovalRequestData(
        id: 'REQ-002',
        staffName: 'Illiyyin Putri',
        staffRole: 'IT Staff',
        assetName: 'Sony Alpha A7 III',
        assetImageUrl:
            'https://www.figma.com/api/mcp/asset/ab9c5259-26cd-4f7d-81b4-b66b169e5ae9',
        startDate: today.add(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 3)),
        justification:
            'Dokumentasi perawatan instalasi pipa di area pelanggan VIP.',
        status: ApprovalStatus.pending,
        badge: RequestBadge.newRequest,
        requestedAt: today.subtract(const Duration(hours: 4)),
      ),
      ApprovalRequestData(
        id: 'REQ-003',
        staffName: 'Bagas Saputra',
        staffRole: 'Field Surveyor',
        assetName: 'iPad Pro 12.9"',
        assetImageUrl:
            'https://www.figma.com/api/mcp/asset/2de7bd5e-34b5-4145-b78a-e66795e2d307',
        startDate: today.add(const Duration(days: 2)),
        endDate: today.add(const Duration(days: 5)),
        justification: 'Survey lapangan dan input data pelanggan baru.',
        status: ApprovalStatus.pending,
        badge: RequestBadge.newRequest,
        requestedAt: today.subtract(const Duration(hours: 8)),
      ),
      ApprovalRequestData(
        id: 'REQ-004',
        staffName: 'Sari Wulandari',
        staffRole: 'IT Staff',
        assetName: 'Epson Pro EX9220',
        assetImageUrl:
            'https://www.figma.com/api/mcp/asset/270f7bbf-1ee1-4a1f-9f53-1c6855cb3641',
        startDate: today.add(const Duration(days: 3)),
        endDate: today.add(const Duration(days: 4)),
        justification: 'Presentasi rapat koordinasi mingguan dengan vendor.',
        status: ApprovalStatus.pending,
        badge: RequestBadge.none,
        requestedAt: today.subtract(const Duration(days: 1)),
      ),
      ApprovalRequestData(
        id: 'REQ-005',
        staffName: 'Dimas Aditya',
        staffRole: 'Field Technician',
        assetName: 'MacBook Pro 16"',
        assetImageUrl:
            'https://www.figma.com/api/mcp/asset/98963021-41f9-494e-b719-9fe028b772da',
        startDate: today.subtract(const Duration(days: 4)),
        endDate: today.subtract(const Duration(days: 2)),
        justification: 'Editing video laporan instalasi pipa.',
        status: ApprovalStatus.approved,
        badge: RequestBadge.none,
        requestedAt: today.subtract(const Duration(days: 5)),
      ),
      ApprovalRequestData(
        id: 'REQ-006',
        staffName: 'Rina Hartono',
        staffRole: 'IT Staff',
        assetName: 'Sony Alpha A7 III',
        assetImageUrl:
            'https://www.figma.com/api/mcp/asset/ab9c5259-26cd-4f7d-81b4-b66b169e5ae9',
        startDate: today.subtract(const Duration(days: 2)),
        endDate: today.subtract(const Duration(days: 1)),
        justification: 'Dokumentasi event internal PDAM.',
        status: ApprovalStatus.rejected,
        badge: RequestBadge.none,
        requestedAt: today.subtract(const Duration(days: 3)),
      ),
    ];
  }
}


class _ApprovalHeader extends StatelessWidget {
  final TextEditingController searchController;
  final int pendingCount;
  final ApprovalStatus activeTab;
  final ValueChanged<ApprovalStatus> onTabChanged;
  final VoidCallback onBackToDashboard;

  const _ApprovalHeader({
    required this.searchController,
    required this.pendingCount,
    required this.activeTab,
    required this.onTabChanged,
    required this.onBackToDashboard,
  });

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
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF6A7282)),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Approval Center',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 14, color: Color(0xFF155DFC)),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF155DFC),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tinjau permintaan peminjaman barang dari staff.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6A7282),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 14),
          Container(
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
                Expanded(
                  child: TextField(
                    controller: searchController,
                    cursorColor: const Color(0xFF155DFC),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w500,
                        ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Cari staff atau nama aset...',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF99A1AF),
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF99A1AF)),
                    onPressed: () => searchController.clear(),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SegmentedTabs(
            activeTab: activeTab,
            pendingCount: pendingCount,
            onChanged: onTabChanged,
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final ApprovalStatus activeTab;
  final int pendingCount;
  final ValueChanged<ApprovalStatus> onChanged;

  const _SegmentedTabs({
    required this.activeTab,
    required this.pendingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TabSegment(
              label: 'Pending',
              isActive: activeTab == ApprovalStatus.pending,
              badgeCount: pendingCount > 0 ? pendingCount : null,
              onTap: () => onChanged(ApprovalStatus.pending),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'Approved',
              isActive: activeTab == ApprovalStatus.approved,
              onTap: () => onChanged(ApprovalStatus.approved),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'Rejected',
              isActive: activeTab == ApprovalStatus.rejected,
              onTap: () => onChanged(ApprovalStatus.rejected),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? const Color(0xFF101828)
                        : const Color(0xFF6A7282),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                constraints:
                    const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF155DFC)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF1447E6),
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatefulWidget {
  final ApprovalRequestData request;
  final VoidCallback onTap;

  const _ApprovalCard({required this.request, required this.onTap});

  @override
  State<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<_ApprovalCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F1F1)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      r.assetImageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.devices_other_rounded,
                          color: Color(0xFF99A1AF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.staffName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF101828),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(badge: r.badge, status: r.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.assetName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF4A5565),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Color(0xFF99A1AF),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _formatDateRange(r.startDate, r.endDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF6A7282),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _relativeTime(r.requestedAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF99A1AF),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF99A1AF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestBadge badge;
  final ApprovalStatus status;

  const _StatusBadge({required this.badge, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ApprovalStatus.approved) {
      return _badgePill(
        context,
        label: 'Approved',
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF16A34A),
      );
    }
    if (status == ApprovalStatus.rejected) {
      return _badgePill(
        context,
        label: 'Rejected',
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFFDC2626),
      );
    }
    switch (badge) {
      case RequestBadge.urgent:
        return _badgePill(
          context,
          label: 'Urgent',
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFFEA580C),
          icon: Icons.priority_high_rounded,
        );
      case RequestBadge.newRequest:
        return _badgePill(
          context,
          label: 'New',
          bg: const Color(0xFFEFF6FF),
          fg: const Color(0xFF155DFC),
        );
      case RequestBadge.none:
        return const SizedBox.shrink();
    }
  }

  Widget _badgePill(
    BuildContext context, {
    required String label,
    required Color bg,
    required Color fg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalDetailSheet extends StatelessWidget {
  final ApprovalRequestData request;

  const _ApprovalDetailSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Request Detail',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    _StatusBadge(badge: r.badge, status: r.status),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F1F1)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              r.assetImageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFFF3F4F6),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.devices_other_rounded,
                                  color: Color(0xFF99A1AF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.assetName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF101828),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Request ID: ${r.id}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF6A7282),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DetailSectionLabel(
                      icon: Icons.person_outline_rounded,
                      title: 'Requested By',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              r.staffName.isNotEmpty
                                  ? r.staffName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF1447E6),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.staffName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF101828),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  r.staffRole,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF6A7282),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailSectionLabel(
                      icon: Icons.calendar_month_outlined,
                      title: 'Borrowing Period',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PeriodTile(
                            label: 'Start Date',
                            date: r.startDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PeriodTile(
                            label: 'End Date',
                            date: r.endDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailSectionLabel(
                      icon: Icons.info_outline_rounded,
                      title: 'Justification',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        r.justification,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: const Color(0xFF364153),
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (r.status == ApprovalStatus.pending)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F1F1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(
                                context, ApprovalStatus.rejected),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                  color: Color(0xFFFCA5A5), width: 1.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(
                                context, ApprovalStatus.approved),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF155DFC),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _DetailSectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final String label;
  final DateTime date;

  const _PeriodTile({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6A7282),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatFullDate(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ApprovalStatus activeTab;

  const _EmptyState({required this.activeTab});

  @override
  Widget build(BuildContext context) {
    final config = switch (activeTab) {
      ApprovalStatus.pending => (
          icon: Icons.task_alt_rounded,
          title: 'All caught up!',
          subtitle:
              'Tidak ada permintaan peminjaman yang menunggu persetujuan saat ini.',
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
        ),
      ApprovalStatus.approved => (
          icon: Icons.fact_check_rounded,
          title: 'Belum ada riwayat approve',
          subtitle: 'Permintaan yang Anda setujui akan muncul di sini.',
          color: const Color(0xFF155DFC),
          bg: const Color(0xFFDBEAFE),
        ),
      ApprovalStatus.rejected => (
          icon: Icons.do_not_disturb_alt_rounded,
          title: 'Belum ada penolakan',
          subtitle: 'Permintaan yang Anda tolak akan muncul di sini.',
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEE2E2),
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: config.bg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(config.icon, size: 44, color: config.color),
            ),
            const SizedBox(height: 18),
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              config.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6A7282),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateRange(DateTime start, DateTime end) {
  return '${_formatShortDate(start)} - ${_formatShortDate(end)}';
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]}';
}

String _formatFullDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}
