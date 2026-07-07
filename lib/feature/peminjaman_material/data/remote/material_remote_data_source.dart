import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/material_model.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/peminjaman_material_model.dart';

class MaterialRemoteDataSource extends RemoteDatasource {
  MaterialRemoteDataSource() : super();

  /// Normalisasi body response jadi List. Toleran terhadap response `show`
  /// yang secara semantik bisa berupa objek tunggal (`{data: {...}}`), bukan
  /// hanya array (`{data: [...]}` / `[...]`), supaya parsing tidak throw.
  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      final data = responseData['data'];
      if (data is List) return data;
      if (data is Map) return [data];
    }
    return const [];
  }

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
      // 1. Fetch all work orders for the current user/spv
      final responseWo = await get(
        path: '/v1/workorder',
        queryParameters: {'all': true},
      );

      final dynamic responseWoData = responseWo.data;
      final List<dynamic> woList;
      if (responseWoData is Map && responseWoData.containsKey('data')) {
        woList = responseWoData['data'] as List;
      } else if (responseWoData is List) {
        woList = responseWoData;
      } else {
        woList = [];
      }

      final List<PeminjamanMaterialModel> combinedResults = [];

      // 2. For each work order, fetch its peminjaman-material
      for (final wo in woList) {
        final woId = wo['id'] as int?;
        if (woId == null) continue;

        try {
          final responsePem = await get(
            path: '/v1/workorder/$woId/peminjaman-material',
          );

          final pemList = _extractList(responsePem.data);

          for (final pem in pemList) {
            final model = PeminjamanMaterialModel.fromMap(
              Map<String, dynamic>.from(pem),
            );
            combinedResults.add(model);
          }
        } catch (e) {
          // Ignore single work order failures to prevent failing the entire list
          debugPrint('Error fetching peminjaman for WO $woId: $e');
        }
      }

      // 3. Filter combined results by status on client-side if status parameter is passed
      List<PeminjamanMaterialModel> finalResult = combinedResults;
      if (status != null) {
        finalResult = combinedResults.where((p) => p.status == status).toList();
      }

      return DataSuccess(finalResult);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/workorder',
            queryParameters: {'all': true},
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
      final dataList = _extractList(response.data);
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
    required String materialKode,
    required int jumlahPinjam,
    String? catatan,
  }) async {
    try {
      final response = await post(
        path: '/v1/workorder/$workOrderId/peminjaman-material',
        data: {
          'material_kode': materialKode,
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
    int jumlahRusak = 0,
    String? kondisiKembali,
  }) async {
    try {
      final response = await post(
        path: '/v1/peminjaman-material/$peminjamanId/kembalikan',
        data: {
          'jumlah_kembali': jumlahKembali,
          'jumlah_rusak': jumlahRusak,
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
