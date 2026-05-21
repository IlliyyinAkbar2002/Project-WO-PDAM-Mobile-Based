import 'package:dio/dio.dart';

import '../../../../core/resource/data_state.dart';

abstract class LaporanWorkorderRepository {
  Future<DataState<Response>> createLaporanWorkorder(Map<String, dynamic> payload);
}
