import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Fetch daftar pegawai dengan filter opsional yang langsung diteruskan
  /// ke endpoint `/v1/pegawai/filter`.
  ///
  /// Setelah perubahan TKT-hirarki di backend, endpoint ini sudah melakukan
  /// clamping berdasar `jabatan_id` user yang login. Parameter di sini
  /// cuma untuk menyempurnakan UX (FE bisa mempersempit lebih jauh bila
  /// perlu); server tetap menjadi sumber kebenaran untuk batas atas.
  Future<DataState<List<UserEntity>>> getUsers({
    int? departemenId,
    List<int>? jabatanIds,
  });
  Future<DataState<UserEntity>> getUserDetail(int id);
}
