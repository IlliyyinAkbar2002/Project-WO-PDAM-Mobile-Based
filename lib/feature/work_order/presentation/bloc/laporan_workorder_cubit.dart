import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resource/data_state.dart';
import '../../domain/usecases/create_laporan_workorder_usecase.dart';

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

class LaporanWorkorderCubit extends Cubit<LaporanWorkorderState> {
  final CreateLaporanWorkorderUseCase _createLaporanWorkorderUseCase;

  LaporanWorkorderCubit(this._createLaporanWorkorderUseCase)
    : super(LaporanWorkorderInitial());

  Future<void> submitLaporan(Map<String, dynamic> payload) async {
    emit(LaporanWorkorderLoading());
    final result = await _createLaporanWorkorderUseCase(payload);
    if (result is DataSuccess) {
      emit(LaporanWorkorderSuccess(result.data?.data ?? {}));
    } else if (result is DataFailed) {
      emit(LaporanWorkorderFailed(result.error?.message ?? 'Unknown Error'));
    }
  }
}
