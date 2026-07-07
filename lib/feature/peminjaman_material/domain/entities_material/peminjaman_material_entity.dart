import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/user_entity.dart';

class PeminjamanMaterialEntity extends Equatable {
  final int? id;
  final int? workorderId;
  final String? materialKode;
  final int? userId;
  final int? jumlahPinjam;
  final DateTime? waktuPinjam;
  final int? jumlahKembali;
  final int? jumlahRusak;

  /// Jumlah material yang terpasang/dikonsumsi permanen (= jumlah_pinjam −
  /// jumlah_kembali). Nullable: `null` saat status `DIPINJAM` dan setelah
  /// verifikasi `REJECTED`; terisi mulai `PENDING_KEMBALI` dan `DIKEMBALIKAN`.
  final int? jumlahTerpasang;
  final DateTime? waktuKembali;
  final String? kondisiKembali;
  final String? status;
  final MaterialEntity? material;
  final UserEntity? user;

  const PeminjamanMaterialEntity({
    this.id,
    this.workorderId,
    this.materialKode,
    this.userId,
    this.jumlahPinjam,
    this.waktuPinjam,
    this.jumlahKembali,
    this.jumlahRusak,
    this.jumlahTerpasang,
    this.waktuKembali,
    this.kondisiKembali,
    this.status,
    this.material,
    this.user,
  });

  @override
  List<Object?> get props => [
    id,
    workorderId,
    materialKode,
    userId,
    jumlahPinjam,
    waktuPinjam,
    jumlahKembali,
    jumlahRusak,
    jumlahTerpasang,
    waktuKembali,
    kondisiKembali,
    status,
    material,
    user,
  ];
}
