import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/resource/api_exception.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_work_order_lembur_progress_detail_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_work_order_lembur_progresses_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/update_work_order_lembur_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/resubmit_lembur_progress_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/work_order_lembur_progress_usecases/get_lembur_progress_by_member_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/repositories/work_order_lembur_repository.dart';
import 'lembur_event.dart';
import 'lembur_state.dart';

class LemburBloc extends Bloc<LemburEvent, LemburState> {
  final GetLemburProgressByWorkOrderIdUsecase
  getLemburProgressByWorkOrderIdUsecase;
  final GetWorkOrderLemburProgressDetailUsecase
  getWorkOrderLemburProgressDetailUsecase;
  final UpdateWorkOrderLemburProgressUseCase
  updateWorkOrderLemburProgressUseCase;
  final ResubmitLemburProgressUseCase resubmitLemburProgressUseCase;
  final GetLemburProgressByMemberUseCase getLemburProgressByMemberUseCase;
  final WorkOrderLemburRepository workOrderLemburRepository;

  LemburBloc({
    required this.getLemburProgressByWorkOrderIdUsecase,
    required this.getWorkOrderLemburProgressDetailUsecase,
    required this.updateWorkOrderLemburProgressUseCase,
    required this.resubmitLemburProgressUseCase,
    required this.getLemburProgressByMemberUseCase,
    required this.workOrderLemburRepository,
  }) : super(LemburInitial()) {
    on<GetLemburProgressByWorkOrderIdEvent>(_onGetLemburProgressByWorkOrderId);
    on<GetLemburProgressDetailEvent>(_onGetLemburProgressDetail);
    on<UpdateLemburProgressEvent>(_onUpdateLemburProgress);
    on<ResubmitLemburProgressEvent>(_onResubmitLemburProgress);
    on<CancelLemburProgressEvent>(_onCancelLemburProgress);
    on<GetLemburProgressByMemberEvent>(_onGetLemburProgressByMember);
    on<GetLemburProgressDetailsHistoryEvent>(
      _onGetLemburProgressDetailsHistory,
    );
  }

  String _friendlyErrorMessage(dynamic error) {
    if (error is DioException) {
      final apiError = error.error;
      if (apiError is ApiException) {
        return _safeApiErrorMessage(apiError);
      }
      final data = error.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
        final message = data['message'] ?? data['error'];
        if (message != null) return message.toString();
      }
      if (data is String && data.isNotEmpty) return data;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Koneksi ke server terlalu lama. Silakan coba lagi.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      }
      return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
    }
    if (error is ApiException) {
      return _safeApiErrorMessage(error);
    }
    return error?.toString() ?? 'Terjadi kesalahan tidak diketahui.';
  }

  String _safeApiErrorMessage(ApiException error) {
    if (error.isServerError) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
    final joined = error.allErrorsJoined();
    if (joined.isNotEmpty && joined != error.message) {
      return joined;
    }
    return error.message;
  }

  Future<void> _onGetLemburProgressByWorkOrderId(
    GetLemburProgressByWorkOrderIdEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await getLemburProgressByWorkOrderIdUsecase(
        event.workOrderId,
      );
      if (dataState is DataSuccess) {
        emit(LemburProgressesLoaded(dataState.data!));
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal mengambil progres lembur: $e"));
    }
  }

  Future<void> _onGetLemburProgressDetail(
    GetLemburProgressDetailEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await getWorkOrderLemburProgressDetailUsecase(event.id);
      if (dataState is DataSuccess) {
        emit(LemburProgressDetailLoaded(dataState.data!));
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal mengambil detail progres lembur: $e"));
    }
  }

  Future<void> _onUpdateLemburProgress(
    UpdateLemburProgressEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await updateWorkOrderLemburProgressUseCase(
        event.progress,
      );
      if (dataState is DataSuccess) {
        emit(LemburProgressUpdated(dataState.data!));
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal memperbarui progres lembur: $e"));
    }
  }

  Future<void> _onResubmitLemburProgress(
    ResubmitLemburProgressEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await resubmitLemburProgressUseCase(event.progress);
      if (dataState is DataSuccess) {
        emit(LemburProgressUpdated(dataState.data!));
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal resubmit progres lembur: $e"));
    }
  }

  Future<void> _onCancelLemburProgress(
    CancelLemburProgressEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await workOrderLemburRepository.cancelProgress(
        event.progressId,
      );
      if (dataState is DataSuccess) {
        emit(LemburCancelProgressSuccess());
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal membatalkan progres: $e"));
    }
  }

  Future<void> _onGetLemburProgressByMember(
    GetLemburProgressByMemberEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await getLemburProgressByMemberUseCase(
        event.workOrderId,
      );
      if (dataState is DataSuccess) {
        emit(LemburProgressByMemberLoaded(dataState.data!));
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal mengambil progress lembur per anggota: $e"));
    }
  }

  Future<void> _onGetLemburProgressDetailsHistory(
    GetLemburProgressDetailsHistoryEvent event,
    Emitter<LemburState> emit,
  ) async {
    emit(LemburLoading());
    try {
      final dataState = await workOrderLemburRepository
          .getProgressDetailsHistory(event.progressWorkorderId);
      if (dataState is DataSuccess) {
        emit(LemburProgressDetailsHistoryLoaded(dataState.data!));
      } else if (dataState is DataFailed) {
        emit(LemburError(_friendlyErrorMessage(dataState.error)));
      }
    } catch (e) {
      emit(LemburError("Gagal mengambil history progres: $e"));
    }
  }
}
