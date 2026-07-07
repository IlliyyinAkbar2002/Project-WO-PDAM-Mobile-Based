import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resource/data_state.dart';
import '../../data/models/laporan_workorder_model.dart';
import '../../domain/usecases/create_laporan_workorder_usecase.dart';
import '../../domain/usecases/get_laporan_report_usecase.dart';

abstract class LaporanWorkorderState {}

class LaporanWorkorderInitial extends LaporanWorkorderState {}

class LaporanWorkorderLoading extends LaporanWorkorderState {}

class LaporanWorkorderSuccess extends LaporanWorkorderState {
  final Map<String, dynamic> data;

  LaporanWorkorderSuccess(this.data);
}

class LaporanWorkorderFailed extends LaporanWorkorderState {
  final String message;

  LaporanWorkorderFailed(this.message);
}

class LaporanReportLoading extends LaporanWorkorderState {}

class LaporanReportLoaded extends LaporanWorkorderState {
  final LaporanReportModel report;

  LaporanReportLoaded(this.report);
}

class LaporanReportError extends LaporanWorkorderState {
  final String message;

  LaporanReportError(this.message);
}

class LaporanWorkorderCubit extends Cubit<LaporanWorkorderState> {
  final CreateLaporanWorkorderUseCase _createLaporanWorkorderUseCase;
  final GetLaporanReportUseCase _getLaporanReportUseCase;

  LaporanWorkorderCubit(
    this._createLaporanWorkorderUseCase,
    this._getLaporanReportUseCase,
  ) : super(LaporanWorkorderInitial());

  Future<void> submitLaporan(Map<String, dynamic> payload) async {
    emit(LaporanWorkorderLoading());
    final result = await _createLaporanWorkorderUseCase(payload);
    if (result is DataSuccess) {
      emit(LaporanWorkorderSuccess(result.data?.data ?? {}));
    } else if (result is DataFailed) {
      emit(LaporanWorkorderFailed(result.error?.message ?? 'Unknown Error'));
    }
  }

  Future<void> loadReport(int workorderId) async {
    emit(LaporanReportLoading());
    final result = await _getLaporanReportUseCase(workorderId);
    if (result is DataSuccess) {
      emit(LaporanReportLoaded(result.data as LaporanReportModel));
    } else if (result is DataFailed) {
      emit(LaporanReportError(result.error?.message ?? 'Gagal memuat laporan'));
    }
  }
}
