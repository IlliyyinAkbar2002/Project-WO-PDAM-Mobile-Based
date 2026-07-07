import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/get_spls_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/pengajuan_lembur/view_riwayat_pengajuan_lembur.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

/// Daftar riwayat pengajuan lembur milik SPV yang login.
///
/// BE `GET /v1/lembur-spl` mengembalikan SEMUA pengajuan (tidak difilter ke
/// pemohon), maka penyaringan "milik saya" dilakukan FE-side via
/// `pemohonId == users.id`. Semua status (`pending`/`approved`/`rejected`)
/// ditampilkan agar pemohon dapat memantau proses pengajuannya, termasuk yang
/// sudah disetujui.
class RiwayatPengajuanLemburPage extends StatefulWidget {
  const RiwayatPengajuanLemburPage({super.key});

  @override
  State<RiwayatPengajuanLemburPage> createState() =>
      _RiwayatPengajuanLemburPageState();
}

class _RiwayatPengajuanLemburPageState
    extends State<RiwayatPengajuanLemburPage> {
  bool _loading = true;
  List<SplEntity> _items = const [];

  /// Filter rentang berdasarkan `tanggalLembur` (null = tampilkan semua).
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Daftar yang ditampilkan setelah filter tanggal diterapkan.
  List<SplEntity> get _filteredItems {
    final range = _dateFilter;
    if (range == null) return _items;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return _items.where((spl) {
      // Selaras dengan tampilan: pakai tanggal lokal (BE mengirim UTC).
      final d = spl.tanggalLembur?.toLocal();
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateFilter,
    );
    if (picked != null) {
      setState(() => _dateFilter = picked);
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await sl<GetSplsUseCase>()(const NoParams());
      if (result is DataSuccess<List<SplEntity>>) {
        final myUserId = AuthStorage.getUserSync()?['id'] as int?;
        final all = result.data ?? const <SplEntity>[];
        final filtered = all
            .where((spl) => myUserId != null && spl.pemohonId == myUserId)
            .toList();
        if (mounted) setState(() => _items = filtered);
      } else if (result is DataFailed<List<SplEntity>>) {
        AppSnackbar.showError(
          'Gagal memuat riwayat pengajuan lembur.',
        );
      }
    } catch (e) {
      AppSnackbar.showError('Terjadi kesalahan saat memuat data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(SplEntity spl) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewRiwayatPengajuanLemburPage(spl: spl),
      ),
    );
    // Segarkan daftar saat kembali (status bisa berubah di sisi BE).
    await _load();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    // BE menserialisasi tanggal sebagai UTC (akhiran 'Z'); konversi ke zona
    // perangkat agar tanggal tampil sesuai data asli (mis. WIB).
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFF0F172A),
                    ),
                    const Expanded(
                      child: Text(
                        'Riwayat Pengajuan Lembur',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildFilterBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final range = _dateFilter;
    final hasFilter = range != null;
    final label = hasFilter
        ? '${_formatDate(range.start)} - ${_formatDate(range.end)}'
        : 'Filter tanggal lembur';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFilter
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: hasFilter
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: hasFilter
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                          fontSize: 13.5,
                          fontWeight: hasFilter
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _dateFilter = null),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _filteredItems;
    if (items.isEmpty) {
      final message = _dateFilter != null
          ? 'Tidak ada pengajuan pada rentang tanggal ini'
          : 'Belum ada pengajuan lembur';
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.description_outlined,
              size: 56,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _SplCard(
          spl: items[index],
          formatDate: _formatDate,
          onTap: () => _openDetail(items[index]),
        ),
      ),
    );
  }
}

class _SplCard extends StatelessWidget {
  final SplEntity spl;
  final String Function(DateTime?) formatDate;
  final VoidCallback onTap;

  const _SplCard({
    required this.spl,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (spl.statusCode ?? 'pending').toLowerCase();
    final isRejected = status == 'rejected';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  spl.judulPekerjaan?.trim().isNotEmpty == true
                      ? spl.judulPekerjaan!
                      : 'Pengajuan Lembur',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                'Tanggal lembur: ${formatDate(spl.tanggalLembur)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (isRejected && (spl.reason?.trim().isNotEmpty == true)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan ditolak: ${spl.reason}',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Disetujui';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Ditolak';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
