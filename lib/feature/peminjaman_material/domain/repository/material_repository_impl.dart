import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/remote/material_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/repository/material_repository.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  final MaterialRemoteDataSource _remoteDataSource;

  MaterialRepositoryImpl(this._remoteDataSource);

  @override
  Future<DataState<List<MaterialEntity>>> getMasterMaterials() async {
    return await _remoteDataSource.getMasterMaterials();
  }

  @override
  Future<DataState<List<PeminjamanMaterialEntity>>> getPeminjamanByWo(
    int workOrderId,
  ) async {
    return await _remoteDataSource.getPeminjamanByWo(workOrderId);
  }

  @override
  Future<DataState<PeminjamanMaterialEntity>> pinjamMaterial({
    required int workOrderId,
    required String materialKode,
    required int jumlahPinjam,
    String? catatan,
  }) async {
    return await _remoteDataSource.pinjamMaterial(
      workOrderId: workOrderId,
      materialKode: materialKode,
      jumlahPinjam: jumlahPinjam,
      catatan: catatan,
    );
  }

  @override
  Future<DataState<PeminjamanMaterialEntity>> kembalikanMaterial({
    required int peminjamanId,
    required int jumlahKembali,
    int jumlahRusak = 0,
    String? kondisiKembali,
    List<XFile> fotoKerusakan = const [],
  }) async {
    return await _remoteDataSource.kembalikanMaterial(
      peminjamanId: peminjamanId,
      jumlahKembali: jumlahKembali,
      jumlahRusak: jumlahRusak,
      kondisiKembali: kondisiKembali,
      fotoKerusakan: fotoKerusakan,
    );
  }
}
