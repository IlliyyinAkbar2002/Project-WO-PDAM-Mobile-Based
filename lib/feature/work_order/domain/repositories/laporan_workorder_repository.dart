import 'package:dio/dio.dart';

import '../../../../core/resource/data_state.dart';
import '../../data/models/laporan_workorder_model.dart';

abstract class LaporanWorkorderRepository {
  Future<DataState<Response>> createLaporanWorkorder(Map<String, dynamic> payload);

  Future<DataState<LaporanReportModel>> getReportDetail(int workorderId);
}
