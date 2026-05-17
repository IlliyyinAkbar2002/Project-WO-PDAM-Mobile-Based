import 'package:project_mobile_pdam/feature/work_order/data/models/master_location_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';

class MapsSeedModel {
  const MapsSeedModel._();

  static const int defaultRadiusMeter = 1000;

  static const List<MasterLocationModel> masterLocations = [
    MasterLocationModel(
      id: 1,
      nama: 'Universitas Ciputra Surabaya',
      latitude: -7.2855908,
      longitude: 112.631599,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 2,
      nama: 'Sepuluh Nopember Institute of Technology',
      latitude: -7.282356,
      longitude: 112.7949253,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 3,
      nama: 'Universitas Telkom Surabaya',
      latitude: -7.3111665,
      longitude: 112.728915,
      radiusMeter: defaultRadiusMeter,
    ),
    MasterLocationModel(
      id: 4,
      nama: 'State University of Surabaya - Campus 1',
      latitude: -7.3152027,
      longitude: 112.7268517,
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
    final aliases = switch (location.id) {
      1 => 'uc uc surabaya ciputra university',
      2 => 'its institut teknologi sepuluh nopember',
      3 => 'telkom university tel-u telkom surabaya',
      4 => 'unesa universitas negeri surabaya state university',
      _ => '',
    };

    return _normalize('${location.nama} $aliases');
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\buniversitas\b|\buniversity\b'), 'univ')
        .replaceAll(RegExp(r'\binstitut\b|\binstitute\b'), 'inst')
        .replaceAll(RegExp(r'\bnegeri\b|\bstate\b'), 'state')
        .replaceAll(RegExp(r'\bkampus\b|\bcampus\b'), 'campus')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
