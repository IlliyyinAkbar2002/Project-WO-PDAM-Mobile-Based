import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/spl_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';
import 'package:project_mobile_pdam/core/seed/maps_seed_model.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_lembur/work_order_report_page_lembur.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/detail_work_order/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/tahapan_stepper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';

const double _kActionButtonHeight = 48.0;
const double _kActionButtonRadius = 8.0;

const EdgeInsets _kActionButtonPadding = EdgeInsets.symmetric(
  horizontal: 16.0,
  vertical: 0.0,
);

const TextStyle _kActionButtonTextStyle = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.w600,
);

final RoundedRectangleBorder _kActionButtonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(_kActionButtonRadius),
);

final Size _kActionButtonMinimumSize = Size.fromHeight(_kActionButtonHeight);

class DetailWorkOrderPageLembur extends StatefulWidget {
  final bool isAssignee;
  final int? workOrderId;
  final int? workOrderTypeId;
  final int? status;
  final String? kategoriForm;
  final LatLng? lngLat;
  final String? locationName;
  final int radiusMeter;

  const DetailWorkOrderPageLembur({
    super.key,
    this.isAssignee = false,
    this.workOrderId,
    this.workOrderTypeId,
    this.status,
    this.kategoriForm,
    this.lngLat,
    this.locationName,
    this.radiusMeter = MapsSeedModel.defaultRadiusMeter,
  });

  @override
  State<DetailWorkOrderPageLembur> createState() =>
      _DetailWorkOrderPageLemburState();
}

class _DetailWorkOrderPageLemburState
    extends AppStatePage<DetailWorkOrderPageLembur> {
  List<WorkOrderProgressEntity> progresses = [];

  bool _progressesLoaded = false;
  bool _isNavigatingToReport = false;
  late final WorkOrderProgressRemoteDataSource _progressRemoteDataSource;
  late final MaterialRemoteDataSource _materialRemoteDataSource;
  WorkOrderEntity? _workOrder;

  bool _isManager = false;
  int? _userId;

  String _resolveAppBarTitle() {
    if (widget.kategoriForm != null) {
      return "${WoKategoriForm.label(widget.kategoriForm)} Lembur";
    }
    return "Work Order Lembur";
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
    final user = AuthStorage.getUserSync();
    _isManager = user?['role_id'] == 2;
    _userId = user != null
        ? (user['id'] is int
              ? user['id']
              : int.tryParse(user['id']?.toString() ?? ''))
        : null;

    _progressRemoteDataSource =
        GetIt.instance<WorkOrderProgressRemoteDataSource>();
    _materialRemoteDataSource = GetIt.instance<MaterialRemoteDataSource>();
    // SPV (non-assignee) tak menampilkan Tahapan maupun entri pelaporan, jadi
    // `progresses` tak terpakai — lewati fetch dan tandai siap langsung.
    if (widget.isAssignee) {
      _fetchProgresses();
    } else {
      _progressesLoaded = true;
    }
    final workOrderBloc = context.read<WorkOrderBloc>();
    if (widget.workOrderId != null) {
      workOrderBloc.add(GetWorkOrderDetailEvent(widget.workOrderId!));
    }
    if (workOrderBloc.state is WorkOrderDetailLoaded) {
      _workOrder = (workOrderBloc.state as WorkOrderDetailLoaded).workOrder;
    }
  }

  Future<void> _fetchProgresses() async {
    if (widget.workOrderId == null) return;
    try {
      final result = await _progressRemoteDataSource.fetchProgressByWorkOrderId(
        widget.workOrderId!,
      );
      if (!mounted) return;
      if (result is DataSuccess) {
        final entities = result.data!.map((m) => m.toEntity()).toList();
        setState(() {
          progresses = entities;
          _progressesLoaded = true;
        });
      } else {
        setState(() {
          _progressesLoaded = true;
        });
      }
    } catch (e, st) {
      debugPrint("⚠️ DetailLemburPage: Error fetching progresses: $e\n$st");
      if (mounted) {
        setState(() {
          _progressesLoaded = true;
        });
      }
    }
  }

  void _handleApproval(int splId, bool isAccept) {
    final approval = SplModel(
      id: splId,
      statusId: isAccept ? 2 : 4,
      decision: isAccept ? "accept" : "reject",
      verificatorId: _userId,
    );
    context.read<WorkOrderBloc>().add(UpdateSplEvent(approval));
  }

  @override
  Widget buildPage(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WorkOrderBloc, WorkOrderState>(
          listener: (context, state) {
            if (state is WorkOrderDetailLoaded) {
              setState(() {
                _workOrder = state.workOrder;
              });
            }

            if (state is SplUpdated) {
              AppSnackbar.showSuccess("Approval SPL berhasil.");
              if (widget.workOrderId != null) {
                context.read<WorkOrderBloc>().add(
                  GetWorkOrderDetailEvent(widget.workOrderId!),
                );
              }
            }
          },
        ),
      ],
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

  Widget _buildBody() {
    if (!_progressesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<WorkOrderProgressEntity> visibleProgresses = progresses;

    final bool hasInspeksi = visibleProgresses.any((item) => item.isInspeksi);
    final bool hasMulai = visibleProgresses.any((item) => item.isMulai);
    final bool hasSelesai = visibleProgresses.any((item) => item.isSelesai);

    final isPendingApproval = _workOrder?.statusId == 1; // Pending SPL

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailWorkOrderPage(
            isOvertime: true,
            workOrderId: widget.workOrderId,
            isAssignee: widget.isAssignee,
            status: widget.status,
            enableInnerScroll: false,
          ),

          if (widget.isAssignee && _workOrder != null)
            TahapanStepper(workOrder: _workOrder, progresses: progresses),

          if (_isManager && isPendingApproval && _workOrder?.splId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Menunggu Persetujuan SPL",
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () =>
                              _handleApproval(_workOrder!.splId!, false),
                          child: const Text("Tolak"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () =>
                              _handleApproval(_workOrder!.splId!, true),
                          child: const Text("Setujui"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Seksi pelaporan hanya untuk assignee/staff. SPV cukup melihat form
          // + kartu "Progress Anggota Tim" dari embedded DetailWorkOrderPage.
          if (widget.isAssignee) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Pelaporan WO Lembur",
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
                builder: (_) => WorkOrderReportPageLembur(
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
                  initialDescription: progress.description,
                  scheduledStart:
                      _workOrder?.assignment?.startDateTime ??
                      _workOrder?.startDateTime,
                  currentTahapanTertinggi: _highestSubmittedTahapan(),
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

  Future<void> _showBelumWaktunyaReminder(DateTime scheduledStart) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Belum Waktunya',
          style: TextStyle(
            color: Color(0xFF001F54),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Work order ini dijadwalkan mulai pada '
          '${_formatEndDateTime(scheduledStart)}. '
          'Anda belum dapat memulainya sekarang.',
          style: const TextStyle(color: Color(0xFF001F54)),
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
    final String reportMode = mode == 'Laporan' ? 'Progress' : mode;

    Future<void> handleTap() async {
      if (disabled) return;
      if (_isNavigatingToReport) {
        AppSnackbar.showWarning('Tombol $mode sudah ditekan, mohon tunggu.');
        return;
      }
      _isNavigatingToReport = true;
      try {
        // Pencegatan "belum waktunya": WO lembur tidak boleh dimulai sebelum
        // jadwal (assignment.tanggal_mulai). Hanya untuk aksi yang MEMULAI
        // kerja (Mulai/Inspeksi); Progress/Selesai sudah terlanjur mulai.
        if (mode == 'Mulai' || mode == 'Inspeksi') {
          final DateTime? rawStart =
              _workOrder?.assignment?.startDateTime ??
              _workOrder?.startDateTime;
          if (rawStart != null) {
            // startDateTime di-parse tanpa toLocal() (lihat work_order_model),
            // bisa ber-flag UTC → normalisasi dulu sebelum dibandingkan.
            final DateTime scheduledStart = rawStart.isUtc
                ? rawStart.toLocal()
                : rawStart;
            if (DateTime.now().isBefore(scheduledStart)) {
              await _showBelumWaktunyaReminder(scheduledStart);
              return;
            }
          }
        }

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
            builder: (_) => WorkOrderReportPageLembur(
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
              scheduledStart:
                  _workOrder?.assignment?.startDateTime ??
                  _workOrder?.startDateTime,
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
