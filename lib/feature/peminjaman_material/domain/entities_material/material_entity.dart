import 'package:equatable/equatable.dart';

class MaterialEntity extends Equatable {
  final int? id;
  final String? kodeMaterial;
  final String? namaMaterial;
  final String? kategori;
  final String? satuan;
  final int? jumlahStok;
  final int? terpakai;
  final int? rusak;

  const MaterialEntity({
    this.id,
    this.kodeMaterial,
    this.namaMaterial,
    this.kategori,
    this.satuan,
    this.jumlahStok,
    this.terpakai,
    this.rusak,
  });

  /// Stok yang bisa dipinjam. Identik dengan `tersedia` dari BE.
  ///
  /// PENTING (jangan double-count): `terpakai` dari BE SUDAH termasuk
  /// `jumlah_terpasang` (material yang dikonsumsi/tidak dikembalikan) selain
  /// pinjaman aktif. Jadi formula ini sudah benar apa adanya — JANGAN kurangi
  /// `terpasang` lagi di sini.
  int get stokTersedia => (jumlahStok ?? 0) - (terpakai ?? 0) - (rusak ?? 0);

  @override
  List<Object?> get props => [
        id,
        kodeMaterial,
        namaMaterial,
        kategori,
        satuan,
        jumlahStok,
        terpakai,
        rusak,
      ];
}
