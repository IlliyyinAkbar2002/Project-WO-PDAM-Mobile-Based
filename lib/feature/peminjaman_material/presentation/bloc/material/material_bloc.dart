import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/get_master_materials.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/get_peminjaman_by_wo.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/pinjam_material.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/usecases_material/kembalikan_material.dart';
import 'package:project_mobile_pdam/core/usecase/usecase.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_event.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/bloc/material/material_state.dart';

class MaterialBloc extends Bloc<MaterialEvent, MaterialState> {
  final GetMasterMaterials getMasterMaterials;
  final GetPeminjamanByWo getPeminjamanByWo;
  final PinjamMaterial pinjamMaterial;
  final KembalikanMaterial kembalikanMaterial;

  MaterialBloc({
    required this.getMasterMaterials,
    required this.getPeminjamanByWo,
    required this.pinjamMaterial,
    required this.kembalikanMaterial,
  }) : super(MaterialInitial()) {
    on<GetMasterMaterialsEvent>(_onGetMasterMaterials);
    on<GetPeminjamanByWoEvent>(_onGetPeminjamanByWo);
    on<PinjamMaterialEvent>(_onPinjamMaterial);
    on<KembalikanMaterialEvent>(_onKembalikanMaterial);
  }

  Future<void> _onGetMasterMaterials(
    GetMasterMaterialsEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialLoading());
    final result = await getMasterMaterials(const NoParams());
    if (result is DataSuccess && result.data != null) {
      emit(MasterMaterialsLoaded(result.data!));
    } else {
      emit(
        MaterialError(result.error?.message ?? 'Gagal mengambil data material'),
      );
    }
  }

  Future<void> _onGetPeminjamanByWo(
    GetPeminjamanByWoEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialLoading());
    final result = await getPeminjamanByWo(event.workOrderId);
    if (result is DataSuccess && result.data != null) {
      emit(PeminjamanLoaded(result.data!));
    } else {
      emit(
        MaterialError(
          result.error?.message ?? 'Gagal mengambil histori peminjaman',
        ),
      );
    }
  }

  Future<void> _onPinjamMaterial(
    PinjamMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialLoading());
    final result = await pinjamMaterial(
      PinjamMaterialParams(
        workOrderId: event.workOrderId,
        materialKode: event.materialKode,
        jumlahPinjam: event.jumlahPinjam,
        catatan: event.catatan,
      ),
    );
    if (result is DataSuccess && result.data != null) {
      emit(MaterialActionSuccess('Berhasil meminjam material', result.data!));
    } else {
      emit(MaterialError(result.error?.message ?? 'Gagal meminjam material'));
    }
  }

  Future<void> _onKembalikanMaterial(
    KembalikanMaterialEvent event,
    Emitter<MaterialState> emit,
  ) async {
    emit(MaterialLoading());
    final result = await kembalikanMaterial(
      KembalikanMaterialParams(
        peminjamanId: event.peminjamanId,
        jumlahKembali: event.jumlahKembali,
        jumlahRusak: event.jumlahRusak,
        kondisiKembali: event.kondisiKembali,
        fotoKerusakan: event.fotoKerusakan,
      ),
    );
    if (result is DataSuccess && result.data != null) {
      emit(
        MaterialActionSuccess('Berhasil mengembalikan material', result.data!),
      );
    } else {
      emit(
        MaterialError(result.error?.message ?? 'Gagal mengembalikan material'),
      );
    }
  }
}
