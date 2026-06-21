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

/// Akses GPS terpusat untuk fitur geofencing work order.
///
/// Satu-satunya tempat aplikasi meminta izin & membaca posisi perangkat, agar
/// logika tidak terduplikasi di widget. TIDAK menolak posisi hasil mock GPS —
/// mock harus tetap terbaca untuk keperluan demo (memperagakan kondisi di
/// dalam vs di luar radius tanpa pergi ke lokasi fisik).
class GeofenceService {
  /// Master switch enforcement geofence. Default AKTIF.
  ///
  /// Set `false` untuk mematikan penolakan submit dengan cepat saat darurat
  /// (mis. hari demo). Posisi tetap diambil & dikirim ke backend; hanya gate
  /// "di luar radius → tolak" yang dilewati.
  static const bool enforceGeofence = true;

  /// Ambil posisi GPS sekarang.
  ///
  /// Melempar [GeofenceException] bila layanan lokasi mati atau izin ditolak.
  ///
  /// - [preferFresh] `false` (default): coba `getLastKnownPosition()` dulu agar
  ///   cepat (untuk indikator status saat halaman dibuka), fallback ke posisi
  ///   baru bila tidak ada.
  /// - [preferFresh] `true`: selalu ambil posisi baru (untuk gate submit, agar
  ///   perubahan mock GPS langsung terbaca dan tidak memakai cache basi).
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
      // Lokasi terakhir yang diketahui (sangat cepat) bila tersedia.
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
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
