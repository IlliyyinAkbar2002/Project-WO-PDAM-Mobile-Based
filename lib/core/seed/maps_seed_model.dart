import 'package:project_mobile_pdam/feature/work_order/data/models/master_location_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';

class MapsSeedModel {
  const MapsSeedModel._();

  static const int defaultRadiusMeter = 3000;

  static const List<MasterLocationModel> masterLocations = [
    MasterLocationModel(
      id: 1,
      nama: 'Jl. Raya Darmo No. 88, Wonokromo, Surabaya',
      latitude: -7.2865975,
      longitude: 112.7394111,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 2,
      nama: 'Jl. Manyar Kertoarjo No. 12, Gubeng, Surabaya',
      latitude: -7.2798543,
      longitude: 112.7631856,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 3,
      nama: 'Jl. HR Muhammad No. 45, Sukomanunggal, Surabaya',
      latitude: -7.2844709,
      longitude: 112.6937142,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 4,
      nama: 'Jl. Ahmad Yani No. 120, Wonocolo, Surabaya',
      latitude: -7.3258005,
      longitude: 112.7302923,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 5,
      nama: 'Jl. Tunjungan No. 10, Genteng, Surabaya',
      latitude: -7.2567402,
      longitude: 112.7372218,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 6,
      nama: 'Jl. Dharmahusada Indah Timur No. 17, Mulyorejo, Surabaya',
      latitude: -7.2839926,
      longitude: 112.7809551,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 7,
      nama: 'Jl. Ketintang Baru Selatan No. 22, Gayungan, Surabaya',
      latitude: -7.3247895,
      longitude: 112.7258568,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 8,
      nama: 'Jl. Kapas Krampung No. 50, Tambaksari, Surabaya',
      latitude: -7.2488449,
      longitude: 112.7576475,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 9,
      nama: 'Jl. Rungkut Madya No. 30, Rungkut, Surabaya',
      latitude: -7.3322081,
      longitude: 112.7258568,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 10,
      nama: 'Jl. Dukuh Kupang Barat No. 19, Dukuh Pakis, Surabaya',
      latitude: -7.2851102,
      longitude: 112.7088043,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 11,
      nama: 'Kecipik, Boteng, Menganti, Gresik Regency',
      latitude: -7.270509,
      longitude: 112.567216,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 12,
      nama: 'Jl. Joyoboyo, Sawunggaling, Kec. Wonokromo, Surabaya',
      latitude: -7.29816,
      longitude: 112.73704,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 13,
      nama: 'Telkom University Surabaya, Jl. Ketintang No. 156, Surabaya',
      latitude: -7.29816,
      longitude: 112.73704,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 14,
      nama: 'PDAM Surya Sembada Kota Surabaya, Jl. Prof. Dr. Moestopo No. 2, Surabaya',
      latitude: -7.29816,
      longitude: 112.73704,
      radiusMeter: defaultRadiusMeter,
    ),
  ];

  static List<MasterLocationEntity> get entities {
    return masterLocations.map((location) => location.toEntity()).toList();
  }

  static List<Map<String, dynamic>> get maps {
    return masterLocations.map((location) => location.toMap()).toList();
  }

  static List<MasterLocationEntity> search(String query) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return entities;
    }

    final queryTokens = normalizedQuery.split(' ');

    return entities.where((location) {
      final searchableText = _searchableText(location);
      return searchableText.contains(normalizedQuery) ||
          queryTokens.every(searchableText.contains);
    }).toList();
  }

  static String _searchableText(MasterLocationEntity location) {
    return _normalize(location.nama);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\bjalan\b'), 'jl')
        .replaceAll(RegExp(r'\bnomor\b'), 'no')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
