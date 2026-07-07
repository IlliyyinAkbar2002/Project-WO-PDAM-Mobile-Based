import 'package:geolocator/geolocator.dart';

/// Exception dengan pesan siap-tampil (Bahasa Indonesia) untuk masalah lokasi:
/// GPS mati, izin ditolak, atau izin ditolak permanen.
class GeofenceException implements Exception {
  final String message;
  const GeofenceException(this.message);

  @override
  String toString() => 'GeofenceException: $message';
}

/// Hasil pengecekan geofence: posisi saat ini + jarak ke titik WO + status.
class GeofenceCheck {
  final Position position;
  final double distanceMeters;
  final double radiusMeter;
  final bool withinRadius;

  /// `true` bila ketidakpastian GPS (accuracy) lebih besar dari radius WO,
  /// sehingga "di dalam/di luar" tidak bisa dipercaya. Bersifat PERINGATAN
  /// saja — tidak pernah memblokir submit.
  final bool accuracyPoor;

  const GeofenceCheck({
    required this.position,
    required this.distanceMeters,
    required this.radiusMeter,
    required this.withinRadius,
    required this.accuracyPoor,
  });
}

class GeofenceService {
  static const bool enforceGeofence = true;
  Future<Position> getCurrentPosition({bool preferFresh = false}) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Buka pengaturan GPS (lebih reliable daripada location.requestService()).
      await Geolocator.openLocationSettings();
      throw const GeofenceException(
        'GPS harus diaktifkan. Silakan aktifkan dan coba lagi.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const GeofenceException('Akses lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const GeofenceException(
        'Akses lokasi ditolak permanen. Silakan aktifkan di Settings.',
      );
    }

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 10),
    );

    if (!preferFresh) {
      // Lokasi terakhir yang diketahui (sangat cepat) bila tersedia dan cukup
      // baru — fix basi (lama tidak update) bisa membuat jarak tampak jauh
      // meski pengguna sudah berada di lokasi yang benar.
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <=
              const Duration(seconds: 30)) {
        return last;
      }
    }

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  /// Jarak (meter) dari [from] ke titik target.
  double distanceTo(Position from, double targetLat, double targetLng) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      targetLat,
      targetLng,
    );
  }

  /// `true` bila [from] berada dalam [radiusMeter] dari titik target.
  bool isWithinRadius(
    Position from,
    double targetLat,
    double targetLng,
    double radiusMeter,
  ) {
    return distanceTo(from, targetLat, targetLng) <= radiusMeter;
  }

  /// Ambil posisi + hitung jarak ke titik WO sekaligus.
  ///
  /// Melempar [GeofenceException] bila posisi tidak bisa diperoleh.
  Future<GeofenceCheck> check({
    required double targetLat,
    required double targetLng,
    required double radiusMeter,
    bool preferFresh = false,
  }) async {
    final Position position = await getCurrentPosition(preferFresh: preferFresh);
    final double distance = distanceTo(position, targetLat, targetLng);
    return GeofenceCheck(
      position: position,
      distanceMeters: distance,
      radiusMeter: radiusMeter,
      withinRadius: distance <= radiusMeter,
      accuracyPoor: position.accuracy > radiusMeter,
    );
  }
}
