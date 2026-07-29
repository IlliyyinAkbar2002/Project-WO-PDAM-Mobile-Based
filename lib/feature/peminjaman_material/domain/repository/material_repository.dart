import 'package:image_picker/image_picker.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';

abstract class MaterialRepository {
  Future<DataState<List<MaterialEntity>>> getMasterMaterials();
  Future<DataState<List<PeminjamanMaterialEntity>>> getPeminjamanByWo(
    int workOrderId,
  );
  Future<DataState<PeminjamanMaterialEntity>> pinjamMaterial({
    required int workOrderId,
    required String materialKode,
    required int jumlahPinjam,
    String? catatan,
  });
  Future<DataState<PeminjamanMaterialEntity>> kembalikanMaterial({
    required int peminjamanId,
    required int jumlahKembali,
    int jumlahRusak = 0,
    String? kondisiKembali,
    List<XFile> fotoKerusakan = const [],
  });
}
