import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:mobile_intern_pdam/config/theme/dynamic_form_config.dart';
import 'package:mobile_intern_pdam/core/utils/app_snackbar.dart';
import 'package:mobile_intern_pdam/core/widget/app_state_page.dart';
import 'package:mobile_intern_pdam/core/widget/custom_app_bar.dart';
import 'package:mobile_intern_pdam/core/widget/custom_field_widgets.dart';
import 'package:mobile_intern_pdam/core/widget/custom_form.dart';
import 'package:mobile_intern_pdam/core/widget/dynamic_form_builder.dart';
import 'package:mobile_intern_pdam/core/widget/image_picker.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/option_form_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/progress_detail_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/data/models/work_order_progress_model.dart';
import 'package:mobile_intern_pdam/feature/work_order/domain/entities/progress_detail_entity.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:mobile_intern_pdam/feature/work_order/presentation/bloc/work_order_state.dart';

class WorkOrderReportPage extends StatefulWidget {
  final String mode;
  final int? status;
  final bool isAssignee;
  final int? progressId;
  final int? workOrderTypeId;
  final LatLng? lngLat;

  const WorkOrderReportPage({
    super.key,
    required this.mode,
    this.status,
    this.isAssignee = false,
    required this.progressId,
    this.workOrderTypeId,
    this.lngLat,
  });

  @override
  State<WorkOrderReportPage> createState() => _WorkOrderReportPageState();
}

class _WorkOrderReportPageState extends AppStatePage<WorkOrderReportPage> {
  late WorkOrderBloc _workOrderBloc;
  bool get isDetailMode =>
      widget.status == 5 || widget.status == 6 || !widget.isAssignee;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  Map<String, dynamic> _formData = {};
  List<ProgressDetailEntity> _progressDetails = [];
  List<dynamic> _images = [];
  DateTime? _submitTime;
  bool _inRange = true;
  bool _isCheckingDistance = true;
  bool isDataLoaded = false;

  // Simulasi JSON form dinamis (sementara hardcoded)

  @override
  void initState() {
    super.initState();
    _workOrderBloc = context.read<WorkOrderBloc>();

    if (widget.mode == 'Selesai') {
      _workOrderBloc.add(GetProgressDetailsEvent(widget.progressId!));
    } else {
      _workOrderBloc.add(GetWorkOrderProgressDetailEvent(widget.progressId!));
    }

    if (widget.lngLat != null && widget.isAssignee) {
      _checkDistance();
    } else {
      _isCheckingDistance = false;
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  void _checkDataLoaded() {
    if (_progressDetails.isNotEmpty) {
      setState(() {
        debugPrint("✅ Data loaded: $_progressDetails");
        debugPrint("Value : ${_progressDetails.first.value}");
        debugPrint(
          "Description: ${_progressDetails.first.workOrderProgress?.description}",
        );
        isDataLoaded = true;
      });
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Form Jurnal"),
      body: BlocListener<WorkOrderBloc, WorkOrderState>(
        listener: (context, state) {
          if (state is WorkOrderProgressDetailLoaded) {
            setState(() {
              _descriptionController.text = state.progress.description ?? '';
              _submitTime = state.progress.submitTime;
              _images = state.progress.documentation!
                  .map((doc) => doc.url) // doc.url adalah String path relatif
                  .where((urlValue) => urlValue != null && urlValue.isNotEmpty)
                  .cast<dynamic>() // Agar sesuai dengan ImagePickerField
                  .toList();
            });

            isDataLoaded = true;
          }
          if (state is ProgressDetailsLoaded) {
            setState(() {
              _progressDetails = state.progressDetails;
              _descriptionController.text =
                  state.progressDetails.first.workOrderProgress?.description ??
                  '';
              _submitTime =
                  state.progressDetails.first.workOrderProgress?.submitTime;
              _formData = {
                for (var detail in _progressDetails)
                  detail.id.toString(): (isDetailMode)
                      ? detail.value
                      : _getOptionIdFromValue(detail),
              };
              _checkDataLoaded();
            });
          }
          if (state is WorkOrderProgressUpdated) {
            AppSnackbar.showSuccess("Form berhasil disubmit.");
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
                          Text(widget.mode, style: textTheme.displaySmall),
                          const SizedBox(height: 20),
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
                                  readOnly: !_inRange || isDetailMode,
                                ),
                                Text(
                                  "Dokumentasi",
                                  style: textTheme.titleLarge,
                                ),
                                ImagePickerField(
                                  initialImages: _images,
                                  enabled: _inRange || !isDetailMode,
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
                          if (widget.mode == 'Selesai') _buildDynamicForm(),
                          const SizedBox(height: 24),
                          widget.isAssignee && !isDetailMode
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getColor(),
                                  ),
                                  onPressed: !_inRange
                                      ? null
                                      : (widget.mode != 'Mulai'
                                            ? (widget.status == 7
                                                  ? _onSubmit
                                                  : null)
                                            : (widget.status != 7
                                                  ? _onSubmit
                                                  : null)),
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
                              : widget.mode == 'Selesai' && !widget.isAssignee
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color.danger,
                                      ),
                                      onPressed: () {},
                                      child: const Text('Tolak'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color.status[2],
                                      ),
                                      onPressed: () {},
                                      child: const Text('Terima'),
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
      readOnly: !_inRange,
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

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_descriptionController.text.isEmpty) {
        AppSnackbar.showError("Deskripsi tidak boleh kosong.");
        return;
      }
      if (_images.isEmpty) {
        AppSnackbar.showError("Minimal satu foto diperlukan.");
        return;
      }

      debugPrint("✅ Deskripsi: ${_descriptionController.text}");
      debugPrint("✅ Gambar: ${_images.map((x) => x.path).toList()}");
      debugPrint("✅ Form Dinamis: $_formData");
      debugPrint(
        "📤 Submit ke backend dengan progressId: ${widget.progressId}",
      );
      final progressDetails = _progressDetails.map((detail) {
        final formId = detail.form?.id.toString();
        final mandatoryField = detail.form?.isRequired;
        final dynamicValue = formId != null ? _formData[formId] : null;
        String? value;
        XFile? image;

        debugPrint(
          "🔍 Processing detail ID: ${detail.id}, formId: $formId, value: $dynamicValue",
        );

        if (mandatoryField == true && dynamicValue == null) {
          AppSnackbar.showError(
            "Field ${detail.form?.fieldName} tidak boleh kosong.",
          );
          return ProgressDetailModel(id: detail.id);
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
            final options = detail.form!.optionsForm!;
            final selectedOption = options.firstWhere(
              (option) => option.id == dynamicValue,
              orElse: () => const OptionFormModel(id: -1, optionName: ''),
            );
            value = selectedOption.id != -1 ? selectedOption.optionName : null;
            debugPrint("✅ Option for valueId $dynamicValue: $value");
          } else {
            value = dynamicValue.toString();
            debugPrint("✅ Value as string: $value");
          }
        } else {
          value = detail.value ?? '';
          debugPrint("⚠️ Fallback to existing value: $value");
        }

        return ProgressDetailModel(
          id: detail.id,
          detailFormId: detail.form?.id,
          value: value,
          image: image,
        );
      }).toList();

      final workOrderProgress = WorkOrderProgressModel(
        id: widget.progressId,
        description: _descriptionController.text,
        photos: _images
            .map((image) => XFile(image.path)) // Konversi ke XFile
            .toList(),
        submitTime: DateTime.now().toUtc(),
        progressDetails: progressDetails,
      );

      debugPrint(
        "📩 Submitting Progress: photos=${workOrderProgress.photos?.map((p) => p.path).toList()}, details=${progressDetails.map((d) => d.detailFormId).toList()}",
      );
      _workOrderBloc.add(UpdateWorkOrderProgressEvent(workOrderProgress));
    }
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
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkDistance() async {
    try {
      final latitudeData = widget.lngLat!.latitude;
      final longitudeData = widget.lngLat!.longitude;
      final result = await isUserWithinRange(
        targetLat: latitudeData,
        targetLng: longitudeData,
      );
      setState(() {
        _inRange = result;
        _isCheckingDistance = false;
      });
      if (!result) {
        AppSnackbar.showError("Lokasi Anda diluar jangkauan.");
      } else {
        AppSnackbar.showSuccess("Anda berada dalam jangkauan.");
      }
    } on TimeoutException catch (_) {
      // Handle timeout - GPS terlalu lama
      debugPrint(
        "⚠️ GPS timeout - tidak dapat mendapatkan lokasi dalam waktu yang ditentukan",
      );
      setState(() {
        _inRange = false;
        _isCheckingDistance = false;
      });
      AppSnackbar.showError("Tidak dapat menentukan lokasi. Coba lagi.");
    } catch (e) {
      debugPrint("⚠️ Error pengecekan lokasi: $e");
      setState(() {
        _inRange = false;
        _isCheckingDistance = false;
      });
    }
  }

  Future<bool> isUserWithinRange({
    required double targetLat,
    required double targetLng,
    double maxDistanceInMeters = 100, // batas jarak
  }) async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location
          .requestService(); // ✅ munculkan dialog otomatis
      if (!serviceEnabled) {
        throw Exception("GPS harus diaktifkan.");
      }
    }

    // Cek permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception("Akses lokasi ditolak.");
      }
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
