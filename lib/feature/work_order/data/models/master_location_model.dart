import 'dart:convert';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';

class MasterLocationModel extends MasterLocationEntity {
  const MasterLocationModel({
    super.id,
    required super.nama,
    required super.latitude,
    required super.longitude,
    required super.radiusMeter,
  });

  factory MasterLocationModel.fromJson(String source) =>
      MasterLocationModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory MasterLocationModel.fromMap(Map<String, dynamic> map) {
    return MasterLocationModel(
      id: map['id'],
      nama: map['nama'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      radiusMeter: map['radius_meter'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radiusMeter,
    };
  }

  MasterLocationEntity toEntity() {
    return MasterLocationEntity(
      id: id,
      nama: nama,
      latitude: latitude,
      longitude: longitude,
      radiusMeter: radiusMeter,
    );
  }

  factory MasterLocationModel.fromEntity(MasterLocationEntity entity) {
    return MasterLocationModel(
      id: entity.id,
      nama: entity.nama,
      latitude: entity.latitude,
      longitude: entity.longitude,
      radiusMeter: entity.radiusMeter,
    );
  }
}
