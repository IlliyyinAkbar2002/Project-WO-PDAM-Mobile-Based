import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceException implements Exception {
  final String message;
  const GeofenceException(this.message);

  @override
  String toString() => 'GeofenceException: $message';
}

/// - [inside]           : jarak ≤ radius (pasti di dalam).
/// - [withinTolerance]  : jarak > radius, tetapi masih mungkin di dalam bila
/// - [outside]          : di luar radius bahkan setelah memperhitungkan akurasi.
/// - [precisionReduced] : izin lokasi hanya "Perkiraan" sehingga posisi yang

enum GeofenceStatus { inside, withinTolerance, outside, precisionReduced }

/// - [precise] : app punya `ACCESS_FINE_LOCATION` (Android) / full accuracy (iOS).
/// - [reduced] : app hanya dapat lokasi "Perkiraan". OS membulatkan posisi ke

enum LocationPrecision { precise, reduced }

/// Keputusan geofence murni (tanpa I/O) — mudah diuji.
class GeofenceDecision {
  final bool withinRadius;
  final bool allowed;
  final bool accuracyPoor;
  final GeofenceStatus status;
  const GeofenceDecision({
    required this.withinRadius,
    required this.allowed,
    required this.accuracyPoor,
    required this.status,
  });
}

class GeofenceCheck {
  final Position position;
  final double distanceMeters;
  final double radiusMeter;
  final GeofenceDecision decision;
  final LocationPrecision precision;

  const GeofenceCheck({
    required this.position,
    required this.distanceMeters,
    required this.radiusMeter,
    required this.decision,
    required this.precision,
  });

  bool get withinRadius => decision.withinRadius;
  bool get allowed => decision.allowed;
  bool get accuracyPoor => decision.accuracyPoor;
  GeofenceStatus get status => decision.status;
}

class GeofenceService {
  static const bool enforceGeofence = true;
  static const Duration _maxCacheAge = Duration(seconds: 30);
  static const double _maxCacheAccuracyMeters = 100;
  static const Duration _freshFixBudget = Duration(seconds: 6);
  static const double _defaultDesiredAccuracyMeters = 50;
  static const double fallbackRadiusMeter = 100;
  Future<LocationPrecision> checkPrecision() async {
    try {
      final status = await Geolocator.getLocationAccuracy();
      return status == LocationAccuracyStatus.reduced
          ? LocationPrecision.reduced
          : LocationPrecision.precise;
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] cek presisi gagal: $e');
      return LocationPrecision.precise;
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<Position> getCurrentPosition({
    bool preferFresh = false,
    double desiredAccuracyMeters = _defaultDesiredAccuracyMeters,
    LocationPrecision? precision,
  }) async {
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

    if (!preferFresh) {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <= _maxCacheAge &&
          last.accuracy > 0 &&
          last.accuracy <= _maxCacheAccuracyMeters) {
        return last;
      }
    }

    final LocationPrecision effectivePrecision =
        precision ?? await checkPrecision();
    if (effectivePrecision == LocationPrecision.reduced) {
      if (kDebugMode) {
        debugPrint(
          '[Geofence] izin lokasi "Perkiraan" — lewati budget GPS presisi',
        );
      }
    } else {
      final Position? fresh = await _acquireFreshFix(desiredAccuracyMeters);
      if (fresh != null) return fresh;

      if (kDebugMode) {
        debugPrint('[Geofence] stream GPS tak memberi fix, fallback ke medium');
      }
    }
    final Position? medium = await _tryFix(
      LocationAccuracy.medium,
      const Duration(seconds: 5),
    );
    if (medium != null) return medium;

    final Position? last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      if (kDebugMode) {
        debugPrint('[Geofence] semua fix gagal, pakai last-known');
      }
      return last;
    }

    throw const GeofenceException(
      'Gagal mendapatkan lokasi GPS. Pastikan berada di area terbuka lalu '
      'coba lagi.',
    );
  }

  Future<Position?> _acquireFreshFix(double desiredAccuracyMeters) async {
    Position? best;
    final completer = Completer<Position>();
    StreamSubscription<Position>? sub;

    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (pos) {
        if (best == null || pos.accuracy < best!.accuracy) best = pos;
        if (pos.accuracy > 0 &&
            pos.accuracy <= desiredAccuracyMeters &&
            !completer.isCompleted) {
          completer.complete(pos);
        }
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('[Geofence] stream lokasi error: $e');
        if (!completer.isCompleted) completer.completeError(e);
      },
      cancelOnError: false,
    );

    try {
      return await completer.future.timeout(_freshFixBudget);
    } on TimeoutException {
      // Budget habis: pakai fix terbaik yang sempat datang (mungkin belum ideal,
      // tapi decide() akan memperhitungkan akurasinya).
      if (kDebugMode) {
        debugPrint(
          '[Geofence] budget GPS habis, best accuracy='
          '${best?.accuracy.toStringAsFixed(0) ?? "-"}m',
        );
      }
      return best;
    } catch (_) {
      return best;
    } finally {
      await sub.cancel();
    }
  }
  Future<Position?> _tryFix(
    LocationAccuracy accuracy,
    Duration timeLimit,
  ) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    } on TimeoutException {
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Geofence] getCurrentPosition gagal: $e');
      return null;
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

  static GeofenceDecision decide({
    required double distanceMeters,
    required double accuracyMeters,
    required double radiusMeter,
    bool precisionReduced = false,
  }) {
    final double accuracy = accuracyMeters.isFinite && accuracyMeters > 0
        ? accuracyMeters
        : 0;
    final bool withinRadius = distanceMeters <= radiusMeter;
    final double effective = (distanceMeters - accuracy).clamp(
      0,
      double.infinity,
    );
    final bool accuracyPoor = accuracy > radiusMeter;
    final bool allowed = !precisionReduced && effective <= radiusMeter;
    final GeofenceStatus status;
    if (precisionReduced) {
      status = GeofenceStatus.precisionReduced;
    } else if (withinRadius) {
      status = GeofenceStatus.inside;
    } else {
      status = allowed ? GeofenceStatus.withinTolerance : GeofenceStatus.outside;
    }

    return GeofenceDecision(
      withinRadius: withinRadius,
      allowed: allowed,
      accuracyPoor: accuracyPoor,
      status: status,
    );
  }

  Future<GeofenceCheck> check({
    required double targetLat,
    required double targetLng,
    required double radiusMeter,
    bool preferFresh = false,
  }) async {
    final double desiredAccuracy = (radiusMeter * 0.5).clamp(30.0, 100.0);
    final LocationPrecision precision = await checkPrecision();
    final Position position = await getCurrentPosition(
      preferFresh: preferFresh,
      desiredAccuracyMeters: desiredAccuracy,
      precision: precision,
    );
    final double distance = distanceTo(position, targetLat, targetLng);
    final GeofenceDecision decision = decide(
      distanceMeters: distance,
      accuracyMeters: position.accuracy,
      radiusMeter: radiusMeter,
      precisionReduced: precision == LocationPrecision.reduced,
    );

    if (kDebugMode) {
      debugPrint(
        '[Geofence] target=($targetLat,$targetLng) '
        'device=(${position.latitude},${position.longitude}) '
        'accuracy=±${position.accuracy.toStringAsFixed(0)}m '
        'distance=${distance.toStringAsFixed(0)}m radius=${radiusMeter.toStringAsFixed(0)}m '
        'precision=${precision.name} '
        'status=${decision.status.name} allowed=${decision.allowed}',
      );
    }

    return GeofenceCheck(
      position: position,
      distanceMeters: distance,
      radiusMeter: radiusMeter,
      decision: decision,
      precision: precision,
    );
  }
}
