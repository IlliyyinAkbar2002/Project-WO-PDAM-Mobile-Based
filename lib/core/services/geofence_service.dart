import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Exception dengan pesan siap-tampil (Bahasa Indonesia) untuk masalah lokasi:
/// GPS mati, izin ditolak, atau izin ditolak permanen.
class GeofenceException implements Exception {
  final String message;
  const GeofenceException(this.message);

  @override
  String toString() => 'GeofenceException: $message';
}

/// Status posisi perangkat terhadap radius WO.
///
/// - [inside]          : jarak ≤ radius (pasti di dalam).
/// - [withinTolerance] : jarak > radius, tetapi masih mungkin di dalam bila
///   ketidakpastian GPS (accuracy) diperhitungkan → submit tetap diizinkan.
/// - [outside]         : di luar radius bahkan setelah memperhitungkan akurasi.
enum GeofenceStatus { inside, withinTolerance, outside }

/// Keputusan geofence murni (tanpa I/O) — mudah diuji.
class GeofenceDecision {
  /// `true` bila jarak mentah ≤ radius (di dalam secara ketat).
  final bool withinRadius;

  /// `true` bila submit boleh dilanjutkan: jarak dikurangi ketidakpastian GPS
  /// masih ≤ radius. Ini adalah gate otoritatif untuk submit.
  final bool allowed;

  /// `true` bila ketidakpastian GPS (accuracy) lebih besar dari radius WO,
  /// sehingga "di dalam/di luar" kurang bisa dipercaya. Bersifat PERINGATAN
  /// saja — tidak pernah memblokir submit.
  final bool accuracyPoor;

  final GeofenceStatus status;

  const GeofenceDecision({
    required this.withinRadius,
    required this.allowed,
    required this.accuracyPoor,
    required this.status,
  });
}

/// Hasil pengecekan geofence: posisi saat ini + jarak ke titik WO + keputusan.
class GeofenceCheck {
  final Position position;
  final double distanceMeters;
  final double radiusMeter;
  final GeofenceDecision decision;

  const GeofenceCheck({
    required this.position,
    required this.distanceMeters,
    required this.radiusMeter,
    required this.decision,
  });

  bool get withinRadius => decision.withinRadius;
  bool get allowed => decision.allowed;
  bool get accuracyPoor => decision.accuracyPoor;
  GeofenceStatus get status => decision.status;
}

class GeofenceService {
  static const bool enforceGeofence = true;

  /// Umur maksimum fix cache (last-known) yang masih dianggap relevan.
  static const Duration _maxCacheAge = Duration(seconds: 30);

  /// Akurasi maksimum agar fix cache boleh dipakai. Fix jaringan yang kasar
  /// (mis. >100 m) ditolak supaya banner awal tidak memakai posisi meleset.
  static const double _maxCacheAccuracyMeters = 100;

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

    // Akurasi tinggi (GPS/fine-location) agar jarak ke titik WO presisi.
    // Akurasi `medium` (berbasis wifi/sel) bisa meleset ratusan meter–>1 km
    // dan membuat submit ditolak keliru meski pengguna berada di lokasi.
    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );

    if (!preferFresh) {
      // Lokasi terakhir yang diketahui (sangat cepat) bila tersedia, cukup baru,
      // dan cukup akurat — fix basi atau kasar bisa membuat jarak tampak jauh
      // meski pengguna sudah berada di lokasi yang benar.
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <= _maxCacheAge &&
          last.accuracy > 0 &&
          last.accuracy <= _maxCacheAccuracyMeters) {
        return last;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } on TimeoutException {
      // Cold-start GPS bisa melewati timeLimit. Fallback ke last-known yang
      // masih relevan bila ada, agar pengguna tidak buntu; jika tidak ada,
      // laporkan sebagai kegagalan lokasi biasa.
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <= _maxCacheAge) {
        return last;
      }
      throw const GeofenceException(
        'Gagal mendapatkan lokasi GPS. Pastikan berada di area terbuka lalu '
        'coba lagi.',
      );
    }
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

  /// Keputusan geofence murni — memperhitungkan ketidakpastian GPS ([accuracyMeters]).
  ///
  /// Perangkat dianggap boleh submit ([GeofenceDecision.allowed]) bila lingkaran
  /// ketidakpastian GPS-nya menyentuh radius WO: `jarak - akurasi ≤ radius`.
  /// Ini mencegah penolakan keliru saat berada di dalam/di dekat batas dengan
  /// akurasi yang tidak sempurna.
  static GeofenceDecision decide({
    required double distanceMeters,
    required double accuracyMeters,
    required double radiusMeter,
  }) {
    final double accuracy = accuracyMeters.isFinite && accuracyMeters > 0
        ? accuracyMeters
        : 0;
    final bool withinRadius = distanceMeters <= radiusMeter;
    final double effective = (distanceMeters - accuracy).clamp(
      0,
      double.infinity,
    );
    final bool allowed = effective <= radiusMeter;
    final bool accuracyPoor = accuracy > radiusMeter;
    final GeofenceStatus status = withinRadius
        ? GeofenceStatus.inside
        : (allowed ? GeofenceStatus.withinTolerance : GeofenceStatus.outside);

    return GeofenceDecision(
      withinRadius: withinRadius,
      allowed: allowed,
      accuracyPoor: accuracyPoor,
      status: status,
    );
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
    final GeofenceDecision decision = decide(
      distanceMeters: distance,
      accuracyMeters: position.accuracy,
      radiusMeter: radiusMeter,
    );

    if (kDebugMode) {
      debugPrint(
        '[Geofence] target=($targetLat,$targetLng) '
        'device=(${position.latitude},${position.longitude}) '
        'accuracy=±${position.accuracy.toStringAsFixed(0)}m '
        'distance=${distance.toStringAsFixed(0)}m radius=${radiusMeter.toStringAsFixed(0)}m '
        'status=${decision.status.name} allowed=${decision.allowed}',
      );
    }

    return GeofenceCheck(
      position: position,
      distanceMeters: distance,
      radiusMeter: radiusMeter,
      decision: decision,
    );
  }
}
