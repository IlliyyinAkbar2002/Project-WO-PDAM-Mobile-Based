import 'dart:convert';
import '../../domain/entities/location_type_entity.dart';

class LocationTypeModel extends LocationTypeEntity {
  const LocationTypeModel({super.id, required super.locationType});

  factory LocationTypeModel.fromJson(String source) =>
      LocationTypeModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory LocationTypeModel.fromMap(Map<String, dynamic> map) {
    print("📢 parsing jenis lokasi: $map");
    return LocationTypeModel(id: map['id'], locationType: map['nama']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': locationType};
  }

  LocationTypeEntity toEntity() {
    return LocationTypeEntity(id: id, locationType: locationType);
  }

  factory LocationTypeModel.fromEntity(LocationTypeEntity entity) {
    return LocationTypeModel(id: entity.id, locationType: entity.locationType);
  }
}
