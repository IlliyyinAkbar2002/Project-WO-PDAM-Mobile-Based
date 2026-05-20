import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';

class WorkOrderProgressRemoteDataSource extends RemoteDatasource {
  WorkOrderProgressRemoteDataSource() : super();

  String basename(String path) => p.basename(path);

  DioException _toDioException(Object error, String path) {
    if (error is DioException) return error;
    return DioException(
      error: error,
      requestOptions: RequestOptions(path: path),
    );
  }

  void _logDioError(String context, DioException error) {
    debugPrint(
      "❌ $context failed:"
      " status=${error.response?.statusCode},"
      " path=${error.requestOptions.path},"
      " data=${error.response?.data},"
      " message=${error.message},"
      " inner=${error.error}",
    );
  }

  String _normalizeReviewDecision(String rawAction) {
    final normalized = rawAction.trim().toLowerCase();
    if (normalized == 'accept' ||
        normalized == 'terima' ||
        normalized == 'approve') {
      return 'accept';
    } else if (normalized == 'reject' || normalized == 'tolak') {
      return 'reject';
    } else if (normalized == 'revision' || normalized == 'revisi') {
      return 'revisi';
    }
    return normalized;
  }

  Map<String, dynamic> _extractProgressPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final dynamic payload = raw['data'] ?? raw;
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      if (payload is List && payload.isNotEmpty && payload.first is Map) {
        return Map<String, dynamic>.from(payload.first as Map);
      }
      if (raw.containsKey('id')) {
        return raw;
      }
    }

    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }

    throw const FormatException('Format detail progress tidak dikenali.');
  }

  Future<DataState<List<WorkOrderProgressModel>>> fetchProgressByWorkOrderId(
    int workOrderId,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(
        path: '/v1/progress-workorder',
        queryParameters: {'workorder_id': workOrderId},
      );
      final dynamic raw = response.data;
      debugPrint("📥 fetchProgressByWorkOrderId($workOrderId) raw: $raw");

      if (raw is Map<String, dynamic>) {
        final dynamic payload = raw['data'] ?? raw;
        if (payload is List) {
          final data = payload
              .whereType<Map>()
              .map<WorkOrderProgressModel>(
                (json) => WorkOrderProgressModel.fromMap(
                  Map<String, dynamic>.from(json),
                ),
              )
              .toList();
          debugPrint(
            "📥 fetchProgressByWorkOrderId parsed ${data.length} items from list",
          );
          return DataSuccess(data);
        }

        final progressModel = WorkOrderProgressModel.fromMap(
          Map<String, dynamic>.from(payload),
        );
        return DataSuccess([progressModel]);
      }

      if (raw is List) {
        final data = raw
            .whereType<Map>()
            .map<WorkOrderProgressModel>(
              (json) => WorkOrderProgressModel.fromMap(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
        debugPrint(
          "📥 fetchProgressByWorkOrderId parsed ${data.length} items from raw list",
        );
        return DataSuccess(data);
      }

      debugPrint(
        "⚠️ fetchProgressByWorkOrderId: unexpected format, returning empty",
      );
      return const DataSuccess(<WorkOrderProgressModel>[]);
    } catch (e, st) {
      final dioError = _toDioException(e, '/v1/progress-workorder');
      _logDioError('fetchProgressByWorkOrderId', dioError);
      debugPrint("❌ fetchProgressByWorkOrderId stack: $st");
      return DataFailed(dioError);
    }
  }

  Future<DataState<void>> cancelProgress(int progressId) async {
    try {
      await post(path: '/v1/progress-workorder/$progressId/cancel');
      return const DataSuccess(null);
    } catch (e) {
      final dioError = _toDioException(
        e,
        '/v1/progress-workorder/$progressId/cancel',
      );
      _logDioError('cancelProgress', dioError);
      return DataFailed(dioError);
    }
  }

  Future<DataState<WorkOrderProgressModel>> getWorkOrderProgressDetail(
    int id,
  ) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/progress-workorder/$id');
      final payload = _extractProgressPayload(response.data);
      final data = WorkOrderProgressModel.fromMap(payload);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/progress-workorder/$id'),
        ),
      );
    }
  }

  Future<DataState<WorkOrderProgressModel>> resubmitProgress(
    int progressWorkorderId,
  ) async {
    try {
      final response = await post(
        path: '/v1/progress-detail/resubmit',
        data: {'progress_workorder_id': progressWorkorderId},
      );
      final dynamic rawData = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      final dynamic payload;
      if (rawData is Map<String, dynamic> && rawData.containsKey('progress')) {
        payload = rawData['progress'];
      } else {
        payload = rawData;
      }
      final data = payload is Map<String, dynamic>
          ? WorkOrderProgressModel.fromMap(payload)
          : throw const FormatException('Invalid resubmit response format');
      return DataSuccess(data);
    } catch (e) {
      final dioError = _toDioException(e, '/v1/progress-detail/resubmit');
      _logDioError('resubmitProgress', dioError);
      return DataFailed(dioError);
    }
  }

  Future<DataState<WorkOrderProgressModel>> updateWorkOrderProgressDetail(
    WorkOrderProgressModel workOrderProgress,
  ) async {
    try {
      final formData = FormData();

      // hasil_pengerjaan is required by all endpoints
      formData.fields.add(
        MapEntry('hasil_pengerjaan', workOrderProgress.description ?? ''),
      );

      // Koordinat GPS (required oleh BE di endpoint /start dan /submit).
      if (workOrderProgress.latitude != null) {
        formData.fields.add(
          MapEntry('latitude', workOrderProgress.latitude.toString()),
        );
      }
      if (workOrderProgress.longitude != null) {
        formData.fields.add(
          MapEntry('longitude', workOrderProgress.longitude.toString()),
        );
      }
      if (workOrderProgress.accuracy != null) {
        formData.fields.add(
          MapEntry('accuracy', workOrderProgress.accuracy.toString()),
        );
      }

      // Add photos to FormData
      debugPrint(
        "📸 photos runtimeType: ${workOrderProgress.photos.runtimeType}",
      );
      if (workOrderProgress.photos != null) {
        debugPrint("📸 First photo: ${workOrderProgress.photos!.first}");
      }
      if (workOrderProgress.photos != null &&
          workOrderProgress.photos!.isNotEmpty) {
        for (var photo in workOrderProgress.photos!) {
          try {
            final file = File(photo.path);
            if (await file.exists()) {
              debugPrint("📷 Adding file photos: ${photo.path}");
              formData.files.add(
                MapEntry(
                  'foto[]',
                  await MultipartFile.fromFile(
                    photo.path,
                    filename: basename(photo.path),
                  ),
                ),
              );
            } else {
              debugPrint("❌ File not found: ${photo.path}");
            }
          } catch (e) {
            debugPrint("❌ Error adding file ${photo.path}: $e");
          }
        }
      } else {
        debugPrint("⚠️ No photos provided");
      }

      final progressDetails = workOrderProgress.progressDetails ?? const [];
      if (progressDetails.isEmpty) {
        debugPrint("⚠️ No progress details provided, skipping detail_progress");
      } else {
        for (int i = 0; i < progressDetails.length; i++) {
          final detailItem = progressDetails[i];

          // Pastikan detail_form_id ada untuk membentuk kunci
          if (detailItem.detailFormId == null) {
            return DataFailed(
              DioException(
                error:
                    'detail_form_id wajib diisi untuk item detail_progress index $i.',
                requestOptions: RequestOptions(
                  path: '/v1/progress-workorder/${workOrderProgress.id}',
                ),
              ),
            );
          }

          // Tambahkan detail_form_id untuk item saat ini
          formData.fields.add(
            MapEntry(
              'detail_progress[$i][detail_form_id]',
              detailItem.detailFormId.toString(), // Backend mengharapkan string
            ),
          );

          // Tentukan 'value' untuk payload
          String valueForPayload;
          if (detailItem.image != null) {
            // Jika ini adalah item gambar, backend mengharapkan value string kosong
            valueForPayload = "";
          } else {
            // Jika bukan item gambar, gunakan value dari model,
            // atau string kosong jika value di model adalah null.
            valueForPayload = detailItem.value ?? "";
          }
          formData.fields.add(
            MapEntry(
              'detail_progress[$i][value]',
              valueForPayload, // Ini sudah string
            ),
          );
        }
        debugPrint("📋 Detail Progress fields constructed in indexed format.");
      }

      if (progressDetails.isNotEmpty) {
        // Tambah detail_progress_images (single-image)
        for (var detail in progressDetails) {
          if (detail.image != null && detail.detailFormId != null) {
            try {
              final file = File(detail.image!.path);
              if (await file.exists()) {
                debugPrint(
                  "🖼️ Adding image for form ${detail.detailFormId}: ${detail.image!.path}",
                );
                formData.files.add(
                  MapEntry(
                    'detail_progress_images[${detail.detailFormId}]',
                    await MultipartFile.fromFile(
                      detail.image!.path,
                      filename: basename(detail.image!.path),
                    ),
                  ),
                );
              } else {
                debugPrint("❌ Image file not found: ${detail.image!.path}");
              }
            } catch (e) {
              debugPrint("❌ Error adding image ${detail.image!.path}: $e");
            }
          }
        }
      }

      debugPrint("📤 Sending payload: ${formData.fields}");
      debugPrint(
        "📤 Sending files: ${formData.files.map((e) => e.key).toList()}",
      );

      late final Response response;
      final bool isStart =
          workOrderProgress.id == null && workOrderProgress.tipeProgressId == 1;
      final bool isSubmit =
          workOrderProgress.id == null &&
          (workOrderProgress.tipeProgressId == 2 ||
              workOrderProgress.tipeProgressId == 3);
      final bool isReview = workOrderProgress.reviewAction != null;

      if (isReview) {
        if (workOrderProgress.id == null) {
          return DataFailed(
            DioException(
              error: 'progressId wajib diisi untuk endpoint review progress.',
              requestOptions: RequestOptions(
                path: '/v1/progress-workorder/review',
              ),
            ),
          );
        }
        final decision = _normalizeReviewDecision(
          workOrderProgress.reviewAction!,
        );
        formData.fields.addAll([
          MapEntry('progress_workorder_id', workOrderProgress.id.toString()),
          MapEntry('progress_id', workOrderProgress.id.toString()),
          MapEntry('decision', decision),
          MapEntry('action', decision),
          MapEntry('review_action', decision),
          if ((workOrderProgress.description ?? '').trim().isNotEmpty)
            MapEntry('alasan_penolakan', workOrderProgress.description!.trim()),
          if ((workOrderProgress.description ?? '').trim().isNotEmpty)
            MapEntry('catatan', workOrderProgress.description!.trim()),
        ]);
        response = await post(
          path: '/v1/progress-workorder/review',
          data: formData,
          contentType: ContentType.multipart,
        );
      } else if (isStart) {
        if (workOrderProgress.workOrderId == null) {
          return DataFailed(
            DioException(
              error: 'workOrderId wajib diisi untuk endpoint start progress.',
              requestOptions: RequestOptions(
                path: '/v1/progress-workorder/start',
              ),
            ),
          );
        }
        if (workOrderProgress.latitude == null ||
            workOrderProgress.longitude == null) {
          return DataFailed(
            DioException(
              error:
                  'Koordinat GPS (latitude & longitude) wajib diisi untuk memulai progress. '
                  'Pastikan izin lokasi diaktifkan dan GPS menyala.',
              requestOptions: RequestOptions(
                path: '/v1/progress-workorder/start',
              ),
            ),
          );
        }
        const progressKode = TipeProgressId.kodeMulai;
        formData.fields.addAll([
          MapEntry('workorder_id', workOrderProgress.workOrderId.toString()),
          if (workOrderProgress.tipeProgressId != null)
            MapEntry(
              'tipe_progress_id',
              workOrderProgress.tipeProgressId.toString(),
            ),
          const MapEntry('tipe_progress_kode', progressKode),
          const MapEntry('tipe_progress', progressKode),
          MapEntry(
            'waktu_submit',
            workOrderProgress.submitTime?.toIso8601String() ??
                DateTime.now().toUtc().toIso8601String(),
          ),
        ]);
        response = await post(
          path: '/v1/progress-workorder/start',
          data: formData,
          contentType: ContentType.multipart,
        );
      } else if (isSubmit) {
        if (workOrderProgress.workOrderId == null) {
          return DataFailed(
            DioException(
              error: 'workOrderId wajib diisi untuk endpoint submit progress.',
              requestOptions: RequestOptions(
                path: '/v1/progress-workorder/submit',
              ),
            ),
          );
        }
        if (workOrderProgress.latitude == null ||
            workOrderProgress.longitude == null) {
          return DataFailed(
            DioException(
              error:
                  'Koordinat GPS (latitude & longitude) wajib diisi untuk submit progress. '
                  'Pastikan izin lokasi diaktifkan dan GPS menyala.',
              requestOptions: RequestOptions(
                path: '/v1/progress-workorder/submit',
              ),
            ),
          );
        }
        final progressKode =
            workOrderProgress.tipeProgressId == TipeProgressId.selesai
            ? TipeProgressId.kodeSelesai
            : TipeProgressId.kodeProgress;
        formData.fields.addAll([
          MapEntry('workorder_id', workOrderProgress.workOrderId.toString()),
          MapEntry('tipe_progress_kode', progressKode),
          MapEntry('tipe_progress', progressKode),
        ]);
        response = await post(
          path: '/v1/progress-workorder/submit',
          data: formData,
          contentType: ContentType.multipart,
        );
      } else {
        // Fallback endpoint lama (kompatibilitas)
        response = await post(
          path: '/v1/progress-workorder/${workOrderProgress.id}',
          data: formData,
          contentType: ContentType.multipart,
        );
      }

      final dynamic rawData = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;

      // Handle new response shape: { progress: {...}, workorder: {...} }
      // as well as old shape where data IS the progress directly.
      final dynamic payload;
      if (rawData is Map<String, dynamic> && rawData.containsKey('progress')) {
        payload = rawData['progress'];
      } else {
        payload = rawData;
      }

      final data = payload is Map<String, dynamic>
          ? WorkOrderProgressModel.fromMap(payload)
          : workOrderProgress;
      return DataSuccess(data);
    } catch (e) {
      final dioError = _toDioException(
        e,
        '/v1/progress-workorder/${workOrderProgress.id}',
      );
      _logDioError('updateWorkOrderProgressDetail', dioError);
      return DataFailed(dioError);
    }
  }
}
