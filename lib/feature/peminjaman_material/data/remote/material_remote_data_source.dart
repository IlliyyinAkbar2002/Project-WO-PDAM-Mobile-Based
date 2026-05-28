import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/material_model.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/peminjaman_material_model.dart';

class MaterialRemoteDataSource extends RemoteDatasource {
  MaterialRemoteDataSource() : super();

  Future<DataState<List<MaterialModel>>> getMasterMaterials() async {
    try {
      final response = await get(path: '/v1/material');
      final dynamic responseData = response.data;
      final List<dynamic> dataList;
      if (responseData is Map && responseData.containsKey('data')) {
        dataList = responseData['data'] as List;
      } else if (responseData is List) {
        dataList = responseData;
      } else {
        throw Exception(
          'Invalid response format: expected List or Map containing data key',
        );
      }
      final result = dataList
          .map((e) => MaterialModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return DataSuccess(result);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/material'),
        ),
      );
    }
  }

  Future<DataState<List<PeminjamanMaterialModel>>> getAllPeminjaman({
    String? status,
  }) async {
    try {
      final response = await get(
        path: '/v1/peminjaman-material',
        queryParameters: status != null ? {'status': status} : null,
      );
      final dynamic responseData = response.data;
      final List<dynamic> dataList;
      if (responseData is Map && responseData.containsKey('data')) {
        dataList = responseData['data'] as List;
      } else if (responseData is List) {
        dataList = responseData;
      } else {
        throw Exception(
          'Invalid response format: expected List or Map containing data key',
        );
      }
      final result = dataList
          .map(
            (e) =>
                PeminjamanMaterialModel.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList();
      return DataSuccess(result);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/peminjaman-material',
            queryParameters: status != null ? {'status': status} : null,
          ),
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
      final dynamic responseData = response.data;
      final List<dynamic> dataList;
      if (responseData is Map && responseData.containsKey('data')) {
        dataList = responseData['data'] as List;
      } else if (responseData is List) {
        dataList = responseData;
      } else {
        throw Exception(
          'Invalid response format: expected List or Map containing data key',
        );
      }
      final result = dataList
          .map(
            (e) =>
                PeminjamanMaterialModel.fromMap(Map<String, dynamic>.from(e)),
          )
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
    String? catatan,
  }) async {
    try {
      final response = await post(
        path: '/v1/workorder/$workOrderId/peminjaman-material',
        data: {
          'material_kode': materialId,
          'jumlah_pinjam': jumlahPinjam,
          if (catatan != null) 'catatan': catatan,
        },
      );
      final dynamic responseData = response.data;
      final dynamic data;
      if (responseData is Map && responseData.containsKey('data')) {
        data = responseData['data'];
      } else {
        data = responseData;
      }
      return DataSuccess(
        PeminjamanMaterialModel.fromMap(Map<String, dynamic>.from(data)),
      );
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
      final dynamic responseData = response.data;
      final dynamic data;
      if (responseData is Map && responseData.containsKey('data')) {
        data = responseData['data'];
      } else {
        data = responseData;
      }
      return DataSuccess(
        PeminjamanMaterialModel.fromMap(Map<String, dynamic>.from(data)),
      );
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

  Future<DataState<PeminjamanMaterialModel>> verifyReturn({
    required int peminjamanId,
    required String status,
    String? catatanVerifikator,
  }) async {
    try {
      final response = await post(
        path: '/v1/peminjaman-material/$peminjamanId/verify',
        data: {
          'status': status,
          if (catatanVerifikator != null)
            'catatan_verifikator': catatanVerifikator,
        },
      );
      final dynamic responseData = response.data;
      final dynamic data;
      if (responseData is Map && responseData.containsKey('data')) {
        data = responseData['data'];
      } else {
        data = responseData;
      }
      return DataSuccess(
        PeminjamanMaterialModel.fromMap(Map<String, dynamic>.from(data)),
      );
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/peminjaman-material/$peminjamanId/verify',
          ),
        ),
      );
    }
  }
}
