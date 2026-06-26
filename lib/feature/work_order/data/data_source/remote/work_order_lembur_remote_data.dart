import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/constants/work_order_constants.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/work_order_progress_model.dart';

import 'package:project_mobile_pdam/feature/work_order/data/models/progress_by_member_model.dart';

class WorkOrderLemburRemoteDataSource extends RemoteDatasource {
  WorkOrderLemburRemoteDataSource() : super();

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
    // For lembur, decision must be 'accept' or 'reject'
    if (normalized == 'accept' ||
        normalized == 'terima' ||
        normalized == 'approve' ||
        normalized == 'setuju') {
      return 'accept';
    } else if (normalized == 'reject' ||
        normalized == 'tolak' ||
        normalized == 'rejected' ||
        normalized == 'revisi') {
      return 'reject';
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
      final response = await get(
        path: '/v1/progress-lembur',
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
        return DataSuccess(data);
      }

      return const DataSuccess(<WorkOrderProgressModel>[]);
    } catch (e, st) {
      final dioError = _toDioException(e, '/v1/progress-lembur');
      _logDioError('fetchProgressByWorkOrderId', dioError);
      debugPrint("❌ fetchProgressByWorkOrderId stack: $st");
      return DataFailed(dioError);
    }
  }

  Future<DataState<WorkOrderProgressModel>> getWorkOrderProgressDetail(
    int id,
  ) async {
    try {
      final response = await get(path: '/v1/progress-lembur/$id');
      final payload = _extractProgressPayload(response.data);
      final data = WorkOrderProgressModel.fromMap(payload);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/progress-lembur/$id'),
        ),
      );
    }
  }

  Future<DataState<WorkOrderProgressModel>> resubmitProgress(
    WorkOrderProgressModel workOrderProgress,
  ) async {
    try {
      final formData = FormData();
      formData.fields.add(
        MapEntry('progress_id', workOrderProgress.id.toString()),
      );
      formData.fields.add(
        MapEntry('hasil_pengerjaan', workOrderProgress.description ?? ''),
      );
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
      if (workOrderProgress.tahapan != null) {
        formData.fields.add(
          MapEntry('tahapan', workOrderProgress.tahapan.toString()),
        );
      }

      if (workOrderProgress.photos != null &&
          workOrderProgress.photos!.isNotEmpty) {
        for (var photo in workOrderProgress.photos!) {
          try {
            final file = File(photo.path);
            if (await file.exists()) {
              formData.files.add(
                MapEntry(
                  'foto[]',
                  await MultipartFile.fromFile(
                    photo.path,
                    filename: basename(photo.path),
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint("❌ Error adding file ${photo.path}: $e");
          }
        }
      }

      if (workOrderProgress.kategoriData != null) {
        workOrderProgress.kategoriData!.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              final y = value.year.toString().padLeft(4, '0');
              final m = value.month.toString().padLeft(2, '0');
              final d = value.day.toString().padLeft(2, '0');
              formData.fields.add(MapEntry(key, '$y-$m-$d'));
            } else {
              formData.fields.add(MapEntry(key, value.toString()));
            }
          }
        });
      }

      final response = await post(
        path: '/v1/progress-lembur/resubmit',
        data: formData,
        contentType: ContentType.multipart,
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
      final dioError = _toDioException(e, '/v1/progress-lembur/resubmit');
      _logDioError('resubmitProgress', dioError);
      return DataFailed(dioError);
    }
  }

  Future<DataState<List<dynamic>>> getProgressDetailsHistory(
    int progressWorkorderId,
  ) async {
    try {
      final response = await get(
        path: '/v1/progress-detail-lembur',
        queryParameters: {'progress_workorder_id': progressWorkorderId},
      );
      final dynamic raw = response.data;
      debugPrint(
        "📥 getProgressDetailsHistory($progressWorkorderId) raw: $raw",
      );

      final dynamic payload = raw is Map<String, dynamic>
          ? (raw['data'] ?? raw)
          : raw;
      if (payload is List) {
        return DataSuccess(payload);
      }
      return const DataSuccess([]);
    } catch (e) {
      final dioError = _toDioException(e, '/v1/progress-detail-lembur');
      _logDioError('getProgressDetailsHistory', dioError);
      return DataFailed(dioError);
    }
  }

  Future<DataState<WorkOrderProgressModel>> updateWorkOrderProgressDetail(
    WorkOrderProgressModel workOrderProgress,
  ) async {
    try {
      final formData = FormData();

      formData.fields.add(
        MapEntry('hasil_pengerjaan', workOrderProgress.description ?? ''),
      );

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
      if (workOrderProgress.tahapan != null) {
        formData.fields.add(
          MapEntry('tahapan', workOrderProgress.tahapan.toString()),
        );
      }

      if (workOrderProgress.photos != null &&
          workOrderProgress.photos!.isNotEmpty) {
        for (var photo in workOrderProgress.photos!) {
          try {
            final file = File(photo.path);
            if (await file.exists()) {
              formData.files.add(
                MapEntry(
                  'foto[]',
                  await MultipartFile.fromFile(
                    photo.path,
                    filename: basename(photo.path),
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint("❌ Error adding file ${photo.path}: $e");
          }
        }
      }

      final progressDetails = workOrderProgress.progressDetails ?? const [];
      for (int i = 0; i < progressDetails.length; i++) {
        final detailItem = progressDetails[i];
        if (detailItem.detailFormId == null) {
          return DataFailed(
            DioException(
              error:
                  'detail_form_id wajib diisi untuk item detail_progress index $i.',
              requestOptions: RequestOptions(
                path: '/v1/progress-lembur/${workOrderProgress.id}',
              ),
            ),
          );
        }

        formData.fields.add(
          MapEntry(
            'detail_progress[$i][detail_form_id]',
            detailItem.detailFormId.toString(),
          ),
        );

        String valueForPayload;
        if (detailItem.image != null) {
          valueForPayload = "";
        } else {
          valueForPayload = detailItem.value ?? "";
        }
        formData.fields.add(
          MapEntry('detail_progress[$i][value]', valueForPayload),
        );
      }

      if (progressDetails.isNotEmpty) {
        for (var detail in progressDetails) {
          if (detail.image != null && detail.detailFormId != null) {
            try {
              final file = File(detail.image!.path);
              if (await file.exists()) {
                formData.files.add(
                  MapEntry(
                    'detail_progress_images[${detail.detailFormId}]',
                    await MultipartFile.fromFile(
                      detail.image!.path,
                      filename: basename(detail.image!.path),
                    ),
                  ),
                );
              }
            } catch (e) {
              debugPrint("❌ Error adding image ${detail.image!.path}: $e");
            }
          }
        }
      }

      late final Response response;
      final bool isStart =
          workOrderProgress.id == null && workOrderProgress.tipeProgressId == 1;
      final bool isSubmit =
          workOrderProgress.id == null &&
          (workOrderProgress.tipeProgressId == 2 ||
              workOrderProgress.tipeProgressId == 3 ||
              workOrderProgress.tipeProgressId == 6);
      final bool isReview = workOrderProgress.reviewAction != null;

      if (isReview) {
        if (workOrderProgress.id == null) {
          return DataFailed(
            DioException(
              error: 'progressId wajib diisi untuk endpoint review progress.',
              requestOptions: RequestOptions(
                path: '/v1/progress-lembur/review',
              ),
            ),
          );
        }
        final decision = _normalizeReviewDecision(
          workOrderProgress.reviewAction!,
        );

        final String note = (workOrderProgress.description ?? '').trim();
        formData.fields.add(
          MapEntry('progress_id', workOrderProgress.id.toString()),
        );
        formData.fields.add(MapEntry('decision', decision));
        if (note.isNotEmpty) {
          if (decision == 'accept') {
            formData.fields.add(MapEntry('approval_notes', note));
          } else {
            formData.fields.add(MapEntry('alasan_penolakan', note));
          }
        }
        response = await post(
          path: '/v1/progress-lembur/review',
          data: formData,
          contentType: ContentType.multipart,
        );
      } else if (isStart) {
        if (workOrderProgress.workOrderId == null) {
          return DataFailed(
            DioException(
              error: 'workOrderId wajib diisi untuk endpoint start progress.',
              requestOptions: RequestOptions(path: '/v1/progress-lembur/start'),
            ),
          );
        }
        if (workOrderProgress.latitude == null ||
            workOrderProgress.longitude == null) {
          return DataFailed(
            DioException(
              error: 'Koordinat GPS wajib diisi untuk memulai progress.',
              requestOptions: RequestOptions(path: '/v1/progress-lembur/start'),
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
        if (workOrderProgress.kategoriData != null) {
          workOrderProgress.kategoriData!.forEach((key, value) {
            if (value != null) {
              if (value is DateTime) {
                final y = value.year.toString().padLeft(4, '0');
                final m = value.month.toString().padLeft(2, '0');
                final d = value.day.toString().padLeft(2, '0');
                formData.fields.add(MapEntry(key, '$y-$m-$d'));
              } else {
                formData.fields.add(MapEntry(key, value.toString()));
              }
            }
          });
        }
        response = await post(
          path: '/v1/progress-lembur/start',
          data: formData,
          contentType: ContentType.multipart,
        );
      } else if (isSubmit) {
        if (workOrderProgress.workOrderId == null) {
          return DataFailed(
            DioException(
              error: 'workOrderId wajib diisi untuk endpoint submit progress.',
              requestOptions: RequestOptions(
                path: '/v1/progress-lembur/submit',
              ),
            ),
          );
        }
        if (workOrderProgress.latitude == null ||
            workOrderProgress.longitude == null) {
          return DataFailed(
            DioException(
              error: 'Koordinat GPS wajib diisi untuk submit progress.',
              requestOptions: RequestOptions(
                path: '/v1/progress-lembur/submit',
              ),
            ),
          );
        }
        final progressKode =
            workOrderProgress.tipeProgressId == TipeProgressId.selesai
            ? TipeProgressId.kodeSelesai
            : (workOrderProgress.tipeProgressId == TipeProgressId.inspeksi
                  ? TipeProgressId.kodeInspeksi
                  : TipeProgressId.kodeProgress);
        formData.fields.addAll([
          MapEntry('workorder_id', workOrderProgress.workOrderId.toString()),
          MapEntry('tipe_progress_kode', progressKode),
          MapEntry('tipe_progress', progressKode),
        ]);
        if (workOrderProgress.kategoriData != null) {
          workOrderProgress.kategoriData!.forEach((key, value) {
            if (value != null) {
              if (value is DateTime) {
                final y = value.year.toString().padLeft(4, '0');
                final m = value.month.toString().padLeft(2, '0');
                final d = value.day.toString().padLeft(2, '0');
                formData.fields.add(MapEntry(key, '$y-$m-$d'));
              } else {
                formData.fields.add(MapEntry(key, value.toString()));
              }
            }
          });
        }
        response = await post(
          path: '/v1/progress-lembur/submit',
          data: formData,
          contentType: ContentType.multipart,
        );
      } else {
        response = await post(
          path: '/v1/progress-lembur/${workOrderProgress.id}',
          data: formData,
          contentType: ContentType.multipart,
        );
      }

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
          : workOrderProgress;
      return DataSuccess(data);
    } catch (e) {
      final dioError = _toDioException(
        e,
        '/v1/progress-lembur/${workOrderProgress.id}',
      );
      _logDioError('updateWorkOrderProgressDetail', dioError);
      return DataFailed(dioError);
    }
  }

  Future<DataState<ProgressByMemberModel>> getProgressByMember(
    int workOrderId,
  ) async {
    try {
      final response = await get(
        path: '/v1/progress-lembur/by-member/$workOrderId',
      );
      final dynamic raw = response.data;
      debugPrint("👥 getProgressByMember($workOrderId) raw: $raw");

      final Map<String, dynamic> payload;
      if (raw is Map<String, dynamic>) {
        payload = raw['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(raw['data'])
            : Map<String, dynamic>.from(raw);
      } else {
        throw const FormatException(
          'Format progress by member tidak dikenali.',
        );
      }

      final data = ProgressByMemberModel.fromMap(payload);
      return DataSuccess(data);
    } catch (e) {
      final dioError = _toDioException(
        e,
        '/v1/progress-lembur/by-member/$workOrderId',
      );
      _logDioError('getProgressByMember', dioError);
      return DataFailed(dioError);
    }
  }
}
