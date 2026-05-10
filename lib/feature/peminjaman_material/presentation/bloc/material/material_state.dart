import 'package:equatable/equatable.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/material_entity.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/domain/entities_material/peminjaman_material_entity.dart';

abstract class MaterialState extends Equatable {
  const MaterialState();

  @override
  List<Object?> get props => [];
}

class MaterialInitial extends MaterialState {}

class MaterialLoading extends MaterialState {}

class MasterMaterialsLoaded extends MaterialState {
  final List<MaterialEntity> materials;

  const MasterMaterialsLoaded(this.materials);

  @override
  List<Object?> get props => [materials];
}

class PeminjamanLoaded extends MaterialState {
  final List<PeminjamanMaterialEntity> peminjamanList;

  const PeminjamanLoaded(this.peminjamanList);

  @override
  List<Object?> get props => [peminjamanList];
}

class MaterialActionSuccess extends MaterialState {
  final String message;
  final PeminjamanMaterialEntity data;

  const MaterialActionSuccess(this.message, this.data);

  @override
  List<Object?> get props => [message, data];
}

class MaterialError extends MaterialState {
  final String message;

  const MaterialError(this.message);

  @override
  List<Object?> get props => [message];
}
