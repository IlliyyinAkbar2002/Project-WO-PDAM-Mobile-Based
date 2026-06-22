import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/seed/maps_seed_model.dart';
import 'package:project_mobile_pdam/core/utils/debug_log.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';

class LocationSearchModal extends StatefulWidget {
  final Function(MasterLocationEntity) onLocationSelected;

  const LocationSearchModal({super.key, required this.onLocationSelected});

  @override
  State<LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<LocationSearchModal> {
  final TextEditingController _searchController = TextEditingController();

  List<MasterLocationEntity> _results = <MasterLocationEntity>[];
  bool _isLoading = false;
  Timer? _debounce;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _results = <MasterLocationEntity>[];
        _errorMsg = '';
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchSeedLocations(query);
    });
  }

  /// Mencari lokasi dari seed lokal karena demo key Google tidak mendukung
  /// Places Autocomplete API untuk mobile REST calls.
  void _searchSeedLocations(String query) {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      DebugLog.info(
        message: '[LocationSearch] Searching local seed for: "$query"',
      );

      final results = MapsSeedModel.search(query);

      DebugLog.info(
        message: '[LocationSearch] Found ${results.length} seeded results',
      );

      setState(() {
        _results = results;
      });
    } catch (e, stackTrace) {
      DebugLog.error(
        message: '[LocationSearch] Unexpected error: $e\n$stackTrace',
      );
      setState(() {
        _errorMsg = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectLocation(MasterLocationEntity location) {
    DebugLog.info(
      message:
          '[LocationSearch] Selected seeded location: ${location.nama} '
          '(${location.latitude}, ${location.longitude})',
    );
    widget.onLocationSelected(location);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Cancel and Search buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 16,
                      color: Color(0xFF2B7FFF),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Optional: implement search action
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 16,
                      color: Color(0xFF2B7FFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.18),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search location',
                        hintStyle: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Location list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMsg.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _errorMsg,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _searchController.text.trim().isEmpty
                            ? 'Ketik atau tempel nama lokasi untuk mencari.'
                            : 'No locations found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];

                      return InkWell(
                        onTap: () {
                          _selectLocation(result);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFF3F4F6),
                                width: 1.18,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result.nama,
                                  style: const TextStyle(
                                    fontFamily: 'Arial',
                                    fontSize: 16,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the location search modal with slide animation
Future<MasterLocationEntity?> showLocationSearchModal(
  BuildContext context,
) async {
  return await showModalBottomSheet<MasterLocationEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      // Build LocationSearchModal once, outside DraggableScrollableSheet.builder
      // to prevent re-creation (and duplicate API calls) on every sheet resize.
      final modal = LocationSearchModal(
        onLocationSelected: (location) {
          Navigator.pop(modalContext, location);
        },
      );
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => modal,
      );
    },
  );
}
