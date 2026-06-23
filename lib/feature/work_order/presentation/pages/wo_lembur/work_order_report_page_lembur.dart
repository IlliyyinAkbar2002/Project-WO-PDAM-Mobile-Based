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
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/custom_app_bar.dart';
import 'package:project_mobile_pdam/core/widget/custom_field_widgets.dart';
import 'package:project_mobile_pdam/core/widget/custom_form.dart';
import 'package:project_mobile_pdam/core/widget/dynamic_form_builder.dart';
import 'package:project_mobile_pdam/core/widget/image_picker.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/option_form_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/progress_detail_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/lembur_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/journal_draft_cubit.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/core/constants/tahapan_labels.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_lembur_repository.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';

class WorkOrderReportPageLembur extends StatefulWidget {
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

  const WorkOrderReportPageLembur({
    super.key,
    required this.mode,
    this.status,
    this.isAssignee = false,
    required this.progressId,
    this.workOrderId,
    this.workOrderTypeId,
    this.lngLat,
    this.locationName,
    this.radiusMeter = 100, // Default 100 meter jika tidak ada
    this.kategoriForm,
    this.initialKategoriData,
    this.initialDescription,
  });

  @override
  State<WorkOrderReportPageLembur> createState() =>
      _WorkOrderReportPageLemburState();
}

class _WorkOrderReportPageLemburState
    extends AppStatePage<WorkOrderReportPageLembur> {
  late LemburBloc _lemburBloc;
  late WorkOrderBloc _workOrderBloc;
  late JournalDraftCubit _journalDraftCubit;
  bool get isDetailMode =>
      widget.status == 5 || widget.status == 6 || !widget.isAssignee;
  bool get isRejected =>
      _progressStatusId != null &&
      ProgressStatusId.isRevisiRequested(_progressStatusId);

  bool get _isAlreadyRecorded =>
      widget.isAssignee && widget.progressId != null && !isRejected;

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
  int? _selectedTahapan;
  int? _progressStatusId;
  String? _revisionNote;
  bool _isCheckingDistance = true;
  bool isDataLoaded = false;
  bool _isSubmitting = false;
  bool _hasClosedAfterSubmit = false;
  bool _requestedHeaderFallback = false;
  Position? _currentPosition;

  String get _draftKey => '${widget.workOrderId}_${widget.mode}';

  // Simulasi JSON form dinamis (sementara hardcoded)

  @override
  void initState() {
    super.initState();
    _lemburBloc = context.read<LemburBloc>();
    _workOrderBloc = context.read<WorkOrderBloc>();
    _journalDraftCubit = context.read<JournalDraftCubit>();

    // Tunda inisialisasi sampai frame pertama selesai
    // untuk menghindari konflik dengan Google Maps dari halaman sebelumnya
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
          _isCheckingDistance = false;
        });
        return;
      }

      setState(() {
        isDataLoaded = true;
        _isCheckingDistance = false;
      });
      return;
    }

    if (widget.progressId != null && widget.isAssignee) {
      _fetchRevisionNote();
    }

    // Dispatch BLoC event untuk mengambil data
    if (widget.mode == 'Selesai') {
      _lemburBloc.add(GetLemburProgressDetailsHistoryEvent(widget.progressId!));
    } else {
      _lemburBloc.add(GetLemburProgressDetailEvent(widget.progressId!));
    }

    if (widget.mode == 'Mulai' && widget.lngLat != null && widget.isAssignee) {
      _checkDistance();
    } else {
      setState(() {
        _isCheckingDistance = false;
      });
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  void _checkDataLoaded() {
    if (isDataLoaded && !_isCheckingDistance) {
      if (_lemburBloc.state is LemburProgressDetailsHistoryLoaded ||
          _lemburBloc.state is LemburProgressDetailLoaded) {
        return;
      }
      setState(() {
        isDataLoaded = true;
      });
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Form Jurnal Lembur"),
      body: BlocListener<LemburBloc, LemburState>(
        listener: (context, state) {
          debugPrint("📢 State saat ini: $state");

          if (state is LemburProgressDetailLoaded) {
            setState(() {
              _progressStatusId = state.progress.statusId;
              if (ProgressStatusId.isRevisiRequested(state.progress.statusId)) {
                _revisionNote = state.progress.description ?? '';
              }
              _descriptionController.text =
                  state.progress.description ?? widget.initialDescription ?? '';

              final kategoriData = state.progress.kategoriData;
              if (kategoriData != null) {
                _formData.addAll(kategoriData);
              }

              if (state.progress.tahapan != null) {
                _selectedTahapan = state.progress.tahapan;
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

              _images =
                  state.progress.documentation
                      ?.map((doc) => doc.url)
                      .where(
                        (urlValue) => urlValue != null && urlValue.isNotEmpty,
                      )
                      .cast<dynamic>()
                      .toList() ??
                  [];
              _requestedHeaderFallback = false;
              isDataLoaded = true;
            });
            _checkDataLoaded();
          } else if (state is LemburProgressDetailsHistoryLoaded) {
            final progressDetails = state.details;
            final parsedDetails = progressDetails
                .whereType<ProgressDetailEntity>()
                .toList();
            // Endpoint history lembur mengembalikan data mentah; bila tidak ada
            // ProgressDetailEntity yang ter-parse (mis. progress "Selesai"
            // berbasis form kategori tanpa field dinamis), deskripsi & status
            // header tidak bisa diambil dari sini. Ambil header progress lewat
            // detail endpoint — sama seperti alur WO reguler.
            if (parsedDetails.isEmpty) {
              if (widget.mode == 'Selesai' &&
                  widget.progressId != null &&
                  !_requestedHeaderFallback) {
                _requestedHeaderFallback = true;
                _lemburBloc.add(
                  GetLemburProgressDetailEvent(widget.progressId!),
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

            final firstElement = parsedDetails.first;
            final rawDesc = firstElement.workOrderProgress?.description;
            final description = rawDesc?.isNotEmpty == true
                ? rawDesc!
                : (widget.initialDescription ?? '');

            final statusId = firstElement.workOrderProgress?.statusId;
            final tahapan = firstElement.workOrderProgress?.tahapan;

            final images =
                (firstElement.workOrderProgress?.documentation ?? [])
                    .map((doc) => doc.url)
                    .where(
                      (urlValue) => urlValue != null && urlValue.isNotEmpty,
                    )
                    .cast<dynamic>()
                    .toList();

            final formData = <String, dynamic>{};
            for (var detail in parsedDetails) {
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
                firstElement.workOrderProgress?.kategoriData;

            final draft = _journalDraftCubit.getDraft(_draftKey);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _progressDetails = parsedDetails;
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
          if (state is LemburProgressUpdated) {
            if (_hasClosedAfterSubmit) return;
            _hasClosedAfterSubmit = true;
            AppSnackbar.showSuccess("Form berhasil disubmit.");
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
              });
            }
          }
          if (state is LemburError) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
            }
            AppSnackbar.showError(state.message);
          }
        },
        child: BlocBuilder<LemburBloc, LemburState>(
          builder: (context, state) {
            final bool isSelesaiResubmit =
                isRejected && widget.mode == 'Selesai';
            final bool isSeniorStaff =
                AuthStorage.getJabatanKodeSync() == 'SENIOR_STAFF';
            final bool canShowResubmitButton =
                !isSelesaiResubmit || isSeniorStaff;

            String? jenisPekerjaan;
            if (widget.workOrderTypeId != null) {
              jenisPekerjaan = kJenisWorkOrderIdToName[widget.workOrderTypeId];
            }

            String? katForm = widget.kategoriForm;
            final woState = _workOrderBloc.state;
            if (woState is WorkOrderDetailLoaded) {
              jenisPekerjaan ??= woState.workOrder.workOrderType?.name;
              katForm ??= woState.workOrder.kategoriForm;
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

            return !isDataLoaded || _isCheckingDistance
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          "Pengecekan lokasi...",
                          style: textTheme.titleLarge?.copyWith(
                            color: color.primary[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (widget.lngLat != null) _buildLocationMap(),
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
                              border: Border.all(color: color.foreground[400]!),
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
                                  readOnly: isDetailMode || _isAlreadyRecorded,
                                ),
                                Text(
                                  "Dokumentasi",
                                  style: textTheme.titleLarge,
                                ),
                                ImagePickerField(
                                  initialImages: _images,
                                  enabled: !isDetailMode && !_isAlreadyRecorded,
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
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _getColor(),
                                              ),
                                              onPressed: _isSubmitting
                                                  ? null
                                                  : _onSubmit,
                                              child: _isSubmitting
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      isRejected
                                                          ? 'Kerjakan Revisi'
                                                          : widget.mode,
                                                      style: textTheme.labelLarge?.copyWith(
                                                        // Tombol "Selesai" ber-background
                                                        // primary[500] (navy gelap) → teks
                                                        // harus terang agar terbaca. Mode
                                                        // lain ber-background terang →
                                                        // pakai primary[500].
                                                        color:
                                                            widget.mode ==
                                                                'Selesai'
                                                            ? Colors.white
                                                            : color
                                                                  .primary[500],
                                                      ),
                                                    ),
                                            )))
                              : widget.isAssignee && isRejected
                              ? const SizedBox()
                              : widget.mode == 'Selesai' &&
                                    !widget.isAssignee &&
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
                                        onPressed: _showRevisionDialog,
                                        child: const Text('Revisi'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color.status[2],
                                        ),
                                        onPressed: () => _onReview('accept'),
                                        child: const Text(
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
                  );
          },
        ),
      ),
    );
  }

  Widget _buildDynamicForm() {
    final List<Map<String, dynamic>> dynamicFields;
    if (widget.kategoriForm != null) {
      dynamicFields = widget.mode == 'Mulai'
          ? FormFieldsConfig.getStartKategoriFields(
              kategoriForm: widget.kategoriForm,
              isReadOnly: isDetailMode || _isAlreadyRecorded,
            )
          : FormFieldsConfig.getSubmissionFields(
              kategoriForm: widget.kategoriForm,
              isReadOnly: isDetailMode || _isAlreadyRecorded,
            );
    } else {
      dynamicFields = (isDetailMode || !widget.isAssignee)
          ? DynamicFormConfig.getDetailDynamicFormFields(
              details: _progressDetails,
              isDetailMode: isDetailMode,
            )
          : DynamicFormConfig.getDynamicFormFields(details: _progressDetails);
    }
    return DynamicFormBuilder(
      fields: dynamicFields,
      formData: _formData,
      onFieldChanged: _onFieldChanged,
      customWidgets: CustomFieldWidgets.fields,
      readOnly: false,
    );
  }

  Widget _buildTahapanSelector() {
    String? jenisPekerjaan;
    int tahapanTertinggi = 1;
    bool isPic = true;

    final state = _workOrderBloc.state;
    if (state is WorkOrderDetailLoaded) {
      jenisPekerjaan ??= state.workOrder.workOrderType?.name;
      tahapanTertinggi = state.workOrder.tahapanTertinggi ?? 1;

      final currentUser = AuthStorage.getUserSync();
      final currentUserIdStr = currentUser?['id']?.toString();
      final picIdStr = state.workOrder.assignment?.assigneeId?.toString();
      final creatorIdStr = state.workOrder.creator?.toString();
      final isSeniorStaff = AuthStorage.getJabatanKodeSync() == 'SENIOR_STAFF';

      if (currentUserIdStr != null) {
        isPic =
            (picIdStr != null && currentUserIdStr == picIdStr) ||
            (creatorIdStr != null && currentUserIdStr == creatorIdStr) ||
            isSeniorStaff;
      }
    }

    List<int> validTahapan = [1, 2, 3, 4];
    if (widget.mode == 'Inspeksi' || widget.mode == 'Mulai') {
      validTahapan = [1];
    } else if (widget.mode == 'Progress') {
      validTahapan = [2, 3];
    } else if (widget.mode == 'Selesai') {
      validTahapan = [4];
    }

    if (_selectedTahapan != null && !validTahapan.contains(_selectedTahapan)) {
      _selectedTahapan = validTahapan.first;
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
              final isDisabled = !isPic && val > tahapanTertinggi;
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

  Widget _buildLocationMap() {
    final location = widget.lngLat!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          widget.locationName ?? "Lokasi Work Order",
          style: textTheme.titleMedium?.copyWith(
            color: color.primary[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Color? _getColor() {
    switch (widget.mode) {
      case 'Mulai':
        return color.status[2];
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
              'Laporan sudah tercatat dan tidak dapat diubah. '
              'Untuk mengirim ulang, batalkan laporan ini terlebih dahulu '
              'dari halaman daftar progress.',
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
      AppSnackbar.showWarning(
        'Laporan sudah tercatat. Batalkan terlebih dahulu sebelum mengubah.',
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (_descriptionController.text.isEmpty) {
        AppSnackbar.showError("Deskripsi tidak boleh kosong.");
        return;
      }
      if (_images.isEmpty && widget.mode != 'Mulai') {
        AppSnackbar.showError("Minimal satu foto diperlukan.");
        return;
      }

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

      if (_currentPosition == null) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            await Geolocator.openLocationSettings();
            throw Exception(
              "GPS harus diaktifkan. Silakan aktifkan dan coba lagi.",
            );
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              throw Exception("Akses lokasi ditolak.");
            }
          }

          if (permission == LocationPermission.deniedForever) {
            throw Exception(
              "Akses lokasi ditolak permanen. Silakan aktifkan di Settings.",
            );
          }

          Position? current = await Geolocator.getLastKnownPosition();
          current ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          );
          _currentPosition = current;
        } catch (e) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
          AppSnackbar.showError("Gagal mendapatkan lokasi: ${e.toString()}");
          return;
        }
      }

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
            } else {
              value = null;
            }
          } else if (dynamicValue is int) {
            final options =
                detail.form!.optionsForm ?? const <OptionFormModel>[];
            final selectedOption = options.firstWhere(
              (option) => option.id == dynamicValue,
              orElse: () => const OptionFormModel(id: -1, optionName: ''),
            );
            value = selectedOption.id != -1 ? selectedOption.optionName : null;
          } else {
            value = dynamicValue.toString().trim();
          }
        } else {
          value = detail.value?.trim() ?? '';
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

      final progressModel = WorkOrderProgressModel(
        id: isRejected ? widget.progressId : null,
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
        "📩 Submitting Progress: photos=${progressModel.photos?.map((p) => p.path).toList()}, details=${progressDetails.map((d) => d.detailFormId).toList()}",
      );

      if (isRejected) {
        final resubmitProgress = progressModel.copyWith(id: widget.progressId);
        _lemburBloc.add(ResubmitLemburProgressEvent(resubmitProgress));
      } else if (widget.mode == 'Mulai') {
        _lemburBloc.add(StartLemburProgressEvent(progressModel));
      } else {
        _lemburBloc.add(UpdateLemburProgressEvent(progressModel));
      }
    }
  }

  void _onReview(String action) {
    final reviewModel = WorkOrderProgressModel(
      id: widget.progressId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reviewAction: action,
    );
    _lemburBloc.add(UpdateLemburProgressEvent(reviewModel));
  }

  void _onReviewWithNote(String action, String note) {
    final reviewModel = WorkOrderProgressModel(
      id: widget.progressId,
      description: note,
      reviewAction: action,
    );
    _lemburBloc.add(UpdateLemburProgressEvent(reviewModel));
  }

  void _fetchRevisionNote() async {
    try {
      final repository = sl<WorkOrderLemburRepository>();
      final response = await repository.getProgressDetailsHistory(
        widget.progressId!,
      );
      if (response is DataSuccess<List<dynamic>>) {
        final list = response.data!;
        String? latestNote;
        for (final item in list.reversed) {
          final note =
              item['catatan']?.toString() ??
              item['keterangan']?.toString() ??
              item['alasan_penolakan']?.toString() ??
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
    XFile? selectedFile;

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
                    // File Picker
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (file != null) {
                          setStateDialog(() {
                            selectedFile = file;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: color.foreground[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.upload, color: color.foreground[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFile != null
                                    ? selectedFile!.name
                                    : 'Pilih File',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: color.foreground[700]),
                              ),
                            ),
                            if (selectedFile != null)
                              GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    selectedFile = null;
                                  });
                                },
                                child: Icon(
                                  Icons.clear,
                                  color: color.foreground[500],
                                  size: 18,
                                ),
                              )
                            else
                              Text(
                                '...',
                                style: TextStyle(color: color.foreground[500]),
                              ),
                          ],
                        ),
                      ),
                    ),
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

  Future<void> _checkDistance() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      final latitudeData = widget.lngLat!.latitude;
      final longitudeData = widget.lngLat!.longitude;

      // Tambahkan timeout keseluruhan 15 detik untuk mencegah freeze
      final result =
          await isUserWithinRange(
            targetLat: latitudeData,
            targetLng: longitudeData,
            maxDistanceInMeters: widget.radiusMeter.toDouble(),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException("Pengecekan lokasi timeout");
            },
          );

      if (!mounted) return; // Safety check setelah async operation

      setState(() {
        _isCheckingDistance = false;
      });
      if (!result) {
        AppSnackbar.showError(
          "Lokasi Anda diluar jangkauan (radius ${widget.radiusMeter}m).",
        );
      } else {
        AppSnackbar.showSuccess("Anda berada dalam jangkauan.");
      }
    } on TimeoutException catch (_) {
      // Handle timeout - GPS terlalu lama
      debugPrint(
        "⚠️ GPS timeout - tidak dapat mendapatkan lokasi dalam waktu yang ditentukan",
      );
      if (!mounted) return;
      setState(() {
        _isCheckingDistance = false;
      });
      AppSnackbar.showError("Tidak dapat menentukan lokasi. Coba lagi.");
    } catch (e) {
      debugPrint("⚠️ Error pengecekan lokasi: $e");
      if (!mounted) return;
      setState(() {
        _isCheckingDistance = false;
      });
      AppSnackbar.showError("Error: ${e.toString()}");
    }
  }

  Future<bool> isUserWithinRange({
    required double targetLat,
    required double targetLng,
    required double maxDistanceInMeters, // batas jarak dari MasterLocation
  }) async {
    // Menggunakan Geolocator saja untuk semua operasi (menghindari konflik dengan package location)

    // Cek apakah location service enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Buka settings GPS (lebih reliable daripada location.requestService())
      await Geolocator.openLocationSettings();
      throw Exception("GPS harus diaktifkan. Silakan aktifkan dan coba lagi.");
    }

    // Cek permission menggunakan Geolocator
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Akses lokasi ditolak.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Akses lokasi ditolak permanen. Silakan aktifkan di Settings.",
      );
    }

    // Coba ambil lokasi terakhir yang diketahui (sangat cepat)
    Position? current = await Geolocator.getLastKnownPosition();

    // Jika tidak ada, baru ambil lokasi baru dengan timeout
    current ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    _currentPosition = current;

    // Hitung jarak
    double distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      targetLat,
      targetLng,
    );

    debugPrint("📏 Jarak ke lokasi: $distance meter");

    return distance <= maxDistanceInMeters;
  }
}
