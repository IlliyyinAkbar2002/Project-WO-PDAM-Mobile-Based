import 'package:equatable/equatable.dart';

class WorkOrderTypeEntity extends Equatable {
  final int? id;
  final String name;
  final String? kategoriForm;

  const WorkOrderTypeEntity({this.id, required this.name, this.kategoriForm});

  @override
  List<Object?> get props => [id, name, kategoriForm];

  WorkOrderTypeEntity copyWith({int? id, String? name, String? kategoriForm}) {
    return WorkOrderTypeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      kategoriForm: kategoriForm ?? this.kategoriForm,
    );
  }
}
