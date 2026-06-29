import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/spl_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/spl_usecases/get_spl_detail.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

/// Detail satu pengajuan lembur (SPL) milik SPV pemohon.
///
/// Cegatan kepemilikan: hanya pembuat pengajuan yang boleh melihat detail.
/// Identitas pembuat = `pemohonId` (== users.id), konsisten dengan filter
/// daftar di `riwayat_pengajuan_lembur.dart`. Bila bukan pemilik, halaman
/// menampilkan layar "akses ditolak" dan tidak melakukan fetch apa pun.
///
/// Field utama sudah lengkap dari entity yang dikirim daftar, sehingga
/// di-render langsung. `members` (daftar peserta) dilengkapi via refetch
/// `GET /v1/lembur-spl/{id}` agar pasti tersedia.
class ViewRiwayatPengajuanLemburPage extends StatefulWidget {
  final SplEntity spl;

  const ViewRiwayatPengajuanLemburPage({super.key, required this.spl});

  @override
  State<ViewRiwayatPengajuanLemburPage> createState() =>
      _ViewRiwayatPengajuanLemburPageState();
}

class _ViewRiwayatPengajuanLemburPageState
    extends State<ViewRiwayatPengajuanLemburPage> {
  late SplEntity _spl = widget.spl;
  late final bool _isOwner = _resolveOwnership();
  bool _loadingMembers = false;

  bool _resolveOwnership() {
    final myId = AuthStorage.getUserSync()?['id'] as int?;
    return myId != null && widget.spl.pemohonId == myId;
  }

  @override
  void initState() {
    super.initState();
    if (_isOwner) _loadDetail();
  }

  /// Refetch detail agar daftar peserta (nama + NIP) terbaru. BE meng-eager-load
  /// `members.user.pegawai`, jadi tiap peserta sudah membawa data pegawainya.
  /// Bila gagal, tetap pakai entity dari daftar (yang juga sudah memuat members).
  Future<void> _loadDetail() async {
    final id = widget.spl.id;
    if (id == null) return;
    if (mounted) setState(() => _loadingMembers = true);
    try {
      final detail = await sl<GetSplDetailUseCase>()(id);
      if (detail is DataSuccess<SplEntity> && detail.data != null) {
        if (mounted) setState(() => _spl = detail.data!);
      }
    } catch (_) {
      // Diamkan: jatuh kembali ke data daftar.
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    // BE menserialisasi tanggal/waktu sebagai UTC (akhiran 'Z'); konversi ke
    // zona perangkat agar tanggal & jam sesuai data asli (mis. WIB).
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    final t =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${_formatDate(local)} $t';
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
              _buildHeader(),
              Expanded(child: _isOwner ? _buildBody() : _buildDenied()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              'Detail Pengajuan Lembur',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'Anda tidak memiliki akses ke pengajuan ini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final status = (_spl.statusCode ?? 'pending').toLowerCase();
    final isRejected = status == 'rejected';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildTitleCard(status),
        const SizedBox(height: 12),
        _buildSection(
          title: 'Informasi Pengajuan',
          children: [
            _infoRow('Jenis pekerjaan', _spl.jenisPekerjaan),
            _infoRow('Tanggal lembur', _formatDate(_spl.tanggalLembur)),
            _infoRow('Jam mulai', _spl.jamMulai),
            _infoRow(
              'Estimasi jam',
              _spl.estimasiJam != null ? '${_spl.estimasiJam} jam' : null,
            ),
            _infoRow('Alasan lembur', _spl.alasanLembur),
          ],
        ),
        const SizedBox(height: 12),
        _buildSection(
          title: 'Status Proses',
          children: [
            _infoRow('Status', _statusLabel(status)),
            _infoRow('Waktu pengajuan', _formatDateTime(_spl.createdAt)),
            _infoRow('Waktu verifikasi', _formatDateTime(_spl.verificationDate)),
            if (isRejected && (_spl.reason?.trim().isNotEmpty == true))
              _rejectionNote(_spl.reason!),
          ],
        ),
        const SizedBox(height: 12),
        _buildMembersSection(),
      ],
    );
  }

  Widget _buildTitleCard(String status) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _spl.judulPekerjaan?.trim().isNotEmpty == true
                  ? _spl.judulPekerjaan!
                  : 'Pengajuan Lembur',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: status),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    final members = _spl.members ?? const [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Peserta Lembur',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              if (_loadingMembers)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (members.isEmpty && !_loadingMembers)
            const Text(
              'Tidak ada peserta',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            )
          else
            for (var i = 0; i < members.length; i++)
              _memberTile(members[i], isCoordinator: i == 0),
        ],
      ),
    );
  }

  /// Render satu peserta. BE mengembalikan tiap member sebagai objek hasil
  /// eager-load `members.user.pegawai`, jadi nama & NIP diambil dari
  /// `member['user']['pegawai']`. Peserta pertama ditandai Koordinator
  /// (kontrak create: PIC = anggota pertama).
  Widget _memberTile(dynamic member, {required bool isCoordinator}) {
    String name = '-';
    String? subtitle;
    if (member is Map) {
      final user = member['user'];
      final pegawai = user is Map ? user['pegawai'] : null;
      final nama = (pegawai is Map ? pegawai['nama'] : null) ?? member['nama'];
      final nip = (pegawai is Map ? pegawai['nip'] : null) ?? member['nip'];
      name = (nama ?? 'Peserta').toString();
      if (nip != null && nip.toString().trim().isNotEmpty) {
        subtitle = 'NIP: $nip';
      }
    } else {
      name = member?.toString() ?? '-';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.person_outline,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (isCoordinator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Koordinator',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    final display = (value == null || value.trim().isEmpty) ? '-' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectionNote(String reason) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alasan ditolak: $reason',
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Pending';
    }
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
