import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  final int? id;
  final String? name;
  final String? nip;
  final int? jabatanId;
  final String? jabatan;
  final int? departemenId;
  final String? departemen;

  const EmployeeEntity({
    this.id,
    this.name,
    this.nip,
    this.jabatanId,
    this.jabatan,
    this.departemenId,
    this.departemen,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        nip,
        jabatanId,
        jabatan,
        departemenId,
        departemen,
      ];

  EmployeeEntity copyWith({
    int? id,
    String? name,
    String? nip,
    int? jabatanId,
    String? jabatan,
    int? departemenId,
    String? departemen,
  }) {
    return EmployeeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nip: nip ?? this.nip,
      jabatanId: jabatanId ?? this.jabatanId,
      jabatan: jabatan ?? this.jabatan,
      departemenId: departemenId ?? this.departemenId,
      departemen: departemen ?? this.departemen,
    );
  }
}
