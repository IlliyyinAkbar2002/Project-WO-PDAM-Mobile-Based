import 'package:equatable/equatable.dart';

abstract class MaterialEvent extends Equatable {
  const MaterialEvent();

  @override
  List<Object?> get props => [];
}

class GetMasterMaterialsEvent extends MaterialEvent {}

class GetPeminjamanByWoEvent extends MaterialEvent {
  final int workOrderId;
  const GetPeminjamanByWoEvent(this.workOrderId);

  @override
  List<Object?> get props => [workOrderId];
}

class PinjamMaterialEvent extends MaterialEvent {
  final int workOrderId;
  final int materialId;
  final int jumlahPinjam;
  final String? catatan;

  const PinjamMaterialEvent({
    required this.workOrderId,
    required this.materialId,
    required this.jumlahPinjam,
    this.catatan,
  });

  @override
  List<Object?> get props => [workOrderId, materialId, jumlahPinjam, catatan];
}

class KembalikanMaterialEvent extends MaterialEvent {
  final int peminjamanId;
  final int jumlahKembali;
  final String? kondisiKembali;

  const KembalikanMaterialEvent({
    required this.peminjamanId,
    required this.jumlahKembali,
    this.kondisiKembali,
  });

  @override
  List<Object?> get props => [peminjamanId, jumlahKembali, kondisiKembali];
}
