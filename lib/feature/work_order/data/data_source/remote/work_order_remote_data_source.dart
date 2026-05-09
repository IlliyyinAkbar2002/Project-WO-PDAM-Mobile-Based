import 'package:dio/dio.dart';
import '/core/resource/data_state.dart';
import '/feature/work_order/data/models/work_order_model.dart';
import '/core/resource/remote_data_source.dart';

class WorkOrderRemoteDataSource extends RemoteDatasource {
  WorkOrderRemoteDataSource() : super();

  Map<String, dynamic> _extractWorkOrderPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final dynamic data = raw['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first as Map);
      }
      if (raw.containsKey('id')) {
        return Map<String, dynamic>.from(raw);
      }
    }

    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }

    throw const FormatException('Format detail work order tidak dikenali.');
  }

  Future<DataState<List<WorkOrderModel>>> fetchWorkOrders(
    int page,
    int limit,
    List<int>? status,
    List<int>? excludeStatus,
    int? picId,
    int? userId,
    int? type,
    String? dateRange,
    String? startDate,
    String? endDate,
    String? search,
  ) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.join(','),
        if (excludeStatus != null) 'exclude_status': excludeStatus.join(','),
        // pic_id tidak dikirim - backend otomatis filter berdasarkan authenticated user
        if (userId != null) 'user_id': userId,
        if (type != null) 'type': type,
        if (dateRange != null) 'date_range': dateRange,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (search != null) 'search': search,
      };

      // Use parent class's get() method which includes auth headers
      final response = await get(
        path: '/v1/workorder',
        queryParameters: queryParameters,
      );
      final data = response.data['data']
          .map<WorkOrderModel>((json) => WorkOrderModel.fromMap(json))
          .toList();
      final totalPages = response.data['totalPages'];
      final currentPage = response.data['currentPage'];
      return PaginatedDataSuccess(
        data,
        totalPages: totalPages,
        currentPage: currentPage,
      );
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder'),
        ),
      );
    }
  }

  Future<DataState<WorkOrderModel>> fetchWorkOrderDetail(int id) async {
    try {
      // Use parent class's get() method which includes auth headers
      final response = await get(path: '/v1/workorder/$id');
      final Map<String, dynamic> payload = _extractWorkOrderPayload(
        response.data,
      );
      final data = WorkOrderModel.fromMap(payload);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder/$id'),
        ),
      );
    }
  }

  Future<DataState<WorkOrderModel>> createWorkOrder(
    WorkOrderModel workOrder,
  ) async {
    try {
      print("📤 Mengirim request ke API: ${dio.options.baseUrl}/v1/workorder");
      print("📤 Data yang dikirim: ${workOrder.toMap()}");

      final response = await post(
        path: '/v1/workorder',
        data: workOrder.toMap(),
      );
      print("📥 Response: ${response.statusCode} - ${response.data}");

      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;

      final Map<String, dynamic> first = raw is List
          ? (raw.isNotEmpty ? Map<String, dynamic>.from(raw.first) : {})
          : Map<String, dynamic>.from(raw as Map);

      if (first.isEmpty) {
        return DataFailed(
          DioException(
            error: 'Server mengembalikan data kosong setelah membuat WO.',
            requestOptions: RequestOptions(path: '/v1/workorder'),
          ),
        );
      }

      final data = WorkOrderModel.fromMap(first);
      return DataSuccess(data);
    } on DioException catch (e) {
      print(
        "❌ Gagal membuat WO: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder'),
        ),
      );
    }
  }

  Future<DataState<WorkOrderModel>> updateWorkOrder(
    WorkOrderModel workOrder,
  ) async {
    try {
      // Use parent class's put() method which includes auth headers
      final response = await put(
        path: '/v1/mobile/workorder/${workOrder.id}',
        data: workOrder.toMap(),
      );
      final data = WorkOrderModel.fromMap(response.data);
      return DataSuccess(data);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder/${workOrder.id}'),
        ),
      );
    }
  }

  Future<DataState<void>> deleteWorkOrder(int id) async {
    try {
      // Use parent class's delete() method which includes auth headers
      await delete(path: '/v1/workorder/$id');
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(path: '/v1/workorder/$id'),
        ),
      );
    }
  }

  Future<DataState<void>> assignStaff({
    required int workOrderId,
    required List<int> staffIds,
    required String nomorMeter,
    required String kondisiMeterAwal,
  }) async {
    try {
      final petugas = staffIds.asMap().entries.map((entry) {
        return {
          'user_id': entry.value,
          'peran': entry.key == 0 ? 'koordinator' : 'anggota',
        };
      }).toList();

      await post(
        path: '/v1/workorder/$workOrderId/assign-staff',
        data: {
          'form_kategori': {
            'nomor_meter': nomorMeter,
            'kondisi_meter_awal': kondisiMeterAwal,
          },
          'petugas': petugas,
        },
      );
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(
          error: e,
          requestOptions: RequestOptions(
            path: '/v1/workorder/$workOrderId/assign-staff',
          ),
        ),
      );
    }
  }
}
