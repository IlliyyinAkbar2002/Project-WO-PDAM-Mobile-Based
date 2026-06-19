import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/detail_work_order_keluar/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';
import 'package:project_mobile_pdam/core/constants/tahapan_labels.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';

final List<Map<String, dynamic>> progressList = [
  {"id": 1, "type": "start", "isFilled": false},
  {"id": 4, "type": "finish", "isFilled": false},
];

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
  bool _isNavigatingToReport = false;
  late final WorkOrderProgressRemoteDataSource _progressRemoteDataSource;
  late final MaterialRemoteDataSource _materialRemoteDataSource;
  WorkOrderEntity? _workOrder;

  String _resolveAppBarTitle() {
    if (widget.kategoriForm != null) {
      return WoKategoriForm.label(widget.kategoriForm);
    }
    // Fallback untuk backward compat
    return widget.isOvertime ? "Work Order Lembur" : "Work Order";
  }

  Map<String, dynamic> _buildKategoriFormData(WorkOrderEntity workOrder) {
    final Map<String, dynamic>? detail = workOrder.detailKategori;
    if (detail == null) return const {};

    switch (workOrder.kategoriForm) {
      case 'jaringan':
        return {
          "jenis_pipa": detail["jenis_pipa"],
          "diameter_pipa": detail["diameter_pipa"]?.toString(),
          "panjang_pipa": detail["panjang_pipa"]?.toString(),
          "tingkat_kerusakan": detail["tingkat_kerusakan"],
          "tindakan_perbaikan": detail["tindakan_perbaikan"]?.toString(),
          "hasil_inspeksi": detail["hasil_inspeksi"]?.toString(),
        };
      case 'infrastruktur':
        return {
          "nama_aset": detail["nama_aset"],
          "jenis_aset": detail["jenis_aset"],
          "kapasitas": detail["kapasitas"]?.toString(),
          "kondisi_awal": detail["kondisi_awal"]?.toString(),
          "kondisi_akhir": detail["kondisi_akhir"]?.toString(),
          "jadwal_pemeliharaan": detail["jadwal_pemeliharaan"]?.toString(),
          "tindakan": detail["tindakan"]?.toString(),
        };
      case 'meter':
        return {
          "nomor_meter": detail["nomor_meter"],
          "kondisi_meter_awal": detail["kondisi_meter_awal"],
          "kondisi_meter_akhir": detail["kondisi_meter_akhir"]?.toString(),
          "hasil_kalibrasi": detail["hasil_kalibrasi"]?.toString(),
        };
      default:
        return const {};
    }
  }

  @override
  void initState() {
    super.initState();
    _progressRemoteDataSource =
        GetIt.instance<WorkOrderProgressRemoteDataSource>();
    _materialRemoteDataSource = GetIt.instance<MaterialRemoteDataSource>();
    _fetchProgresses();

    // Check if WorkOrderBloc already has the work order detail loaded
    final workOrderBloc = context.read<WorkOrderBloc>();
    if (workOrderBloc.state is WorkOrderDetailLoaded) {
      _workOrder = (workOrderBloc.state as WorkOrderDetailLoaded).workOrder;
    }
    // Muat detail WO (termasuk assignment: koordinat & lokasi) supaya titik
    // peta bisa diteruskan ke WorkOrderReportPage. lngLat dari daftar WO kosong
    // karena endpoint index BE tidak menyertakan assignment.
    if (widget.workOrderId != null) {
      workOrderBloc.add(GetWorkOrderDetailEvent(widget.workOrderId!));
    }
  }

  /// Titik peta WO. Prioritaskan nilai dari konstruktor (daftar WO); bila kosong
  /// — yang terjadi pada BE terintegrasi karena index tidak memuat assignment —
  /// ambil dari assignment hasil fetch detail.
  LatLng? get _resolvedLngLat {
    if (widget.lngLat != null) return widget.lngLat;
    final assignment = _workOrder?.assignment;
    final double? lat = assignment?.latitude ?? assignment?.location?.latitude;
    final double? lng =
        assignment?.longitude ?? assignment?.location?.longitude;
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  String? get _resolvedLocationName =>
      widget.locationName ?? _workOrder?.assignment?.location?.nama;

  int get _resolvedRadiusMeter =>
      _workOrder?.assignment?.location?.radiusMeter ?? widget.radiusMeter;

  /// Status WO terkini. `widget.status` dibekukan saat halaman dibuka, sehingga
  /// basi setelah staf submit "Selesai" (status BE berpindah ke pengecekan).
  /// Utamakan `statusId` dari detail WO yang ikut ter-refresh lewat WorkOrderBloc.
  int? get _liveStatus => _workOrder?.statusId ?? widget.status;

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
    return BlocListener<WorkOrderBloc, WorkOrderState>(
      listener: (context, state) {
        if (state is WorkOrderDetailLoaded) {
          setState(() {
            _workOrder = state.workOrder;
          });
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: _resolveAppBarTitle()),
        body: _buildBody(),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    _fetchProgresses();
    if (widget.workOrderId != null) {
      context.read<WorkOrderBloc>().add(
        GetWorkOrderDetailEvent(widget.workOrderId!),
      );
    }
  }

  Widget _buildBody() {
    if (!_progressesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<WorkOrderProgressEntity> visibleProgresses = progresses
        .where((p) => !p.isDibatalkan)
        .toList();

    final bool hasInspeksi = visibleProgresses.any((item) => item.isInspeksi);
    final bool hasMulai = visibleProgresses.any((item) => item.isMulai);
    final bool hasSelesai = visibleProgresses.any((item) => item.isSelesai);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailWorkOrderPage(
            isOvertime: widget.isOvertime,
            workOrderId: widget.workOrderId,
            isAssignee: widget.isAssignee,
            status: widget.status,
            enableInnerScroll: false,
          ),
          if (_workOrder != null) _buildTahapanStepper(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Pelaporan Work Order",
                  style: textTheme.displayMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasInspeksi && !hasMulai)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: _buildActionButton('Inspeksi'),
              ),
            ),
          if (hasInspeksi && !hasMulai)
            Row(
              children: [
                Expanded(child: _buildActionButton('Mulai')),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSecondaryOutlinedButton(
                    label: 'Pinjam Material',
                    onPressed: () async {
                      final shouldRefresh = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PeminjamanItemListPage(
                            workOrderId: widget.workOrderId,
                          ),
                        ),
                      );
                      if (shouldRefresh == true && mounted) {
                        _handleRefresh();
                      }
                    },
                  ),
                ),
              ],
            ),
          ...visibleProgresses.map(
            (progressIndex) => _buildProgressEntry(progressIndex),
          ),
          if (hasMulai && !hasSelesai) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildActionButton('Selesai')),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton('Laporan')),
              ],
            ),
          ],
          // Tombol muncul begitu staff submit progress "Selesai". Tidak digate
          // ke status WO numerik (5/6): BE terintegrasi memakai status string
          // (Proses→13, Selesai→6) & tak punya "pengecekan", lalu status WO
          // induk baru jadi "Selesai" saat verifikasi — bukan saat staff selesai.
          if (hasSelesai) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryOutlinedButton(
                    label: 'Kembalikan Material',
                    onPressed: () async {
                      final shouldRefresh = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PeminjamanItemListPage(
                            workOrderId: widget.workOrderId,
                          ),
                        ),
                      );
                      if (shouldRefresh == true && mounted) {
                        _handleRefresh();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTahapanStepper() {
    int computedTahapan = 0;
    if (_workOrder?.tahapanTertinggi != null) {
      computedTahapan = _workOrder!.tahapanTertinggi!;
    } else {
      for (final p in progresses) {
        if (!p.isDibatalkan &&
            p.tahapan != null &&
            p.tahapan! > computedTahapan) {
          computedTahapan = p.tahapan!;
        }
      }
    }

    final labels = tahapanLabelsFor(_workOrder?.workOrderType?.name);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.foreground[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahapan Pekerjaan',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final stepTahapan = index + 1;
              final isCompleted = computedTahapan >= stepTahapan;
              final isCurrent =
                  computedTahapan + 1 == stepTahapan && computedTahapan != 4;
              // Jika selesai semua, step 4 akan isCompleted=true, isCurrent=false

              final Color circleColor = isCompleted
                  ? color.status[2]! // hijau
                  : isCurrent
                  ? color.primary[500]! // biru primary
                  : color.foreground[300]!; // abu-abu

              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? circleColor
                                  : Colors.transparent,
                              border: Border.all(color: circleColor, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : isCurrent
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: circleColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: isCurrent || isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isCurrent || isCompleted
                                  ? color.foreground[900]
                                  : color.foreground[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 11),
                          height: 2,
                          color: isCompleted
                              ? color.status[2]
                              : color.foreground[200],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
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
          description: progress.description,
          dateTime: _resolveProgressDateTime(progress),
          onTap: () async {
            final shouldRefresh = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => WorkOrderReportPage(
                  mode: progress.progressType ?? '-',
                  status: _liveStatus,
                  isAssignee: widget.isAssignee,
                  progressId: progress.id,
                  workOrderId: widget.workOrderId,
                  workOrderTypeId: widget.workOrderTypeId,
                  lngLat: _resolvedLngLat,
                  locationName: _resolvedLocationName,
                  radiusMeter: _resolvedRadiusMeter,
                  kategoriForm: widget.kategoriForm,
                  initialKategoriData: _workOrder != null
                      ? _buildKategoriFormData(_workOrder!)
                      : null,
                  workOrderTypeName: _workOrder?.workOrderType?.name,
                  initialDescription: progress.description,
                ),
              ),
            );
            if (shouldRefresh == true && mounted) {
              _handleRefresh();
            }
          },
        ),
        if (progress.canCancel)
          Positioned(top: 8, right: 8, child: _buildCancelButton(progress)),
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
    final String message =
        'Laporan ini akan dibatalkan. Tindakan ini tidak dapat diurungkan.';

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
    final result = await _progressRemoteDataSource.cancelProgress(progress.id!);
    if (!mounted) return;
    if (result is DataSuccess) {
      final String successMsg = 'Laporan berhasil dibatalkan.';
      AppSnackbar.showSuccess(successMsg);
      _handleRefresh();
    } else {
      final errorMsg = result.error?.response?.data is Map
          ? (result.error!.response!.data['message'] ??
                'Gagal membatalkan laporan.')
          : 'Gagal membatalkan laporan. Mungkin sudah melewati batas waktu 5 menit.';
      AppSnackbar.showError(errorMsg.toString());
    }
  }

  Future<bool> _needsPinjamMaterialFirst() async {
    if (widget.workOrderId == null) return false;
    try {
      final result = await _materialRemoteDataSource.getPeminjamanByWo(
        widget.workOrderId!,
      );
      if (result is DataSuccess) {
        return (result.data ?? const []).isEmpty;
      }
    } catch (e) {
      debugPrint('⚠️ Gagal cek peminjaman material: $e');
    }
    return false;
  }

  Future<void> _showPinjamMaterialReminder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Pinjam Material Dulu',
          style: TextStyle(
            color: Color(0xFF001F54),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Anda belum meminjam material untuk work order ini. Silakan ajukan '
          'peminjaman material terlebih dahulu sebelum memulai pekerjaan.',
          style: TextStyle(color: Color(0xFF001F54)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PeminjamanItemListPage(workOrderId: widget.workOrderId),
      ),
    );
    if (shouldRefresh == true && mounted) {
      _handleRefresh();
    }
  }

  Widget _buildActionButton(String mode, {bool disabled = false}) {
    // Map mode 'Laporan' ke tipeProgressId 2 (Progress) di WorkOrderReportPage
    final String reportMode = mode == 'Laporan' ? 'Progress' : mode;

    Future<void> handleTap() async {
      if (disabled) return;
      if (_isNavigatingToReport) {
        AppSnackbar.showWarning('Tombol $mode sudah ditekan, mohon tunggu.');
        return;
      }
      _isNavigatingToReport = true;
      try {
        // Pencegatan tombol "Mulai": bila belum ada peminjaman material untuk
        // WO ini, arahkan staff untuk meminjam material lebih dulu.
        if (mode == 'Mulai') {
          final bool needPinjam = await _needsPinjamMaterialFirst();
          if (!mounted) return;
          if (needPinjam) {
            await _showPinjamMaterialReminder();
            return;
          }
        }

        final bool? shouldRefresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => WorkOrderReportPage(
              mode: reportMode,
              status: _liveStatus,
              isAssignee: widget.isAssignee,
              progressId: null,
              workOrderId: widget.workOrderId,
              workOrderTypeId: widget.workOrderTypeId,
              lngLat: _resolvedLngLat,
              locationName: _resolvedLocationName,
              radiusMeter: _resolvedRadiusMeter,
              kategoriForm: widget.kategoriForm,
              initialKategoriData: _workOrder != null
                  ? _buildKategoriFormData(_workOrder!)
                  : null,
              workOrderTypeName: _workOrder?.workOrderType?.name,
            ),
          ),
        );
        if (shouldRefresh == true && mounted) {
          _handleRefresh();
        }
      } finally {
        if (mounted) _isNavigatingToReport = false;
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
