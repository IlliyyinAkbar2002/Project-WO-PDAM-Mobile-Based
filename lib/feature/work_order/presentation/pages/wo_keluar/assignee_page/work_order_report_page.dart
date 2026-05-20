import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/config/theme/dynamic_form_config.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
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
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/journal_draft_cubit.dart';

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
    this.radiusMeter = 100, // Default 100 meter jika tidak ada
  });

  @override
  State<WorkOrderReportPage> createState() => _WorkOrderReportPageState();
}

class _WorkOrderReportPageState extends AppStatePage<WorkOrderReportPage> {
  late WorkOrderBloc _workOrderBloc;
  late JournalDraftCubit _journalDraftCubit;
  bool get isDetailMode =>
      widget.status == 5 || widget.status == 6 || !widget.isAssignee;
  bool get isRejected => _progressStatusId != null &&
      ProgressStatusId.isRevisiRequested(_progressStatusId);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  Map<String, dynamic> _formData = {};
  List<ProgressDetailEntity> _progressDetails = [];
  List<dynamic> _images = [];
  DateTime? _submitTime;
  int? _progressStatusId;
  bool _inRange = true;
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
    }

    if (widget.progressId == null) {
      if (widget.mode == 'Selesai') {
        setState(() {
          _progressDetails = [];
          isDataLoaded = true;
          _inRange = true;
          _isCheckingDistance = false;
        });
        return;
      }

      setState(() {
        isDataLoaded = true;
        _inRange = true;
        _isCheckingDistance = false;
      });
      return;
    }

    // Dispatch BLoC event untuk mengambil data
    if (widget.mode == 'Selesai') {
      _workOrderBloc.add(GetProgressDetailsEvent(widget.progressId!));
    } else {
      _workOrderBloc.add(GetWorkOrderProgressDetailEvent(widget.progressId!));
    }

    if (widget.mode == 'Mulai' && widget.lngLat != null && widget.isAssignee) {
      _checkDistance();
    } else {
      setState(() {
        _inRange = true;
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
            final description = state.progress.description ?? '';
            final submitTime = state.progress.submitTime;
            final statusId = state.progress.statusId;
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
                if (draft != null) {
                  _descriptionController.text = draft.description;
                  _images = List.from(draft.images);
                } else {
                  _descriptionController.text = description;
                  _images = images;
                }
                _submitTime = submitTime;
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
                  // Untuk mode selesai, tunggu fallback header progres
                  // agar deskripsi/dokumentasi tetap tampil saat detail kosong.
                  isDataLoaded = widget.mode == 'Selesai' ? false : true;
                });
              });
              return;
            }

            final description =
                progressDetails.first.workOrderProgress?.description ?? '';
            final submitTime =
                progressDetails.first.workOrderProgress?.submitTime;
            final statusId =
                progressDetails.first.workOrderProgress?.statusId;

            // Ambil images dari workOrderProgress.documentation
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

            // Schedule setState setelah frame selesai untuk menghindari blocking
            final draft = _journalDraftCubit.getDraft(_draftKey);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _progressDetails = progressDetails;
                if (draft != null) {
                  _descriptionController.text = draft.description;
                  _formData = Map.from(draft.formData);
                  _images = List.from(draft.images);
                } else {
                  _descriptionController.text = description;
                  _formData = formData;
                  _images = images;
                }
                _submitTime = submitTime;
                _progressStatusId = statusId;
                isDataLoaded = true;
              });
              _checkDataLoaded();
            });
          }
          if (state is WorkOrderProgressUpdated) {
            if (_hasClosedAfterSubmit) return;
            _hasClosedAfterSubmit = true;
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
            }
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
                          // Text(widget.mode, style: textTheme.displaySmall),
                          // const SizedBox(height: 16),
                          // Map dan info lokasi
                          if (widget.lngLat != null) _buildLocationMap(),
                          const SizedBox(height: 16),
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
                                  readOnly: isDetailMode,
                                ),
                                Text(
                                  "Dokumentasi",
                                  style: textTheme.titleLarge,
                                ),
                                ImagePickerField(
                                  initialImages: _images,
                                  enabled: !isDetailMode,
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
                          if (widget.mode == 'Selesai' &&
                              _progressDetails.isNotEmpty)
                            _buildDynamicForm(),
                          const SizedBox(height: 24),
                          widget.isAssignee && !isDetailMode
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getColor(),
                                  ),
                                  onPressed: _onSubmit,
                                  child: Text(
                                    widget.mode,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: widget.mode == 'Selesai'
                                          ? (widget.status == 7
                                                ? color.foreground[100]
                                                : color.primary[500])
                                          : color.primary[500],
                                    ),
                                  ),
                                )
                              : widget.isAssignee && isRejected
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: color.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: color.danger,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: color.danger,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Progress Ditolak',
                                                style: textTheme.titleMedium?.copyWith(
                                                  color: color.danger,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Silakan perbaiki progress sesuai catatan supervisor dan kirim ulang.',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: color.foreground[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color.primary[500],
                                      ),
                                      onPressed: _onResubmit,
                                      child: const Text('Kirim Ulang Progress'),
                                    ),
                                  ],
                                )
                              : widget.mode == 'Selesai' &&
                                    !widget.isAssignee &&
                                    ProgressStatusId.isSubmitted(_progressStatusId)
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color.danger,
                                        ),
                                        onPressed: () => _onReview('tolak'),
                                        child: const Text('Tolak'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color.status[2],
                                        ),
                                        onPressed: () => _onReview('accept'),
                                        child: const Text('Terima'),
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
    // Simulasi JSON form dinamis (sementara hardcoded)
    final dynamicFields = (isDetailMode || !widget.isAssignee)
        ? DynamicFormConfig.getDetailDynamicFormFields(
            details: _progressDetails,
            isDetailMode: isDetailMode,
          )
        : DynamicFormConfig.getDynamicFormFields(details: _progressDetails);
    debugPrint("🔍 detail mode: $isDetailMode");
    return DynamicFormBuilder(
      fields: dynamicFields,
      formData: _formData,
      onFieldChanged: _onFieldChanged,
      customWidgets: CustomFieldWidgets.fields,
      readOnly: false,
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
              initialCameraPosition: CameraPosition(
                target: location,
                zoom: 15,
              ),
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

  void _onSubmit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      if (_descriptionController.text.isEmpty) {
        AppSnackbar.showError("Deskripsi tidak boleh kosong.");
        return;
      }
      if (_images.isEmpty && widget.mode != 'Mulai') {
        AppSnackbar.showError("Minimal satu foto diperlukan.");
        return;
      }

      // Pastikan lokasi diambil untuk semua mode submit jika belum ada
      if (_currentPosition == null) {
        setState(() {
          _isSubmitting = true;
        });
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
            : (widget.mode == 'Selesai' ? 3 : 2),
        description: _descriptionController.text,
        photos: _images.whereType<XFile>().toList(),
        submitTime: DateTime.now().toUtc(),
        progressDetails: progressDetails,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        accuracy: _currentPosition?.accuracy,
      );

      debugPrint(
        "📩 Submitting Progress: photos=${workOrderProgress.photos?.map((p) => p.path).toList()}, details=${progressDetails.map((d) => d.detailFormId).toList()}",
      );
      setState(() {
        _isSubmitting = true;
        _hasClosedAfterSubmit = false;
      });
      _workOrderBloc.add(UpdateWorkOrderProgressEvent(workOrderProgress));
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
    _workOrderBloc.add(UpdateWorkOrderProgressEvent(reviewModel));
  }

  void _onResubmit() {
    if (widget.progressId == null) {
      AppSnackbar.showError("Progress ID tidak ditemukan.");
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    _workOrderBloc.add(ResubmitProgressEvent(widget.progressId!));
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
    // Beri jeda untuk memastikan Google Maps dari halaman sebelumnya
    // sudah selesai melakukan heavy initialization
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
        _inRange = result;
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
        _inRange = false;
        _isCheckingDistance = false;
      });
      AppSnackbar.showError("Tidak dapat menentukan lokasi. Coba lagi.");
    } catch (e) {
      debugPrint("⚠️ Error pengecekan lokasi: $e");
      if (!mounted) return;
      setState(() {
        _inRange = false;
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
