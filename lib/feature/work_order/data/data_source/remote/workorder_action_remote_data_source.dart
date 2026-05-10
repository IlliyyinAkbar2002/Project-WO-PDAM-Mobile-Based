import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/resource/remote_data_source.dart';

/// Data source untuk endpoint **TKT-06 / pasca route-refactor**:
///   - `GET  /v1/workorder-action`   → list action (index backend masih
///     skeleton — kita tetap expose supaya future-ready).
///   - `POST /v1/workorder-action`   → freeze / resume / extend.
///
/// Catatan penting (lihat `Guide_mobile_flutter.md` §3.5):
/// - Payload **TIDAK** boleh membawa `actor_id`. Backend otomatis meng-
///   inject dari `auth()->user()->id`. Kalau Flutter tetap kirim, akan
///   di-abaikan (no-op), tidak error.
/// - Nilai `action_id` tetap id numerik master `m_action`. Kalau suatu
///   saat backend menerima `kode` (PENUGASAN/FREEZE/RESUME/EXTEND) di
///   body, tinggal extend method `createAction` dengan parameter `kode`.
class WorkOrderActionRemoteDataSource extends RemoteDatasource {
  WorkOrderActionRemoteDataSource() : super();

  /// Buat record workorder_action baru.
  ///
  /// Field wajib: [workorderId], [actionId], [waktuMulai].
  /// Field opsional: [keterangan], [sisaDurasiMenit], [estimasiSelesai].
  Future<DataState<Map<String, dynamic>>> createAction({
    required int workorderId,
    required int actionId,
    required DateTime waktuMulai,
    String? keterangan,
    int? sisaDurasiMenit,
    DateTime? estimasiSelesai,
  }) async {
    try {
      final payload = <String, dynamic>{
        'workorder_id': workorderId,
        'action_id': actionId,
        'waktu_mulai': waktuMulai.toIso8601String(),
        if (keterangan != null) 'keterangan': keterangan,
        if (sisaDurasiMenit != null) 'sisa_durasi_menit': sisaDurasiMenit,
        if (estimasiSelesai != null)
          'estimasi_selesai': estimasiSelesai.toIso8601String(),
      };

      final response = await post(
        path: '/v1/workorder-action',
        data: payload,
      );

      final dynamic data = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;

      return DataSuccess(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder-action'),
        ),
      );
    }
  }

  /// List action untuk satu workorder (atau seluruhnya). Backend index
  /// masih minimal, tapi endpoint sudah terdaftar — aman dipanggil.
  Future<DataState<List<Map<String, dynamic>>>> fetchActions({
    int? workorderId,
  }) async {
    try {
      final response = await get(
        path: '/v1/workorder-action',
        queryParameters: {
          if (workorderId != null) 'workorder_id': workorderId,
        },
      );

      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      final List<Map<String, dynamic>> parsed = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      return DataSuccess(parsed);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder-action'),
        ),
      );
    }
  }
}
