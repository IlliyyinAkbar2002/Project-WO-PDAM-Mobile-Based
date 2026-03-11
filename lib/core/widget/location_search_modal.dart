import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/master_location_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_event.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/work_order_state.dart';

class LocationSearchModal extends StatefulWidget {
  final Function(MasterLocationEntity) onLocationSelected;

  const LocationSearchModal({super.key, required this.onLocationSelected});

  @override
  State<LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<LocationSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<MasterLocationEntity> _filteredLocations = [];
  List<MasterLocationEntity> _allLocations = [];

  @override
  void initState() {
    super.initState();
    // Fetch master locations when modal opens
    context.read<WorkOrderBloc>().add(GetMasterLocationsEvent());
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        _filteredLocations = _allLocations
            .where(
              (location) =>
                  location.nama.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                      onChanged: _filterLocations,
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
            child: BlocConsumer<WorkOrderBloc, WorkOrderState>(
              listener: (context, state) {
                if (state is MasterLocationsLoaded) {
                  setState(() {
                    _allLocations = state.masterLocations;
                    _filteredLocations = state.masterLocations;
                  });
                } else if (state is WorkOrderError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is WorkOrderLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (_filteredLocations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No locations found',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = _filteredLocations[index];
                    return InkWell(
                      onTap: () {
                        // Only call the callback, don't pop here
                        // The callback will handle the pop with the data
                        widget.onLocationSelected(location);
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
                                location.nama,
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
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => LocationSearchModal(
        onLocationSelected: (location) {
          Navigator.pop(context, location);
        },
      ),
    ),
  );
}
