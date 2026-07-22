import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/config/form_fields_config.dart';
import 'package:project_mobile_pdam/config/theme/dynamic_form_config.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/seed/maps_seed_model.dart';
import 'package:project_mobile_pdam/core/services/geofence_service.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/core/widget/custom_field_widgets.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/core/widget/custom_scroll_refresh.dart';
import 'package:project_mobile_pdam/core/widget/dynamic_form_builder.dart';
import 'package:project_mobile_pdam/core/widget/image_picker.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_progress_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/option_form_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_detail_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/core/constants/tahapan_labels.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/journal_draft_cubit.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

class WorkOrderReportPage extends StatefulWidget {
  final String mode;
  final int? status;
  final bool isAssignee;
  final int? progressId;
  final int? workOrderId;
  final int? workOrderTypeId;
  final LatLng? lngLat;
  final String? locationName; // Nama lokasi dari MasterLocation
  final int radiusMeter; // Radius dari MasterLocation untuk pengecekan jarak
  final String? kategoriForm;
  final Map<String, dynamic>? initialKategoriData;
  final String? initialDescription;
  final String? workOrderTypeName;

  /// Prioritas WO (mis. 'urgent'). Dipakai untuk pengecualian cutoff jam upload
  /// laporan: WO Urgent boleh upload kapan saja, selain itu dibatasi ≤ 16:00.
  final String? prioritas;

  /// Tahap tertinggi yang sudah tersubmit pada WO ini, dihitung pemanggil dari
  /// daftar progress (andal). Dipakai untuk memandu pilihan tahapan di selector.
  /// `null`/0 = tidak diketahui → selector tidak membatasi (BE tetap menjaga).
  final int? currentTahapanTertinggi;

  const WorkOrderReportPage({
    super.key,
    required this.mode,
    this.status,
    this.isAssignee = false,
    required this.progressId,
    this.workOrderId,
    this.workOrderTypeId,
    this.lngLat,
    this.locationName,
    this.radiusMeter = MapsSeedModel
        .defaultRadiusMeter, // Default dari MapsSeedModel bila tidak ada
    this.kategoriForm,
    this.initialKategoriData,
    this.initialDescription,
    this.workOrderTypeName,
    this.prioritas,
    this.currentTahapanTertinggi,
  });

  @override
  State<WorkOrderReportPage> createState() => _WorkOrderReportPageState();
}

class _WorkOrderReportPageState extends AppStatePage<WorkOrderReportPage> {
  late WorkOrderBloc _workOrderBloc;
  late JournalDraftCubit _journalDraftCubit;
  bool get isDetailMode =>
      widget.status == 5 || widget.status == 6 || !widget.isAssignee;
  bool get isRejected =>
      _progressStatusId != null &&
      ProgressStatusId.isRevisiRequested(_progressStatusId);

  bool get _isAlreadyRecorded =>
      widget.isAssignee && widget.progressId != null && !isRejected;

  /// Geofence hanya digate untuk staff yang sedang menyubmit progress dan WO
  /// punya titik lokasi. Mode review/detail (SPV) atau WO tanpa titik tidak
  /// digate.
  bool get _shouldGateGeofence =>
      widget.isAssignee && widget.lngLat != null && !isDetailMode;

  String get _submitInProgressMessage {
    switch (widget.mode) {
      case 'Mulai':
        return 'Tombol Mulai sudah pernah ditekan, mohon tunggu.';
      case 'Selesai':
        return 'Tombol Selesai sudah pernah ditekan, mohon tunggu.';
      default:
        return 'Tombol Laporan sudah pernah ditekan, mohon tunggu.';
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  Map<String, dynamic> _formData = {};
  List<ProgressDetailEntity> _progressDetails = [];
  List<dynamic> _images = [];
  int? _progressStatusId;
  String? _revisionNote;
  bool _isCheckingDistance = true;
  bool isDataLoaded = false;
  bool _isSubmitting = false;
  bool _hasClosedAfterSubmit = false;
  bool _requestedHeaderFallback = false;
  Position? _currentPosition;
  final GeofenceService _geofence = sl<GeofenceService>();

  /// Status geofence untuk banner UX. `_geoStatus` null = belum/ gagal cek.
  GeofenceStatus? _geoStatus;
  bool _poorAccuracy = false;
  String? _geoStatusError;
  int? _selectedTahapan;

  String get _draftKey => '${widget.workOrderId}_${widget.mode}';

  // Simulasi JSON form dinamis (sementara hardcoded)

  @override
  void initState() {
    super.initState();
    _workOrderBloc = context.read<WorkOrderBloc>();
    _journalDraftCubit = context.read<JournalDraftCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  /// Menginisialisasi data setelah frame pertama selesai render
  void _initializeData() {
    if (!mounted) return;

    final draft = _journalDraftCubit.getDraft(_draftKey);
    if (draft != null) {
      _descriptionController.text = draft.description;
      _images = List.from(draft.images);
      _formData = Map.from(draft.formData);
      if (_formData.containsKey('tahapan')) {
        _selectedTahapan = int.tryParse(_formData['tahapan'].toString());
      }
    } else if (widget.initialKategoriData != null) {
      final init = widget.initialKategoriData!;
      dynamic pick(List<String> keys) {
        for (final k in keys) {
          if (init.containsKey(k) && init[k] != null) return init[k];
        }
        return null;
      }

      _formData = {
        if (widget.initialKategoriData!.containsKey('kondisiAwal'))
          'kondisi_awal': widget.initialKategoriData!['kondisiAwal'],
        if (widget.initialKategoriData!.containsKey('kondisi_awal'))
          'kondisi_awal': widget.initialKategoriData!['kondisi_awal'],
        if (widget.initialKategoriData!.containsKey('tindakan_perbaikan'))
          'tindakan_perbaikan':
              widget.initialKategoriData!['tindakan_perbaikan'],
        if (widget.initialKategoriData!.containsKey('hasil_inspeksi'))
          'hasil_inspeksi': widget.initialKategoriData!['hasil_inspeksi'],
        if (widget.initialKategoriData!.containsKey('kondisi_akhir'))
          'kondisi_akhir': widget.initialKategoriData!['kondisi_akhir'],
        if (widget.initialKategoriData!.containsKey('jadwal_pemeliharaan'))
          'jadwal_pemeliharaan':
              widget.initialKategoriData!['jadwal_pemeliharaan'] is String
              ? DateTime.tryParse(
                  widget.initialKategoriData!['jadwal_pemeliharaan'],
                )
              : widget.initialKategoriData!['jadwal_pemeliharaan'],
        if (widget.initialKategoriData!.containsKey('tindakan'))
          'tindakan': widget.initialKategoriData!['tindakan'],
        if (widget.initialKategoriData!.containsKey('kondisi_meter_akhir'))
          'kondisi_meter_akhir':
              widget.initialKategoriData!['kondisi_meter_akhir'],
        if (widget.initialKategoriData!.containsKey('hasil_kalibrasi'))
          'hasil_kalibrasi': widget.initialKategoriData!['hasil_kalibrasi'],
        // Field kategori "awal" (diisi staff saat Mulai). Sumber bisa
        // camelCase (dari detail work order) atau snake_case (dari draft).
        // Normalisasi ke snake_case agar cocok dengan getStartKategoriFields.
        if (pick(['jenis_pipa', 'jenisPipa']) != null)
          'jenis_pipa': pick(['jenis_pipa', 'jenisPipa']),
        if (pick(['diameter_pipa', 'diameterPipa']) != null)
          'diameter_pipa': pick(['diameter_pipa', 'diameterPipa'])?.toString(),
        if (pick(['panjang_pipa', 'panjangPipa']) != null)
          'panjang_pipa': pick(['panjang_pipa', 'panjangPipa'])?.toString(),
        if (pick(['tingkat_kerusakan', 'tingkatKerusakan']) != null)
          'tingkat_kerusakan': pick(['tingkat_kerusakan', 'tingkatKerusakan']),
        if (pick(['nama_aset', 'namaAset']) != null)
          'nama_aset': pick(['nama_aset', 'namaAset']),
        if (pick(['jenis_aset', 'jenisAset']) != null)
          'jenis_aset': pick(['jenis_aset', 'jenisAset']),
        if (pick(['kapasitas']) != null)
          'kapasitas': pick(['kapasitas'])?.toString(),
        if (pick(['nomor_meter', 'nomorMeter']) != null)
          'nomor_meter': pick(['nomor_meter', 'nomorMeter']),
        if (pick(['kondisi_meter_awal', 'kondisiMeterAwal']) != null)
          'kondisi_meter_awal': pick([
            'kondisi_meter_awal',
            'kondisiMeterAwal',
          ]),
      };
    }

    if (_selectedTahapan == null) {
      if (widget.mode == 'Inspeksi' || widget.mode == 'Mulai') {
        _selectedTahapan = 1;
      } else if (widget.mode == 'Selesai') {
        _selectedTahapan = 4;
      } else if (widget.mode == 'Progress') {
        final state = _workOrderBloc.state;
        if (state is WorkOrderDetailLoaded) {
          int tahapan = state.workOrder.tahapanTertinggi ?? 1;
          if (tahapan < 2) tahapan = 2;
          if (tahapan > 3) tahapan = 3;
          _selectedTahapan = tahapan;
        } else {
          _selectedTahapan = 2;
        }
      }
      if (_selectedTahapan != null) {
        _formData['tahapan'] = _selectedTahapan;
      }
    }

    if (widget.progressId == null) {
      if (widget.mode == 'Selesai') {
        setState(() {
          _progressDetails = [];
          isDataLoaded = true;
          _isCheckingDistance = _shouldGateGeofence;
        });
        if (_shouldGateGeofence) _checkDistance();
        return;
      }

      setState(() {
        isDataLoaded = true;
        _isCheckingDistance = _shouldGateGeofence;
      });
      if (_shouldGateGeofence) _checkDistance();
      return;
    }

    if (widget.progressId != null && widget.isAssignee) {
      _fetchRevisionNote();
    }

    // Dispatch BLoC event untuk mengambil data
    if (widget.mode == 'Selesai') {
      _workOrderBloc.add(GetProgressDetailsEvent(widget.progressId!));
    } else {
      _workOrderBloc.add(GetWorkOrderProgressDetailEvent(widget.progressId!));
    }

    if (_shouldGateGeofence) {
      _checkDistance();
    } else {
      setState(() {
        _isCheckingDistance = false;
      });
    }
  }

  /// Muat ulang data form via pull-to-refresh. Isian yang sedang diketik
  /// disimpan dulu sebagai draft supaya listener BLoC me-restore-nya setelah
  /// data baru masuk — refresh tidak boleh menghapus input user.
  Future<void> _onRefresh() async {
    if (!isDetailMode && !_isAlreadyRecorded) {
      _journalDraftCubit.saveDraft(
        _draftKey,
        JournalDraft(
          description: _descriptionController.text,
          images: _images,
          formData: _formData,
        ),
      );
    }

    if (widget.progressId != null) {
      if (widget.isAssignee) _fetchRevisionNote();
      // Await state hasil fetch agar spinner RefreshIndicator berputar selama
      // loading berlangsung, bukan langsung hilang.
      final done = _workOrderBloc.stream
          .firstWhere(
            (state) =>
                state is WorkOrderProgressDetailLoaded ||
                state is ProgressDetailsLoaded ||
                state is WorkOrderError,
          )
          .timeout(const Duration(seconds: 10));
      if (widget.mode == 'Selesai') {
        _workOrderBloc.add(GetProgressDetailsEvent(widget.progressId!));
      } else {
        _workOrderBloc.add(GetWorkOrderProgressDetailEvent(widget.progressId!));
      }
      try {
        await done;
      } on TimeoutException {
        // Respons lambat — listener tetap memproses bila data datang belakangan.
      }
    }

    if (_shouldGateGeofence) {
      await _checkDistance(preferFresh: true);
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  void _checkDataLoaded() {
    // Removed nested setState - this method is now only for logging
    if (_progressDetails.isNotEmpty) {
      debugPrint("✅ Data loaded: $_progressDetails");
      debugPrint("Value : ${_progressDetails.first.value}");
      debugPrint(
        "Description: ${_progressDetails.first.workOrderProgress?.description}",
      );
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Form Jurnal"),
      body: BlocListener<WorkOrderBloc, WorkOrderState>(
        listener: (context, state) {
          if (state is WorkOrderProgressDetailLoaded) {
            // Proses data di luar setState
            final description = state.progress.description?.isNotEmpty == true
                ? state.progress.description!
                : (widget.initialDescription ?? '');
            final statusId = state.progress.statusId;
            final tahapan = state.progress.tahapan;
            final images = (state.progress.documentation ?? [])
                .map((doc) => doc.url)
                .where((urlValue) => urlValue != null && urlValue.isNotEmpty)
                .cast<dynamic>()
                .toList();

            // Schedule setState setelah frame selesai untuk menghindari blocking
            final draft = _journalDraftCubit.getDraft(_draftKey);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                if (draft != null && !isDetailMode) {
                  _descriptionController.text = draft.description;
                  _images = List.from(draft.images);
                } else {
                  _descriptionController.text = description;
                  _images = images;
                  if (state.progress.kategoriData != null) {
                    _formData.addAll(state.progress.kategoriData!);
                  }
                  if (tahapan != null) {
                    _selectedTahapan = tahapan;
                  } else if (_workOrderBloc.state is WorkOrderDetailLoaded) {
                    _selectedTahapan =
                        (_workOrderBloc.state as WorkOrderDetailLoaded)
                            .workOrder
                            .tahapanTertinggi ??
                        1;
                  } else {
                    _selectedTahapan = 1;
                  }
                  _formData['tahapan'] = _selectedTahapan;
                }
                _progressStatusId = statusId;
                _requestedHeaderFallback = false;
                isDataLoaded = true;
              });
            });
          }
          if (state is ProgressDetailsLoaded) {
            // Proses data di luar setState untuk menghindari blocking UI
            final progressDetails = state.progressDetails;

            // 🔒 Safety check: Handle empty list to prevent "Bad state: No element" error
            if (progressDetails.isEmpty) {
              debugPrint("⚠️ ProgressDetails kosong, skip processing");
              if (widget.mode == 'Selesai' &&
                  widget.progressId != null &&
                  !_requestedHeaderFallback) {
                _requestedHeaderFallback = true;
                _workOrderBloc.add(
                  GetWorkOrderProgressDetailEvent(widget.progressId!),
                );
              }
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _progressDetails = [];

                  isDataLoaded = widget.mode == 'Selesai' ? false : true;
                });
              });
              return;
            }

            final rawDesc =
                progressDetails.first.workOrderProgress?.description;
            final description = rawDesc?.isNotEmpty == true
                ? rawDesc!
                : (widget.initialDescription ?? '');
            final statusId = progressDetails.first.workOrderProgress?.statusId;
            final tahapan = progressDetails.first.workOrderProgress?.tahapan;

            final images =
                progressDetails.first.workOrderProgress?.documentation
                    ?.map((doc) => doc.url)
                    .where(
                      (urlValue) => urlValue != null && urlValue.isNotEmpty,
                    )
                    .cast<dynamic>()
                    .toList() ??
                [];

            // Hitung formData di luar setState
            final formData = <String, dynamic>{};
            for (var detail in progressDetails) {
              final key = (detail.form?.id ?? detail.detailFormId ?? detail.id)
                  ?.toString();
              if (key == null) continue;
              formData[key] = isDetailMode
                  ? detail.value
                  : _getOptionIdFromValue(detail);
            }

            // kategori_data (tindakan_perbaikan, hasil_inspeksi, dll) tersimpan
            // terpisah dari progress_detail. Tanpa merge ini, field kategori
            // pada form Selesai (jaringan/infrastruktur/meter) tidak terisi.
            final kategoriData =
                progressDetails.first.workOrderProgress?.kategoriData;

            // Schedule setState setelah frame selesai untuk menghindari blocking
            final draft = _journalDraftCubit.getDraft(_draftKey);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _progressDetails = progressDetails;
                if (draft != null && !isDetailMode) {
                  _descriptionController.text = draft.description;
                  _formData = Map.from(draft.formData);
                  _images = List.from(draft.images);
                } else {
                  _descriptionController.text = description;
                  _formData = formData;
                  if (kategoriData != null) {
                    _formData.addAll(kategoriData);
                  }
                  _images = images;
                  if (tahapan != null) {
                    _selectedTahapan = tahapan;
                  } else if (_workOrderBloc.state is WorkOrderDetailLoaded) {
                    _selectedTahapan =
                        (_workOrderBloc.state as WorkOrderDetailLoaded)
                            .workOrder
                            .tahapanTertinggi ??
                        1;
                  } else {
                    _selectedTahapan = 1;
                  }
                  _formData['tahapan'] = _selectedTahapan;
                }
                _progressStatusId = statusId;
                isDataLoaded = true;
              });
              _checkDataLoaded();
            });
          }
          if (state is WorkOrderProgressUpdated) {
            if (_hasClosedAfterSubmit) return;
            _hasClosedAfterSubmit = true;
            if ((widget.isAssignee && !isDetailMode) || !widget.isAssignee) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _journalDraftCubit.clearDraft(_draftKey);
                final route = ModalRoute.of(context);
                if (route != null &&
                    route.isActive &&
                    route.isCurrent &&
                    Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
                // Toast SETELAH pop: Flushbar tampil via route push; kalau
                // dipanggil sebelum pop, route-nya merebut posisi teratas
                // sehingga guard route.isCurrent gagal dan pop di-skip (form
                // "nyangkut", tanpa refresh). AppSnackbar memakai
                // scaffoldMessengerKeys global, jadi tetap tampil di halaman
                // detail setelah form ditutup.
                AppSnackbar.showSuccess("Form berhasil disubmit.");
              });
            } else {
              // Cabang tak-pop (praktis tak terjangkau) tetap memberi
              // konfirmasi.
              AppSnackbar.showSuccess("Form berhasil disubmit.");
            }
          }
          if (state is WorkOrderError) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
            }
            AppSnackbar.showError(state.message);
          }
        },
        child: BlocBuilder<WorkOrderBloc, WorkOrderState>(
          builder: (context, state) {
            final bool isSelesaiResubmit =
                isRejected && widget.mode == 'Selesai';
            final bool isSeniorStaff =
                AuthStorage.getJabatanKodeSync() == 'SENIOR_STAFF';
            final bool canShowResubmitButton =
                !isSelesaiResubmit || isSeniorStaff;
            final bool isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';
            final bool isWorkOrderClosed =
                widget.status == WorkOrderStatusId.selesai;

            String? jenisPekerjaan = widget.workOrderTypeName;
            if (jenisPekerjaan == null && widget.workOrderTypeId != null) {
              jenisPekerjaan = kJenisWorkOrderIdToName[widget.workOrderTypeId];
            }

            String? katForm = widget.kategoriForm;
            if (state is WorkOrderDetailLoaded) {
              jenisPekerjaan ??= state.workOrder.workOrderType?.name;
              katForm ??= state.workOrder.kategoriForm;
            }

            // Fallback to determine specific label if jenisPekerjaan is missing or unknown
            if (jenisPekerjaan == null ||
                !kTahapanByJenis.containsKey(jenisPekerjaan)) {
              if (katForm == 'meter') {
                jenisPekerjaan = 'Kalibrasi Meteran';
              } else if (katForm == 'jaringan') {
                jenisPekerjaan = 'Penanganan Kebocoran';
              } else if (katForm == 'infrastruktur') {
                jenisPekerjaan = 'Pemeliharaan Pompa';
              }
            }

            final List<String> specificLabels = tahapanLabelsFor(
              jenisPekerjaan,
            );
            final String specificLabel =
                specificLabels.isNotEmpty &&
                    _selectedTahapan != null &&
                    _selectedTahapan! > 0 &&
                    _selectedTahapan! <= specificLabels.length
                ? specificLabels[_selectedTahapan! - 1]
                : "Persiapan";

            // Spinner penuh hanya saat memuat data; pengecekan geofence
            // ditampilkan via banner agar form tetap terlihat (mis. tombol
            // "Periksa ulang" tidak menghilang).
            return !isDataLoaded
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          "Memuat data...",
                          style: textTheme.titleLarge?.copyWith(
                            color: color.primary[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollRefreshWidget(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      // Tetap bisa di-swipe walau konten lebih pendek dari
                      // layar — syarat gesture pull-to-refresh.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (widget.lngLat != null) _buildLocationMap(),
                            if (_shouldGateGeofence) ...[
                              const SizedBox(height: 8),
                              _buildGeofenceStatus(),
                            ],
                            const SizedBox(height: 16),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                key: ValueKey(specificLabel),
                                initialValue: specificLabel,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: "Target Pekerjaan",
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            if (isRejected && _revisionNote != null) ...[
                              _buildRevisionNotePanel(),
                              const SizedBox(height: 16),
                            ],
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: color.foreground[400]!,
                                ),
                              ),
                              child: Column(
                                spacing: 8,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomForm(
                                    labelText: "Deskripsi",
                                    hintText: "Masukkan deskripsi pekerjaan",
                                    maxLines: 5,
                                    controller: _descriptionController,
                                    readOnly:
                                        isDetailMode || _isAlreadyRecorded,
                                  ),
                                  Text(
                                    "Dokumentasi",
                                    style: textTheme.titleLarge,
                                  ),
                                  ImagePickerField(
                                    initialImages: _images,
                                    enabled:
                                        !isDetailMode && !_isAlreadyRecorded,
                                    onChanged: (newImages) {
                                      setState(() {
                                        _images = newImages;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTahapanSelector(),
                            const SizedBox(height: 16),
                            if (widget.mode == 'Selesai' ||
                                widget.mode == 'Mulai')
                              _buildDynamicForm(),
                            const SizedBox(height: 24),
                            widget.isAssignee && !isDetailMode
                                ? (_isAlreadyRecorded
                                      ? _buildAlreadyRecordedBanner()
                                      : (!canShowResubmitButton
                                            ? _buildOnlySeniorStaffBanner()
                                            : ElevatedButton(
                                                // Pertahankan warna tombol saat
                                                // disabled (sedang submit) agar
                                                // spinner tetap kontras — default
                                                // disabled Material = abu-abu.
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _getColor(),
                                                  disabledBackgroundColor:
                                                      _getColor(),
                                                ),
                                                onPressed: _isSubmitting
                                                    ? null
                                                    : _onSubmit,
                                                child: _isSubmitting
                                                    ? SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(
                                                                widget.mode ==
                                                                        'Selesai'
                                                                    ? color
                                                                          .foreground[100]!
                                                                    : color
                                                                          .primary[500]!,
                                                              ),
                                                        ),
                                                      )
                                                    : Text(
                                                        isRejected
                                                            ? 'Kerjakan Revisi'
                                                            : widget.mode,
                                                        style: textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              color:
                                                                  widget.mode ==
                                                                      'Selesai'
                                                                  ? color
                                                                        .foreground[100]
                                                                  : color
                                                                        .primary[500],
                                                            ),
                                                      ),
                                              )))
                                : widget.isAssignee && isRejected
                                ? const SizedBox()
                                : widget.mode == 'Selesai' &&
                                      !widget.isAssignee &&
                                      isSpv &&
                                      !isWorkOrderClosed &&
                                      ProgressStatusId.isSubmitted(
                                        _progressStatusId,
                                      )
                                ? Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color.danger,
                                          ),
                                          onPressed: _isSubmitting
                                              ? null
                                              : _showRevisionDialog,
                                          child: const Text('Revisi'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color.status[2],
                                            disabledBackgroundColor:
                                                color.status[2],
                                          ),
                                          onPressed: _isSubmitting
                                              ? null
                                              : () => _onReview('accept'),
                                          child: _isSubmitting
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFF000080)),
                                                  ),
                                                )
                                              : const Text(
                                                  'Terima',
                                                  style: TextStyle(
                                                    color: Color(0xFF000080),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildDynamicForm() {
    final List<Map<String, dynamic>> dynamicFields;
    if (widget.kategoriForm != null) {
      if (widget.mode == 'Mulai') {
        dynamicFields = FormFieldsConfig.getStartKategoriFields(
          kategoriForm: widget.kategoriForm,
          isReadOnly: isDetailMode || _isAlreadyRecorded,
        );
      } else if (widget.mode == 'Selesai') {
        dynamicFields = FormFieldsConfig.getSubmissionFields(
          kategoriForm: widget.kategoriForm,
          isReadOnly: isDetailMode || _isAlreadyRecorded,
        );
      } else {
        dynamicFields = [];
      }
    } else {
      dynamicFields = (isDetailMode || !widget.isAssignee)
          ? DynamicFormConfig.getDetailDynamicFormFields(
              details: _progressDetails,
              isDetailMode: isDetailMode,
            )
          : DynamicFormConfig.getDynamicFormFields(details: _progressDetails);
    }
    debugPrint("🔍 detail mode: $isDetailMode");
    return DynamicFormBuilder(
      fields: dynamicFields,
      formData: _formData,
      onFieldChanged: _onFieldChanged,
      customWidgets: CustomFieldWidgets.fields,
      readOnly: false,
    );
  }

  Widget _buildTahapanSelector() {
    String? jenisPekerjaan = widget.workOrderTypeName;
    bool isPic = true;

    final state = _workOrderBloc.state;
    if (state is WorkOrderDetailLoaded) {
      jenisPekerjaan ??= state.workOrder.workOrderType?.name;

      final currentUser = AuthStorage.getUserSync();
      final currentPegawaiIdStr = currentUser?['pegawai_id']?.toString();
      final picPegawaiIdStr = state.workOrder.assignment?.assignee?.id
          ?.toString();

      if (picPegawaiIdStr != null && currentPegawaiIdStr != null) {
        isPic = currentPegawaiIdStr == picPegawaiIdStr;
      }
    }

    // Tahap tertinggi yang sudah tersubmit. Sumber utama: param dari pemanggil
    // (dihitung dari daftar progress — andal). Fallback ke entity bila ada.
    // Detail WO dari BE TIDAK mengembalikan `tahapan_tertinggi`, jadi entity
    // biasanya null; karenanya param dari detail page yang jadi acuan.
    final int? entityTahapan = state is WorkOrderDetailLoaded
        ? state.workOrder.tahapanTertinggi
        : null;
    final int tahapanTertinggi =
        widget.currentTahapanTertinggi ?? entityTahapan ?? 0;
    // Bila tahap tidak diketahui (0), selector tidak membatasi pilihan — biarkan
    // BE (rejectIfTahapanInvalid) yang menolak urutan yang salah.
    final bool knowTahapan = tahapanTertinggi > 0;

    List<int> validTahapan = [1, 2, 3, 4];
    if (widget.mode == 'Inspeksi' || widget.mode == 'Mulai') {
      validTahapan = [1];
    } else if (widget.mode == 'Progress') {
      validTahapan = [TahapanWorkorder.pengerjaan, TahapanWorkorder.pengujian];
    } else if (widget.mode == 'Selesai') {
      validTahapan = [TahapanWorkorder.dokumentasi];
    }

    // Tahap berikut yang boleh dimajukan PIC: maju satu langkah, maksimal 3
    // (Pengujian). Tahap 4 (Dokumentasi) hanya lewat mode "Selesai".
    final int nextStage = (tahapanTertinggi + 1).clamp(
      1,
      TahapanWorkorder.maxProgress,
    );

    // Aturan enable/disable opsi tahapan (hanya saat tahap diketahui):
    // - Mode selain Progress: pertahankan perilaku lama (hanya 1 opsi valid).
    // - Mode Progress + PIC: hanya boleh lapor tahap berjalan atau maju satu
    //   langkah (cegah lompat & mundur — Bug 1 & 2).
    // - Mode Progress + non-PIC: tetap tidak boleh memajukan tahap.
    bool isStageDisabled(int val) {
      if (!knowTahapan) return false;
      if (widget.mode != 'Progress') {
        return !isPic && val > tahapanTertinggi;
      }
      if (isPic) {
        return val < tahapanTertinggi || val > nextStage;
      }
      return val > tahapanTertinggi;
    }

    // Default aman: untuk Progress arahkan ke tahap berikut yang valid;
    // selain itu opsi pertama. Reset bila pilihan saat ini tidak valid/disabled.
    int defaultTahapan = validTahapan.first;
    if (widget.mode == 'Progress' && knowTahapan) {
      final int desired = isPic ? nextStage : tahapanTertinggi;
      defaultTahapan = validTahapan.contains(desired)
          ? desired
          : validTahapan.first;
    }
    if (_selectedTahapan == null ||
        !validTahapan.contains(_selectedTahapan) ||
        isStageDisabled(_selectedTahapan!)) {
      _selectedTahapan = defaultTahapan;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.foreground[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tahapan Pekerjaan", style: textTheme.titleMedium),
          if (widget.mode == 'Progress') ...[
            const SizedBox(height: 4),
            Text(
              knowTahapan
                  ? "Tahap berjalan: $tahapanTertinggi - ${kTahapanGeneric[(tahapanTertinggi - 1).clamp(0, 3)]}. "
                        "Tahapan harus berurutan; tidak bisa melompati atau mengulang tahap yang sudah lewat."
                  : "Tahapan harus berurutan; tidak bisa melompati atau mengulang tahap yang sudah lewat.",
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
          if (!isPic) ...[
            const SizedBox(height: 4),
            Text(
              "Pilih tahapan pekerjaan. Hanya koordinator (PIC) yang dapat memajukan tahapan.",
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedTahapan,
            hint: const Text('Pilih tahapan... (Opsional)'),
            items: validTahapan.map((val) {
              final index = val - 1;
              final isDisabled = isStageDisabled(val);
              return DropdownMenuItem<int>(
                value: val,
                enabled: !isDisabled,
                child: Text(
                  '$val - ${kTahapanGeneric[index]}',
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: isDetailMode || _isAlreadyRecorded
                ? null
                : (value) {
                    setState(() {
                      _selectedTahapan = value;
                      _formData['tahapan'] = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan map lokasi work order
  Widget _buildLocationMap() {
    final location = widget.lngLat!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google Maps
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 165,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: location, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('wo_location'),
                  position: location,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
                // Posisi perangkat (bila sudah dicek) — membantu staff melihat
                // di mana GPS menaruh mereka relatif ke titik WO.
                if (_currentPosition != null)
                  Marker(
                    markerId: const MarkerId('device_location'),
                    position: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: 'Posisi Anda'),
                  ),
              },
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              liteModeEnabled: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Info lokasi
        Text(
          widget.locationName ?? "Lokasi Work Order",
          style: textTheme.titleMedium?.copyWith(
            color: color.primary[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        // Text(
        //   "Long ${location.longitude.toStringAsFixed(6)}  Lat ${location.latitude.toStringAsFixed(6)}",
        //   style: textTheme.bodySmall?.copyWith(color: color.foreground[600]),
        // ),
      ],
    );
  }

  Color? _getColor() {
    switch (widget.mode) {
      case 'Mulai':
        return color.status[2];
      // case 'progress':
      //   return color.control;
      case 'Selesai':
        return color.primary[500];
      default:
        return color.control;
    }
  }

  Widget _buildAlreadyRecordedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.primary[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.primary[500]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: color.primary[500], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Laporan sudah tercatat dan tidak dapat diubah.',
              style: textTheme.bodyMedium?.copyWith(
                color: color.foreground[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit() async {
    if (_isSubmitting) {
      AppSnackbar.showWarning(_submitInProgressMessage);
      return;
    }
    if (_isAlreadyRecorded) {
      AppSnackbar.showWarning('Laporan sudah tercatat dan tidak dapat diubah.');
      return;
    }
    // Cutoff jam upload laporan WO reguler: di atas 16:00 tidak boleh upload,
    // kecuali prioritas Urgent. Mengikuti pola gate assignment 09:00–16:00 di
    // detail_work_order_page.dart. WO lembur tidak melewati halaman ini.
    final bool isUrgent = (widget.prioritas ?? '').toLowerCase() == 'urgent';
    if (!isUrgent) {
      final TimeOfDay now = TimeOfDay.now();
      const int batasMenit = 16 * 60; // 16:00
      if (now.hour * 60 + now.minute > batasMenit) {
        AppSnackbar.showError(
          'Upload laporan hanya dapat dilakukan sampai pukul 16:00.',
        );
        return;
      }
    }
    // Urutan tahapan (skip/mundur/Selesai sebelum Pengujian) ditegakkan oleh BE
    // `ProgressWorkorderController::rejectIfTahapanInvalid` — error 422-nya
    // tampil via snackbar. Selector di atas sudah mencegah pilihan tak valid
    // saat tahap diketahui; tombol "Selesai" juga digate di detail page.
    if (_formKey.currentState!.validate()) {
      if (_descriptionController.text.isEmpty) {
        AppSnackbar.showError("Deskripsi tidak boleh kosong.");
        return;
      }
      if (_images.isEmpty && widget.mode != 'Mulai') {
        AppSnackbar.showError("Minimal satu foto diperlukan.");
        return;
      }

      // Validate photo size (<= 2048 KB)
      for (final photo in _images) {
        if (photo is XFile) {
          final size = await File(photo.path).length();
          if (size > 2048 * 1024) {
            AppSnackbar.showError("Ukuran foto '${photo.name}' melebihi 2MB.");
            return;
          }
        }
      }

      if (widget.mode == 'Mulai') {
        final category = widget.kategoriForm;
        if (category == 'jaringan') {
          if ((_formData['jenis_pipa'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Jenis Pipa tidak boleh kosong.");
            return;
          }
          if ((_formData['diameter_pipa'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Diameter Pipa tidak boleh kosong.");
            return;
          }
          if (double.tryParse(
                (_formData['diameter_pipa'] ?? '').toString().trim(),
              ) ==
              null) {
            AppSnackbar.showError("Diameter Pipa harus berupa angka.");
            return;
          }
          if ((_formData['panjang_pipa'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Panjang Pipa tidak boleh kosong.");
            return;
          }
          if ((_formData['tingkat_kerusakan'] ?? '')
              .toString()
              .trim()
              .isEmpty) {
            AppSnackbar.showError("Tingkat Kerusakan tidak boleh kosong.");
            return;
          }
        } else if (category == 'infrastruktur') {
          if ((_formData['nama_aset'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Nama Aset tidak boleh kosong.");
            return;
          }
          if ((_formData['jenis_aset'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Jenis Aset tidak boleh kosong.");
            return;
          }
          if ((_formData['kapasitas'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Kapasitas tidak boleh kosong.");
            return;
          }
          if ((_formData['kondisi_awal'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Kondisi Awal tidak boleh kosong.");
            return;
          }
        } else if (category == 'meter') {
          if ((_formData['nomor_meter'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Nomor Meter tidak boleh kosong.");
            return;
          }
          if ((_formData['kondisi_meter_awal'] ?? '')
              .toString()
              .trim()
              .isEmpty) {
            AppSnackbar.showError("Kondisi Meter Awal tidak boleh kosong.");
            return;
          }
        }
      }

      if (widget.mode == 'Selesai') {
        final category = widget.kategoriForm;
        if (category == 'jaringan') {
          if ((_formData['tindakan_perbaikan'] ?? '')
              .toString()
              .trim()
              .isEmpty) {
            AppSnackbar.showError("Tindakan Perbaikan tidak boleh kosong.");
            return;
          }
          if ((_formData['hasil_inspeksi'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Hasil Inspeksi tidak boleh kosong.");
            return;
          }
        } else if (category == 'infrastruktur') {
          if ((_formData['kondisi_akhir'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Kondisi Akhir tidak boleh kosong.");
            return;
          }
          if (_formData['jadwal_pemeliharaan'] == null) {
            AppSnackbar.showError("Jadwal Pemeliharaan tidak boleh kosong.");
            return;
          }
          if ((_formData['tindakan'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Tindakan tidak boleh kosong.");
            return;
          }
        } else if (category == 'meter') {
          if ((_formData['kondisi_meter_akhir'] ?? '')
              .toString()
              .trim()
              .isEmpty) {
            AppSnackbar.showError("Kondisi Meter Akhir tidak boleh kosong.");
            return;
          }
          if ((_formData['hasil_kalibrasi'] ?? '').toString().trim().isEmpty) {
            AppSnackbar.showError("Hasil Kalibrasi tidak boleh kosong.");
            return;
          }
        }
      }

      setState(() {
        _isSubmitting = true;
        _hasClosedAfterSubmit = false;
      });

      // === Geofence gate ===
      // Ambil posisi SEGAR (preferFresh) agar perubahan mock GPS terbaca, lalu
      // tolak submit bila di luar radius. Posisi disimpan untuk payload BE
      // (latitude/longitude/accuracy) — kontrak tidak berubah.
      if (widget.lngLat != null) {
        try {
          final geo = await _geofence.check(
            targetLat: widget.lngLat!.latitude,
            targetLng: widget.lngLat!.longitude,
            radiusMeter: widget.radiusMeter.toDouble(),
            preferFresh: true,
          );
          if (!mounted) return;
          setState(() {
            _currentPosition = geo.position;
            _geoStatus = geo.status;
            _poorAccuracy = geo.accuracyPoor;
            _geoStatusError = null;
          });

          // Akurasi buruk = peringatan saja, tidak memblokir. TIDAK dijadikan
          // toast di sini: AppSnackbar (Flushbar) push route, dan route toast
          // itu menutup form sehingga guard route.isCurrent pada auto-pop sukses
          // gagal → form nyangkut tanpa refresh (khusus staff yang kena
          // geofence; SPV tidak). Peringatan akurasi tetap tampil persisten di
          // banner geofence, jadi tak ada info yang hilang. `_poorAccuracy`
          // (di setState atas) yang menyalakan banner itu.

          // Gate memperhitungkan ketidakpastian GPS (allowed), bukan jarak
          // mentah — mencegah penolakan keliru saat di dalam/di dekat batas.
          if (GeofenceService.enforceGeofence && !geo.allowed) {
            setState(() => _isSubmitting = false);
            AppSnackbar.showError(
              "Anda berada di luar jangkauan lokasi WO. Submit ditolak.",
            );
            return;
          }
        } on GeofenceException catch (e) {
          if (mounted) setState(() => _isSubmitting = false);
          AppSnackbar.showError(e.message);
          return;
        } catch (e) {
          if (mounted) setState(() => _isSubmitting = false);
          AppSnackbar.showError("Gagal mendapatkan lokasi: ${e.toString()}");
          return;
        }
      } else {
        // Tanpa titik lokasi WO → geofence tidak bisa diterapkan. Tetap ambil
        // posisi untuk payload (tanpa memblokir submit).
        try {
          final pos = await _geofence.getCurrentPosition(preferFresh: true);
          if (!mounted) return;
          setState(() => _currentPosition = pos);
        } on GeofenceException catch (e) {
          if (mounted) setState(() => _isSubmitting = false);
          AppSnackbar.showError(e.message);
          return;
        } catch (e) {
          if (mounted) setState(() => _isSubmitting = false);
          AppSnackbar.showError("Gagal mendapatkan lokasi: ${e.toString()}");
          return;
        }
      }

      debugPrint("✅ Deskripsi: ${_descriptionController.text}");
      debugPrint(
        "✅ Gambar: ${_images.map((x) => x is XFile ? x.path : x.toString()).toList()}",
      );
      debugPrint("✅ Form Dinamis: $_formData");
      debugPrint(
        "📤 Submit ke backend dengan progressId: ${widget.progressId}",
      );
      final List<ProgressDetailModel> progressDetails = [];
      for (final detail in _progressDetails) {
        final int? resolvedDetailFormId =
            detail.form?.id ?? detail.detailFormId ?? detail.id;
        final String? formIdKey = resolvedDetailFormId?.toString();
        final bool mandatoryField = detail.form?.isRequired == true;
        final dynamic dynamicValue = formIdKey != null
            ? _formData[formIdKey]
            : null;
        String? value;
        XFile? image;

        debugPrint(
          "🔍 Processing detail ID: ${detail.id}, formId: $formIdKey, value: $dynamicValue",
        );

        if (resolvedDetailFormId == null) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          AppSnackbar.showError(
            "Struktur form tidak valid: detail_form_id tidak ditemukan.",
          );
          return;
        }

        final bool isEmptyDynamicValue =
            dynamicValue == null ||
            (dynamicValue is String && dynamicValue.trim().isEmpty) ||
            (dynamicValue is List && dynamicValue.isEmpty);

        if (mandatoryField && isEmptyDynamicValue) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          AppSnackbar.showError(
            "Field ${detail.form?.fieldName ?? resolvedDetailFormId} tidak boleh kosong.",
          );
          return;
        }

        if (dynamicValue != null && detail.form != null) {
          if (detail.form!.fieldType == 'image') {
            if (dynamicValue is XFile) {
              image = dynamicValue;
              value = null;
              debugPrint(
                "🖼️ Image for form ${detail.form!.id}: ${image.path}",
              );
            } else {
              value = null;
              debugPrint("⚠️ No image for form ${detail.form!.id}");
            }
          } else if (dynamicValue is int) {
            final options =
                detail.form!.optionsForm ?? const <OptionFormModel>[];
            final selectedOption = options.firstWhere(
              (option) => option.id == dynamicValue,
              orElse: () => const OptionFormModel(id: -1, optionName: ''),
            );
            value = selectedOption.id != -1 ? selectedOption.optionName : null;
            debugPrint("✅ Option for valueId $dynamicValue: $value");
          } else {
            value = dynamicValue.toString().trim();
            debugPrint("✅ Value as string: $value");
          }
        } else {
          value = detail.value?.trim() ?? '';
          debugPrint("⚠️ Fallback to existing value: $value");
        }

        progressDetails.add(
          ProgressDetailModel(
            id: detail.id,
            detailFormId: resolvedDetailFormId,
            value: value,
            image: image,
          ),
        );
      }

      final workOrderProgress = WorkOrderProgressModel(
        id: null,
        workOrderId: widget.workOrderId,
        tipeProgressId: widget.mode == 'Mulai'
            ? 1
            : (widget.mode == 'Selesai'
                  ? 3
                  : (widget.mode == 'Inspeksi' ? 6 : 2)),
        tahapan: widget.mode == 'Selesai'
            ? 4
            : (widget.mode == 'Progress' ? _selectedTahapan : null),
        description: _descriptionController.text,
        photos: _images.whereType<XFile>().toList(),
        submitTime: DateTime.now().toUtc(),
        progressDetails: progressDetails,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        accuracy: _currentPosition?.accuracy,
        kategoriData: widget.mode == 'Mulai'
            ? {
                if (widget.kategoriForm == 'jaringan') ...{
                  'jenis_pipa': _formData['jenis_pipa']?.toString().trim(),
                  'diameter_pipa': _formData['diameter_pipa']
                      ?.toString()
                      .trim(),
                  'panjang_pipa': _formData['panjang_pipa']?.toString().trim(),
                  'tingkat_kerusakan': _formData['tingkat_kerusakan']
                      ?.toString()
                      .trim(),
                } else if (widget.kategoriForm == 'infrastruktur') ...{
                  'nama_aset': _formData['nama_aset']?.toString().trim(),
                  'jenis_aset': _formData['jenis_aset']?.toString().trim(),
                  'kapasitas': _formData['kapasitas']?.toString().trim(),
                  'kondisi_awal': _formData['kondisi_awal']?.toString().trim(),
                } else if (widget.kategoriForm == 'meter') ...{
                  'nomor_meter': _formData['nomor_meter']?.toString().trim(),
                  'kondisi_meter_awal': _formData['kondisi_meter_awal']
                      ?.toString()
                      .trim(),
                },
              }
            : widget.mode == 'Selesai'
            ? {
                if (widget.kategoriForm == 'jaringan') ...{
                  'tindakan_perbaikan': _formData['tindakan_perbaikan']
                      ?.toString()
                      .trim(),
                  'hasil_inspeksi': _formData['hasil_inspeksi']
                      ?.toString()
                      .trim(),
                } else if (widget.kategoriForm == 'infrastruktur') ...{
                  'kondisi_awal': _formData['kondisi_awal']?.toString().trim(),
                  'kondisi_akhir': _formData['kondisi_akhir']
                      ?.toString()
                      .trim(),
                  'jadwal_pemeliharaan': _formData['jadwal_pemeliharaan'],
                  'tindakan': _formData['tindakan']?.toString().trim(),
                } else if (widget.kategoriForm == 'meter') ...{
                  'kondisi_meter_akhir': _formData['kondisi_meter_akhir']
                      ?.toString()
                      .trim(),
                  'hasil_kalibrasi': _formData['hasil_kalibrasi']
                      ?.toString()
                      .trim(),
                },
              }
            : null,
      );

      debugPrint(
        "📩 Submitting Progress: photos=${workOrderProgress.photos?.map((p) => p.path).toList()}, details=${progressDetails.map((d) => d.detailFormId).toList()}",
      );
      if (isRejected) {
        final resubmitProgress = workOrderProgress.copyWith(
          id: widget.progressId,
        );
        _workOrderBloc.add(ResubmitProgressEvent(resubmitProgress));
      } else {
        _workOrderBloc.add(UpdateWorkOrderProgressEvent(workOrderProgress));
      }
    }
  }

  void _onReview(String action) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final reviewModel = WorkOrderProgressModel(
      id: widget.progressId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reviewAction: action,
    );
    _workOrderBloc.add(UpdateWorkOrderProgressEvent(reviewModel));
  }

  void _onReviewWithNote(String action, String note) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final reviewModel = WorkOrderProgressModel(
      id: widget.progressId,
      description: note,
      reviewAction: action,
    );
    _workOrderBloc.add(UpdateWorkOrderProgressEvent(reviewModel));
  }

  void _fetchRevisionNote() async {
    try {
      final remoteDataSource = sl<WorkOrderProgressRemoteDataSource>();
      final response = await remoteDataSource.getProgressDetailsHistory(
        widget.progressId!,
      );
      if (response is DataSuccess<List<dynamic>>) {
        final list = response.data!;
        String? latestNote;
        for (final item in list.reversed) {
          final note =
              item['alasan_revisi']?.toString() ??
              item['catatan']?.toString() ??
              item['keterangan']?.toString() ??
              item['approval_notes']?.toString();
          if (note != null && note.trim().isNotEmpty) {
            latestNote = note.trim();
            break;
          }
        }
        if (latestNote != null && mounted) {
          setState(() {
            _revisionNote = latestNote;
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to fetch revision history: $e");
    }
  }

  void _showRevisionDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revisi',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Icon(Icons.close, color: color.foreground[500]),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Isi revisi...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: color.foreground[400]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.danger,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.success,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final note = noteController.text.trim();
                              if (note.isEmpty) {
                                AppSnackbar.showError(
                                  "Catatan revisi tidak boleh kosong.",
                                );
                                return;
                              }
                              Navigator.pop(dialogContext);
                              _onReviewWithNote('revisi', note);
                            },
                            child: const Text('Kirim'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRevisionNotePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.danger, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color.danger, size: 20),
              const SizedBox(width: 8),
              Text(
                'Revisi',
                style: textTheme.titleMedium?.copyWith(
                  color: color.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _revisionNote ?? '',
            style: textTheme.bodyMedium?.copyWith(color: color.foreground[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlySeniorStaffBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.danger, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: color.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hanya PIC dengan jabatan Senior Staff yang dapat submit SELESAI',
              style: textTheme.bodyMedium?.copyWith(
                color: color.foreground[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  dynamic _getOptionIdFromValue(ProgressDetailEntity detail) {
    if (detail.form != null &&
        detail.form!.optionsForm != null &&
        detail.value != null) {
      final options = detail.form!.optionsForm!;
      try {
        final selectedOption = options.firstWhere(
          (option) => option.optionName == detail.value,
          orElse: () => const OptionFormModel(id: -1, optionName: ''),
        );
        if (selectedOption.id != -1) {
          debugPrint(
            "✅ Found option ID ${selectedOption.id} for value ${detail.value}",
          );
          return selectedOption.id;
        }
      } catch (e) {
        debugPrint("❌ Error finding option ID for value ${detail.value}: $e");
      }
    }
    debugPrint("⚠️ Fallback to null for detail ID ${detail.id}");
    return null; // Fallback jika tidak ada opsi yang cocok
  }

  @override
  void dispose() {
    if (!isDetailMode && !_isSubmitting) {
      final draft = JournalDraft(
        description: _descriptionController.text,
        images: _images,
        formData: _formData,
      );
      _journalDraftCubit.saveDraft(_draftKey, draft);
    }
    _descriptionController.dispose();
    super.dispose();
  }

  /// Pengecekan geofence untuk indikator status (banner). Tidak memblokir —
  /// gate otoritatif ada di [_onSubmit]. [preferFresh] dipakai tombol
  /// "Periksa ulang" agar perubahan mock GPS langsung terbaca.
  Future<void> _checkDistance({bool preferFresh = false}) async {
    // Beri jeda agar Google Maps dari halaman sebelumnya selesai inisialisasi.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (widget.lngLat == null) {
      setState(() => _isCheckingDistance = false);
      return;
    }

    setState(() {
      _isCheckingDistance = true;
      _geoStatusError = null;
    });

    try {
      final result = await _geofence
          .check(
            targetLat: widget.lngLat!.latitude,
            targetLng: widget.lngLat!.longitude,
            radiusMeter: widget.radiusMeter.toDouble(),
            preferFresh: preferFresh,
          )
          .timeout(
            // Lebih besar dari total budget akuisisi di GeofenceService
            // (stream GPS ~6s + medium ~5s) agar fallback sempat jalan.
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException("Pengecekan lokasi timeout"),
          );

      if (!mounted) return;
      setState(() {
        _isCheckingDistance = false;
        _currentPosition = result.position;
        _geoStatus = result.status;
        _poorAccuracy = result.accuracyPoor;
        _geoStatusError = null;
      });
    } on GeofenceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingDistance = false;
        _geoStatus = null;
        _geoStatusError = e.message;
      });
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingDistance = false;
        _geoStatus = null;
        _geoStatusError = "Tidak dapat menentukan lokasi. Coba lagi.";
      });
    } catch (e) {
      debugPrint("⚠️ Error pengecekan lokasi: $e");
      if (!mounted) return;
      setState(() {
        _isCheckingDistance = false;
        _geoStatus = null;
        _geoStatusError = "Error: ${e.toString()}";
      });
    }
  }

  /// Banner status jangkauan di bawah peta. Memberi umpan balik visual sebelum
  /// submit; gate sesungguhnya tetap di [_onSubmit].
  Widget _buildGeofenceStatus() {
    if (_isCheckingDistance) {
      return _geoStatusBox(
        bg: color.foreground[100]!,
        border: color.foreground[400]!,
        icon: Icons.my_location,
        iconColor: color.foreground[600]!,
        title: "Memeriksa lokasi…",
        showSpinner: true,
      );
    }

    if (_geoStatusError != null) {
      return _geoStatusBox(
        bg: Colors.orange.withValues(alpha: 0.1),
        border: Colors.orange,
        icon: Icons.gps_off,
        iconColor: Colors.orange.shade800,
        title: "Tidak dapat memeriksa lokasi",
        subtitle: _geoStatusError,
        showRecheck: true,
      );
    }

    if (_geoStatus != null) {
      // Angka jarak/radius/akurasi sengaja TIDAK ditampilkan di UI (bisa
      // membingungkan saat GPS kasar) — tetap tercatat di log `[Geofence]`.
      final accNote = _poorAccuracy
          ? "\n⚠️ Akurasi GPS rendah, hasil mungkin kurang akurat."
          : "";
      switch (_geoStatus!) {
        case GeofenceStatus.inside:
          return _geoStatusBox(
            bg: color.status[2]!.withValues(alpha: 0.12),
            border: color.status[2]!,
            icon: Icons.check_circle,
            iconColor: color.status[2]!,
            title: "Anda berada dalam jangkauan",
            subtitle: accNote.isEmpty
                ? "Lokasi terverifikasi."
                : accNote.trim(),
            showRecheck: true,
          );
        case GeofenceStatus.withinTolerance:
          return _geoStatusBox(
            bg: Colors.orange.withValues(alpha: 0.1),
            border: Colors.orange,
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange.shade800,
            title: "Dalam jangkauan (perkiraan)",
            subtitle: "Submit diizinkan.$accNote",
            showRecheck: true,
          );
        case GeofenceStatus.outside:
          return _geoStatusBox(
            bg: color.danger.withValues(alpha: 0.1),
            border: color.danger,
            icon: Icons.location_off,
            iconColor: color.danger,
            title: "Anda di luar jangkauan",
            subtitle: "Submit akan ditolak.$accNote",
            showRecheck: true,
          );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _geoStatusBox({
    required Color bg,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool showSpinner = false,
    bool showRecheck = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          showSpinner
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (showRecheck)
            TextButton(
              onPressed: _isCheckingDistance
                  ? null
                  : () => _checkDistance(preferFresh: true),
              child: const Text("Periksa ulang"),
            ),
        ],
      ),
    );
  }
}
