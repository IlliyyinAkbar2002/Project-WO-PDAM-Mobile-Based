import 'package:equatable/equatable.dart';

class MasterLocationEntity extends Equatable {
  final int? id;
  final String nama;
  final double latitude;
  final double longitude;

  /// Radius geofence dari BE. `null` = BE tidak mengirimkannya (mis. relasi
  /// `location` tidak ter-eager-load) — kondisi ini sengaja dibiarkan eksplisit
  /// agar pemakainya memutuskan sendiri, bukan ditambal diam-diam dengan nilai
  /// longgar. Pemakai geofence memakai `GeofenceService.fallbackRadiusMeter`.
  final int? radiusMeter;

  const MasterLocationEntity({
    this.id,
    required this.nama,
    required this.latitude,
    required this.longitude,
    this.radiusMeter,
  });

  @override
  List<Object?> get props => [id, nama, latitude, longitude, radiusMeter];

  MasterLocationEntity copyWith({
    int? id,
    String? nama,
    double? latitude,
    double? longitude,
    int? radiusMeter,
  }) {
    return MasterLocationEntity(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeter: radiusMeter ?? this.radiusMeter,
    );
  }
}

