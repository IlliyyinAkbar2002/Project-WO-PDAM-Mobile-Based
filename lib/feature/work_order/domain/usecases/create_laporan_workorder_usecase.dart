import 'package:dio/dio.dart';

import '../../../../core/resource/data_state.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/laporan_workorder_repository.dart';

class CreateLaporanWorkorderUseCase
    implements UseCase<Future<DataState<Response>>, Map<String, dynamic>> {
  final LaporanWorkorderRepository repository;

  CreateLaporanWorkorderUseCase(this.repository);

  @override
  Future<DataState<Response>> call(Map<String, dynamic> params) {
    return repository.createLaporanWorkorder(params);
  }
}
