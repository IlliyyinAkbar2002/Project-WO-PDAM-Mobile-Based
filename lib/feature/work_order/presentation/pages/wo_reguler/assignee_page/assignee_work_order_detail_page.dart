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
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/detail_work_order/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/tahapan_stepper.dart';
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

    final List<WorkOrderProgressEntity> visibleProgresses = progresses;

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
          if (_workOrder != null)
            TahapanStepper(workOrder: _workOrder, progresses: progresses),
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
                            returnMode: true,
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
      ],
    );
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

  /// Tahap tertinggi yang sudah tersubmit (acuan urutan tahapan). Dihitung dari
  /// daftar [progresses] — sama seperti [TahapanStepper]. Detail WO dari BE
  /// tidak mengembalikan `tahapan_tertinggi`, jadi `_workOrder.tahapanTertinggi`
  /// umumnya null; gunakan progress sebagai sumber yang andal.
  int _highestSubmittedTahapan() {
    final entityVal = _workOrder?.tahapanTertinggi;
    if (entityVal != null) return entityVal;
    int computed = 0;
    for (final p in progresses) {
      if (p.tahapan != null && p.tahapan! > computed) {
        computed = p.tahapan!;
      }
    }
    return computed;
  }

  Future<void> _showTahapanIncompleteReminder() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tahapan Belum Selesai',
          style: TextStyle(
            color: Color(0xFF001F54),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Selesaikan tahap Pengujian terlebih dahulu sebelum menyelesaikan '
          'work order. Tahapan harus dikerjakan berurutan.',
          style: TextStyle(color: Color(0xFF001F54)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

        // Pencegatan tombol "Selesai": tahap Pengujian (3) harus tercapai dulu
        // agar WO tidak diselesaikan dengan melompati tahapan (Bug 3).
        if (mode == 'Selesai' &&
            _highestSubmittedTahapan() < TahapanWorkorder.pengujian) {
          await _showTahapanIncompleteReminder();
          return;
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
              currentTahapanTertinggi: _highestSubmittedTahapan(),
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
