import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/material_model.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/peminjaman_material_model.dart';

class MaterialRemoteDataSource extends RemoteDatasource {
  MaterialRemoteDataSource() : super();

  Future<DataState<List<MaterialModel>>> getMasterMaterials() async {
    try {
      final response = await get(path: '/v1/master/material');
      final data = response.data['data'] as List;
      final result = data.map((e) => MaterialModel.fromMap(e)).toList();
      return DataSuccess(result);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/master/material'),
        ),
      );
    }
  }

  Future<DataState<List<PeminjamanMaterialModel>>> getPeminjamanByWo(
    int workOrderId,
  ) async {
    try {
      final response = await get(
        path: '/v1/workorder/$workOrderId/peminjaman-material',
      );
      final data = response.data['data'] as List;
      final result = data
          .map((e) => PeminjamanMaterialModel.fromMap(e))
          .toList();
      return DataSuccess(result);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/workorder/$workOrderId/peminjaman-material',
          ),
        ),
      );
    }
  }

  Future<DataState<PeminjamanMaterialModel>> pinjamMaterial({
    required int workOrderId,
    required int materialId,
    required int jumlahPinjam,
  }) async {
    try {
      final response = await post(
        path: '/v1/workorder/$workOrderId/peminjaman-material',
        data: {'material_id': materialId, 'jumlah_pinjam': jumlahPinjam},
      );
      final data = response.data['data'];
      return DataSuccess(PeminjamanMaterialModel.fromMap(data));
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/workorder/$workOrderId/peminjaman-material',
          ),
        ),
      );
    }
  }

  Future<DataState<PeminjamanMaterialModel>> kembalikanMaterial({
    required int peminjamanId,
    required int jumlahKembali,
    String? kondisiKembali,
  }) async {
    try {
      final response = await post(
        path: '/v1/peminjaman-material/$peminjamanId/kembalikan',
        data: {
          'jumlah_kembali': jumlahKembali,
          if (kondisiKembali != null) 'kondisi_kembali': kondisiKembali,
        },
      );
      final data = response.data['data'];
      return DataSuccess(PeminjamanMaterialModel.fromMap(data));
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/peminjaman-material/$peminjamanId/kembalikan',
          ),
        ),
      );
    }
  }
}
