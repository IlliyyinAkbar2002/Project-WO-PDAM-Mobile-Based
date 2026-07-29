import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

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
  final String materialKode;
  final int jumlahPinjam;
  final String? catatan;

  const PinjamMaterialEvent({
    required this.workOrderId,
    required this.materialKode,
    required this.jumlahPinjam,
    this.catatan,
  });

  @override
  List<Object?> get props => [workOrderId, materialKode, jumlahPinjam, catatan];
}

class KembalikanMaterialEvent extends MaterialEvent {
  final int peminjamanId;
  final int jumlahKembali;
  final int jumlahRusak;
  final String? kondisiKembali;

  /// Foto bukti kerusakan yang dipilih staf (belum terunggah). Dikirim sebagai
  /// multipart `foto_kerusakan[]` oleh remote data source.
  final List<XFile> fotoKerusakan;

  const KembalikanMaterialEvent({
    required this.peminjamanId,
    required this.jumlahKembali,
    this.jumlahRusak = 0,
    this.kondisiKembali,
    this.fotoKerusakan = const [],
  });

  @override
  List<Object?> get props => [
    peminjamanId,
    jumlahKembali,
    jumlahRusak,
    kondisiKembali,
    fotoKerusakan,
  ];
}
