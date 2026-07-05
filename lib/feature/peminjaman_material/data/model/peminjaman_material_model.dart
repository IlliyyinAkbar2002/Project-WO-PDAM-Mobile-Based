import 'dart:convert';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/data/model/material_model.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/user_model.dart';

class PeminjamanMaterialModel extends PeminjamanMaterialEntity {
  const PeminjamanMaterialModel({
    super.id,
    super.workorderId,
    super.materialKode,
    super.userId,
    super.jumlahPinjam,
    super.waktuPinjam,
    super.jumlahKembali,
    super.jumlahRusak,
    super.jumlahTerpasang,
    super.waktuKembali,
    super.kondisiKembali,
    super.status,
    super.material,
    super.user,
  });

  factory PeminjamanMaterialModel.fromMap(Map<String, dynamic> map) {
    return PeminjamanMaterialModel(
      id: map['id'],
      workorderId: map['workorder_id'],
      materialKode: map['material_kode']?.toString(),
      userId: map['user_id'] ?? map['diajukan_oleh'],
      jumlahPinjam: map['jumlah_pinjam'] != null
          ? int.tryParse(map['jumlah_pinjam'].toString())
          : null,
      waktuPinjam: map['waktu_pinjam'] != null
          ? DateTime.tryParse(map['waktu_pinjam'].toString())?.toLocal()
          : (map['diajukan_at'] != null ? DateTime.tryParse(map['diajukan_at'].toString())?.toLocal() : null),
      jumlahKembali: map['jumlah_kembali'] != null
          ? int.tryParse(map['jumlah_kembali'].toString())
          : null,
      jumlahRusak: map['jumlah_rusak'] != null
          ? int.tryParse(map['jumlah_rusak'].toString())
          : null,
      jumlahTerpasang: map['jumlah_terpasang'] != null
          ? int.tryParse(map['jumlah_terpasang'].toString())
          : null,
      waktuKembali: map['waktu_kembali'] != null
          ? DateTime.tryParse(map['waktu_kembali'].toString())?.toLocal()
          : (map['dikembalikan_at'] != null ? DateTime.tryParse(map['dikembalikan_at'].toString())?.toLocal() : null),
      kondisiKembali: map['kondisi_kembali'],
      status: map['status'],
      material: map['material'] != null
          ? MaterialModel.fromMap(Map<String, dynamic>.from(map['material']))
          : null,
      user: map['user'] != null
          ? UserModel.fromMap(Map<String, dynamic>.from(map['user']))
          : (map['pengaju'] != null ? UserModel.fromMap(Map<String, dynamic>.from(map['pengaju'])) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workorder_id': workorderId,
      'material_kode': materialKode,
      'user_id': userId,
      'jumlah_pinjam': jumlahPinjam,
      'waktu_pinjam': waktuPinjam?.toIso8601String(),
      'jumlah_kembali': jumlahKembali,
      'jumlah_rusak': jumlahRusak,
      'jumlah_terpasang': jumlahTerpasang,
      'waktu_kembali': waktuKembali?.toIso8601String(),
      'kondisi_kembali': kondisiKembali,
      'status': status,
    };
  }

  factory PeminjamanMaterialModel.fromJson(String source) =>
      PeminjamanMaterialModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}
