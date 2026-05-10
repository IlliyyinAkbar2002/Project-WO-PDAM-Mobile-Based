import 'dart:convert';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';

class MaterialModel extends MaterialEntity {
  const MaterialModel({
    super.id,
    super.kodeMaterial,
    super.namaMaterial,
    super.kategori,
    super.satuan,
    super.jumlahStok,
    super.terpakai,
  });

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'],
      kodeMaterial: map['kode_material'],
      namaMaterial: map['nama_material'],
      kategori: map['kategori'],
      satuan: map['satuan'],
      jumlahStok: map['jumlah_stok'] != null
          ? int.tryParse(map['jumlah_stok'].toString())
          : null,
      terpakai: map['terpakai'] != null
          ? int.tryParse(map['terpakai'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_material': kodeMaterial,
      'nama_material': namaMaterial,
      'kategori': kategori,
      'satuan': satuan,
      'jumlah_stok': jumlahStok,
      'terpakai': terpakai,
    };
  }

  factory MaterialModel.fromJson(String source) =>
      MaterialModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}
