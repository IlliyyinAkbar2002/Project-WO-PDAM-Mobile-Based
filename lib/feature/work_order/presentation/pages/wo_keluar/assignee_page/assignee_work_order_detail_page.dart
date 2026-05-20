import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/peminjaman_material_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/detail_work_order_keluar/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';

final List<Map<String, dynamic>> progressList = [
  {"id": 1, "type": "start", "isFilled": false},
  // {"id": 2, "type": "progress", "isFilled": true, "index": 1},
  // {"id": 3, "type": "progress", "isFilled": false, "index": 2},
  {"id": 4, "type": "finish", "isFilled": false},
];

const int _kDailyReportLimit = 8;

const double _kActionButtonHeight = 48.0;
const double _kActionButtonRadius = 8.0;

const EdgeInsets _kActionButtonPadding = EdgeInsets.symmetric(
  horizontal: 16.0,
  vertical: 0.0, // tinggi dikontrol via minimumSize
);

const TextStyle _kActionButtonTextStyle = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.w600,
);

final RoundedRectangleBorder _kActionButtonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(_kActionButtonRadius),
);

final Size _kActionButtonMinimumSize = Size.fromHeight(_kActionButtonHeight);

class AssigneeWorkOrderDetailPage extends StatefulWidget {
  final bool isAssignee;
  final int? workOrderId;
  final int? workOrderTypeId;
  final int? status;
  final bool isOvertime;
  final String? kategoriForm; // 'meter' | 'jaringan' | 'infrastruktur'
  final LatLng? lngLat;
  final String? locationName; // Nama lokasi dari MasterLocation
  final int radiusMeter; // Radius dari MasterLocation untuk pengecekan jarak

  const AssigneeWorkOrderDetailPage({
    super.key,
    this.isAssignee = false,
    this.workOrderId,
    this.workOrderTypeId,
    this.status,
    this.isOvertime = false,
    this.kategoriForm,
    this.lngLat,
    this.locationName,
    this.radiusMeter = 100, // Default 100 meter jika tidak ada
  });

  @override
  State<AssigneeWorkOrderDetailPage> createState() =>
      _AssigneeWorkOrderDetailPageState();
}

class _AssigneeWorkOrderDetailPageState
    extends AppStatePage<AssigneeWorkOrderDetailPage> {
  List<WorkOrderProgressEntity> progresses = [];
  bool _progressesLoaded = false;
  late final WorkOrderProgressRemoteDataSource _progressRemoteDataSource;

  String _resolveAppBarTitle() {
    if (widget.kategoriForm != null) {
      return WoKategoriForm.label(widget.kategoriForm);
    }
    // Fallback untuk backward compat
    return widget.isOvertime ? "Work Order Lembur" : "Work Order";
  }

  @override
  void initState() {
    super.initState();
    _progressRemoteDataSource =
        GetIt.instance<WorkOrderProgressRemoteDataSource>();
    _fetchProgresses();
  }

  /// Fetch progresses directly from remote data source — bypass BLoC
  /// to avoid race condition with shared WorkOrderBloc state.
  Future<void> _fetchProgresses() async {
    if (widget.workOrderId == null) return;
    debugPrint(
      "🔄 AssigneePage._fetchProgresses() for WO ${widget.workOrderId}",
    );
    try {
      final result = await _progressRemoteDataSource.fetchProgressByWorkOrderId(
        widget.workOrderId!,
      );
      if (!mounted) return;
      if (result is DataSuccess) {
        final entities = result.data!.map((m) => m.toEntity()).toList();
        debugPrint(
          "✅ AssigneePage: ${entities.length} progresses — "
          "ids: ${entities.map((e) => e.id).toList()}, "
          "tipeIds: ${entities.map((e) => e.tipeProgressId).toList()}",
        );
        setState(() {
          progresses = entities;
          _progressesLoaded = true;
        });
      } else {
        debugPrint(
          "⚠️ AssigneePage: Failed to fetch progresses: ${result.error}",
        );
        setState(() {
          _progressesLoaded = true;
        });
      }
    } catch (e, st) {
      debugPrint("⚠️ AssigneePage: Error fetching progresses: $e\n$st");
      if (mounted) {
        setState(() {
          _progressesLoaded = true;
        });
      }
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _resolveAppBarTitle()),
      body: _buildBody(),
    );
  }

  /// Hitung jumlah laporan yang sudah disubmit hari ini (bukan draft).
  /// Mulai tidak dihitung karena tidak mengonsumsi kuota.
  int _countSubmittedToday() {
    final today = DateTime.now();
    return progresses.where((p) {
      if (p.isMulai) return false;
      if (p.isDibatalkan) return false;
      final t = p.submitTime;
      if (t == null) return false;
      final local = t.toLocal();
      return local.year == today.year &&
          local.month == today.month &&
          local.day == today.day;
    }).length;
  }

  Widget _buildBody() {
    if (!_progressesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool hasMulai = progresses.any((item) => item.isMulai);
    final bool hasSelesai = progresses.any((item) => item.isSelesai);
    final int submittedToday = _countSubmittedToday();
    final int sisaKuota = (_kDailyReportLimit - submittedToday).clamp(
      0,
      _kDailyReportLimit,
    );
    final bool isKuotaHabis = sisaKuota == 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DetailWorkOrderPage(
          isOvertime: widget.isOvertime,
          workOrderId: widget.workOrderId,
          isAssignee: widget.isAssignee,
          status: widget.status,
          enableInnerScroll: false,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                "Pelaporan Work Order",
                style: textTheme.displayMedium,
              ),
            ),
            if (hasMulai && !hasSelesai) _buildKuotaChip(sisaKuota),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasMulai)
          Row(
            children: [
              Expanded(child: _buildActionButton('Mulai')),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryOutlinedButton(
                  label: 'Pinjam Material',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PeminjamanMaterialPage(
                          workOrderId: widget.workOrderId ?? 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ...progresses.map(
          (progressIndex) => _buildProgressEntry(progressIndex),
        ),
        if (hasMulai && !hasSelesai) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildActionButton('Selesai')),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton('Laporan', disabled: isKuotaHabis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryOutlinedButton(
                  label: 'Kembalikan Material',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PeminjamanMaterialPage(
                          workOrderId: widget.workOrderId ?? 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKuotaChip(int sisaKuota) {
    final bool isHabis = sisaKuota == 0;
    return Chip(
      label: Text(
        isHabis ? 'Kuota Habis' : 'Sisa: $sisaKuota/$_kDailyReportLimit',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isHabis ? Colors.white : color.primary[700],
        ),
      ),
      backgroundColor: isHabis ? color.danger : color.primary[100],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatEndDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm \'WIB\'');
    return formatter.format(dateTime);
  }

  String? _resolveProgressDateTime(WorkOrderProgressEntity progress) {
    final DateTime? sourceTime =
        progress.submitTime ?? progress.updatedAt ?? progress.createdAt;
    if (sourceTime == null) return null;
    return _formatEndDateTime(sourceTime);
  }

  Widget _buildProgressEntry(WorkOrderProgressEntity progress) {
    return Stack(
      children: [
        ProgressCard(
          type: progress.progressType ?? '-',
          index: progress.order ?? 0,
          description: progress.isDibatalkan
              ? '[Dibatalkan] ${progress.description ?? ''}'
              : progress.description,
          dateTime: _resolveProgressDateTime(progress),
          onTap: progress.isDibatalkan
              ? () {}
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkOrderReportPage(
                        mode: progress.progressType ?? '-',
                        status: widget.status,
                        isAssignee: widget.isAssignee,
                        progressId: progress.id,
                        workOrderId: widget.workOrderId,
                        workOrderTypeId: widget.workOrderTypeId,
                        lngLat: widget.lngLat,
                        locationName: widget.locationName,
                        radiusMeter: widget.radiusMeter,
                      ),
                    ),
                  );
                },
        ),
        if (progress.canCancel)
          Positioned(
            top: 8,
            right: 8,
            child: _buildCancelButton(progress),
          ),
      ],
    );
  }

  Widget _buildCancelButton(WorkOrderProgressEntity progress) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _confirmCancel(progress),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.danger, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.undo, size: 14, color: color.danger),
              const SizedBox(width: 4),
              Text(
                'Batalkan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(WorkOrderProgressEntity progress) async {
    final String message = progress.isMulai
        ? 'Laporan ini akan dibatalkan. Tindakan ini tidak dapat diurungkan.'
        : 'Laporan ini akan dibatalkan dan kuota harian Anda akan dikembalikan. '
            'Tindakan ini tidak dapat diurungkan.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Laporan?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: color.danger),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _executeCancelProgress(progress);
  }

  Future<void> _executeCancelProgress(WorkOrderProgressEntity progress) async {
    if (progress.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _progressRemoteDataSource.cancelProgress(progress.id!);
    if (!mounted) return;
    if (result is DataSuccess) {
      final String successMsg = progress.isMulai
          ? 'Laporan berhasil dibatalkan.'
          : 'Laporan berhasil dibatalkan. Kuota dikembalikan.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: Colors.green,
        ),
      );
      _fetchProgresses();
    } else {
      final errorMsg = result.error?.response?.data is Map
          ? (result.error!.response!.data['message'] ??
              'Gagal membatalkan laporan.')
          : 'Gagal membatalkan laporan. Mungkin sudah melewati batas waktu 5 menit.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg.toString()),
          backgroundColor: color.danger,
        ),
      );
    }
  }

  Widget _buildActionButton(String mode, {bool disabled = false}) {
    // Map mode 'Laporan' ke tipeProgressId 2 (Progress) di WorkOrderReportPage
    final String reportMode = mode == 'Laporan' ? 'Progress' : mode;

    Future<void> handleTap() async {
      if (disabled) return;
      final bool? shouldRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkOrderReportPage(
            mode: reportMode,
            status: widget.status,
            isAssignee: widget.isAssignee,
            progressId: null,
            workOrderId: widget.workOrderId,
            workOrderTypeId: widget.workOrderTypeId,
            lngLat: widget.lngLat,
            locationName: widget.locationName,
            radiusMeter: widget.radiusMeter,
          ),
        ),
      );
      if (shouldRefresh == true && mounted && widget.workOrderId != null) {
        _fetchProgresses();
      }
    }

    if (mode == 'Mulai') {
      return OutlinedButton(
        onPressed: handleTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.status[2]!, width: 2),
          minimumSize: _kActionButtonMinimumSize,
          shape: _kActionButtonShape,
          padding: _kActionButtonPadding,
          textStyle: _kActionButtonTextStyle,
        ),
        child: Text(mode),
      );
    }

    if (mode == 'Laporan') {
      return OutlinedButton(
        onPressed: disabled ? null : handleTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: disabled ? Colors.grey : color.control,
            width: 2,
          ),
          foregroundColor: disabled ? Colors.grey : color.control,
          minimumSize: _kActionButtonMinimumSize,
          shape: _kActionButtonShape,
          padding: _kActionButtonPadding,
          textStyle: _kActionButtonTextStyle,
        ),
        child: Text(mode),
      );
    }

    return ElevatedButton(
      onPressed: handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.primary[500],
        minimumSize: _kActionButtonMinimumSize,
        shape: _kActionButtonShape,
        padding: _kActionButtonPadding,
        textStyle: _kActionButtonTextStyle,
      ),
      child: Text(mode),
    );
  }

  Widget _buildSecondaryOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: _kActionButtonMinimumSize,
        shape: _kActionButtonShape,
        padding: _kActionButtonPadding,
        textStyle: _kActionButtonTextStyle,
      ),
      child: Text(label),
    );
  }
}
