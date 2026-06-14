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

import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/inventory/peminjaman_item_list.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_lembur/work_order_report_page_lembur.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_keluar/detail_work_order_keluar/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/progress_card.dart';
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
    this.radiusMeter = 100,
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
    _fetchProgresses();
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

          if (widget.isAssignee && !hasInspeksi && !hasMulai)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: _buildActionButton('Inspeksi'),
              ),
            ),
          if (widget.isAssignee && hasInspeksi && !hasMulai)
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

          if (widget.isAssignee && hasMulai && !hasSelesai) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildActionButton('Selesai')),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton('Laporan')),
              ],
            ),
          ],
          if (widget.isAssignee &&
              hasSelesai &&
              (widget.status == WorkOrderStatusId.pengecekan ||
                  widget.status == WorkOrderStatusId.selesai)) ...[
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
                  status: widget.status,
                  isAssignee: widget.isAssignee,
                  progressId: progress.id,
                  workOrderId: widget.workOrderId,
                  workOrderTypeId: widget.workOrderTypeId,
                  lngLat: widget.lngLat,
                  locationName: widget.locationName,
                  radiusMeter: widget.radiusMeter,
                  kategoriForm: widget.kategoriForm,
                  initialKategoriData: _workOrder != null
                      ? _buildKategoriFormData(_workOrder!)
                      : null,
                  initialDescription: progress.description,
                ),
              ),
            );
            if (shouldRefresh == true && mounted) {
              _handleRefresh();
            }
          },
        ),
        if (progress.canCancel && widget.isAssignee)
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
    final String reportMode = mode == 'Laporan' ? 'Progress' : mode;

    Future<void> handleTap() async {
      if (disabled) return;
      if (_isNavigatingToReport) {
        AppSnackbar.showWarning('Tombol $mode sudah ditekan, mohon tunggu.');
        return;
      }
      _isNavigatingToReport = true;
      try {
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
            builder: (_) => WorkOrderReportPageLembur(
              mode: reportMode,
              status: widget.status,
              isAssignee: widget.isAssignee,
              progressId: null,
              workOrderId: widget.workOrderId,
              workOrderTypeId: widget.workOrderTypeId,
              lngLat: widget.lngLat,
              locationName: widget.locationName,
              radiusMeter: widget.radiusMeter,
              kategoriForm: widget.kategoriForm,
              initialKategoriData: _workOrder != null
                  ? _buildKategoriFormData(_workOrder!)
                  : null,
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
