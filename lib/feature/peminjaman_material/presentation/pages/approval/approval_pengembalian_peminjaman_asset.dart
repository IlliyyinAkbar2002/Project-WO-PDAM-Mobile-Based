import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/spv/landing_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/users/staff/landing_page.dart';

class PersetujuanPeminjamanBarangPage extends StatefulWidget {
  const PersetujuanPeminjamanBarangPage({super.key});

  @override
  State<PersetujuanPeminjamanBarangPage> createState() =>
      _PersetujuanPeminjamanBarangPageState();
}

class _PersetujuanPeminjamanBarangPageState
    extends State<PersetujuanPeminjamanBarangPage> {
  final TextEditingController _searchController = TextEditingController();
  final MaterialRemoteDataSource _materialRemote = MaterialRemoteDataSource();

  int _activeTab = 0; // 0: Pending, 1: Approved
  String _query = '';
  bool _isLoading = false;
  List<PeminjamanMaterialEntity> _allPeminjaman = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _materialRemote.getAllPeminjaman();

      if (result is DataSuccess && result.data != null) {
        setState(() {
          _allPeminjaman = result.data!;
        });
      } else {
        AppSnackbar.showError('Gagal mengambil data peminjaman material.');
      }
    } catch (e) {
      AppSnackbar.showError('Terjadi kesalahan saat memuat data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRoleDashboard() {
    final user = AuthStorage.getUserSync();
    final roleId = user?['role_id'] as int?;
    final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';

    Widget target;
    if (roleId == 4 && isSpv) {
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

  List<PeminjamanMaterialEntity> get _filteredPeminjaman {
    final statusFilter = _activeTab == 0 ? 'PENDING_KEMBALI' : 'DIKEMBALIKAN';
    return _allPeminjaman.where((p) {
      if (p.status != statusFilter) return false;
      if (_query.isEmpty) return true;
      final staffName = (p.user?.employee?.name ?? 'Staff').toLowerCase();
      final matName = (p.material?.namaMaterial ?? '').toLowerCase();
      return staffName.contains(_query) || matName.contains(_query);
    }).toList();
  }

  int get _pendingCount =>
      _allPeminjaman.where((p) => p.status == 'PENDING_KEMBALI').length;

  Future<void> _verifyReturnRequest(
    PeminjamanMaterialEntity request,
    String actionStatus,
  ) async {
    final verifikatorController = TextEditingController();
    final actionLabel = actionStatus == 'APPROVED' ? 'Setujui' : 'Tolak';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionLabel Pengembalian?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin $actionLabel pengembalian untuk ${request.material?.namaMaterial ?? "material ini"}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: verifikatorController,
              decoration: InputDecoration(
                labelText: 'Catatan Verifikator (Opsional)',
                hintText: 'Masukkan catatan/alasan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionStatus == 'APPROVED'
                  ? const Color(0xFF155DFC)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _materialRemote.verifyReturn(
        peminjamanId: request.id!,
        status: actionStatus,
        catatanVerifikator: verifikatorController.text.trim().isNotEmpty
            ? verifikatorController.text.trim()
            : null,
      );

      if (res is DataSuccess) {
        AppSnackbar.showSuccess(
          'Pengembalian berhasil ${actionStatus == "APPROVED" ? "disetujui" : "ditolak"}.',
        );
        _fetchData();
      } else {
        AppSnackbar.showError(
          res.error?.response?.data?['message'] ??
              'Gagal memverifikasi pengembalian.',
        );
      }
    } catch (e) {
      AppSnackbar.showError('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetail(PeminjamanMaterialEntity request) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _ApprovalDetailSheet(
        request: request,
        onVerify: (status) {
          Navigator.pop(context);
          _verifyReturnRequest(request, status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPeminjaman;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildRequestCard(filtered[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                onTap: _navigateToRoleDashboard,
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
                  'Approval Log Pengembalian Material',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: Color(0xFF155DFC),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
            'Tinjau pengembalian material dari staff.',
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
                    controller: _searchController,
                    cursorColor: const Color(0xFF155DFC),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF101828),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Cari staff atau nama material...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: const Color(0xFF99A1AF),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF99A1AF),
                    ),
                    onPressed: () => _searchController.clear(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildTabs(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
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
            child: _buildTabSegment(
              'Pending',
              0,
              _pendingCount > 0 ? _pendingCount : null,
            ),
          ),
          Expanded(child: _buildTabSegment('Approved', 1, null)),
        ],
      ),
    );
  }

  Widget _buildTabSegment(String label, int index, int? badgeCount) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
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
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
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
                    color: isActive ? Colors.white : const Color(0xFF1447E6),
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

  Widget _buildRequestCard(PeminjamanMaterialEntity request) {
    final matName =
        request.material?.namaMaterial ?? 'Material #${request.materialKode}';
    final requesterName = request.user?.employee?.name ?? 'Staff';
    final submittedTime = request.waktuKembali ?? DateTime.now();

    return GestureDetector(
      onTap: () => _openDetail(request),
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          requesterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF101828),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (request.status == 'PENDING_KEMBALI')
                        _buildBadge(
                          'Pending Return',
                          const Color(0xFFEFF6FF),
                          const Color(0xFF155DFC),
                        )
                      else if (request.status == 'DIKEMBALIKAN')
                        _buildBadge(
                          'Returned',
                          const Color(0xFFECFDF5),
                          const Color(0xFF059669),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    matName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4A5565),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 13,
                        color: Color(0xFF99A1AF),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Pinjam: ${request.jumlahPinjam} • Terpasang: ${request.jumlahTerpasang ?? '-'} • Rusak: ${request.jumlahRusak ?? 0}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF6A7282),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _relativeTime(submittedTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF99A1AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isPending = _activeTab == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isPending ? Icons.check_circle_rounded : Icons.history_rounded,
                size: 38,
                color: isPending
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF155DFC),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isPending ? 'Selesai Semua!' : 'Belum Ada Riwayat',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Tidak ada pengajuan pengembalian material yang menunggu verifikasi.'
                  : 'Pengembalian material yang telah diverifikasi akan muncul di sini.',
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

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(time);
  }
}

class _ApprovalDetailSheet extends StatelessWidget {
  final PeminjamanMaterialEntity request;
  final ValueChanged<String> onVerify;

  const _ApprovalDetailSheet({required this.request, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final matName = r.material?.namaMaterial ?? 'Material #${r.materialKode}';
    final submittedTime = r.waktuKembali ?? r.waktuPinjam ?? DateTime.now();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Return Request Detail',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  matName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF101828),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kategori: ${r.material?.kategori ?? "Umum"}',
                                  style: Theme.of(context).textTheme.bodySmall
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
                    _buildSectionLabel(
                      Icons.person_outline_rounded,
                      'Requested By',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                              (r.user?.employee?.name ?? 'Staff').isNotEmpty
                                  ? (r.user?.employee?.name ?? 'Staff')[0]
                                        .toUpperCase()
                                  : 'S',
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
                                  r.user?.employee?.name ?? 'Staff Lapangan',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF101828),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  'NIP: ${r.user?.employee?.nip ?? "-"}',
                                  style: Theme.of(context).textTheme.bodySmall
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
                    _buildSectionLabel(
                      Icons.assignment_turned_in_outlined,
                      'Material Detail',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            'Jumlah Pinjam',
                            '${r.jumlahPinjam} ${r.material?.satuan ?? ""}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoTile(
                            'Jumlah Kembali',
                            '${r.jumlahKembali ?? 0} ${r.material?.satuan ?? ""}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            'Jumlah Terpasang',
                            '${r.jumlahTerpasang ?? '-'} ${r.material?.satuan ?? ""}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoTile(
                            'Jumlah Rusak',
                            '${r.jumlahRusak ?? 0} ${r.material?.satuan ?? ""}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel(
                      Icons.calendar_month_outlined,
                      'Submitted Date',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoTile(
                      'Tanggal Pengajuan Pengembalian',
                      DateFormat('dd MMMM yyyy HH:mm').format(submittedTime),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel(
                      Icons.info_outline_rounded,
                      'Kondisi Pengembalian (Catatan Staff)',
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
                        r.kondisiKembali ?? 'Tidak ada catatan.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF364153),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (r.status == 'PENDING_KEMBALI')
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => onVerify('REJECTED'),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                color: Color(0xFFFCA5A5),
                                width: 1.4,
                              ),
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
                            onPressed: () => onVerify('APPROVED'),
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

  Widget _buildSectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: double.infinity,
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
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6A7282),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
