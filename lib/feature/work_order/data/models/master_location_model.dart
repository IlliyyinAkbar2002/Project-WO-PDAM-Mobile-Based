import 'dart:convert';
import 'package:project_mobile_pdam/core/seed/maps_seed_model.dart';
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
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      radiusMeter: _resolveRadius(map['radius_meter']),
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

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Radius dari BE; jatuh ke [MapsSeedModel.defaultRadiusMeter] bila
  /// null/kosong/0 agar geofence tidak menolak submit secara keliru.
  static int _resolveRadius(dynamic value) {
    final parsed = _toInt(value);
    return parsed > 0 ? parsed : MapsSeedModel.defaultRadiusMeter;
  }
}
