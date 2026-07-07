import '../../../../core/resource/data_state.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/laporan_workorder_model.dart';
import '../repositories/laporan_workorder_repository.dart';

class GetLaporanReportUseCase
    implements UseCase<Future<DataState<LaporanReportModel>>, int> {
  final LaporanWorkorderRepository repository;

  GetLaporanReportUseCase(this.repository);

  @override
  Future<DataState<LaporanReportModel>> call(int params) {
    return repository.getReportDetail(params);
  }
}
