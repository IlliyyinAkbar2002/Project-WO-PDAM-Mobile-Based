import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/core/widget/location_search_modal.dart';

class LocationPicker extends StatefulWidget {
  final int? workOrderId;
  final Function(double lat, double lng, {int? locationId, int? radiusMeter})
  onLocationSelected;
  final bool isStatic;
  final bool isReadOnly;
  final double? longitude;
  final double? latitude;
  final int? locationId;

  const LocationPicker({
    super.key,
    this.workOrderId,
    required this.onLocationSelected,
    required this.isStatic,
    this.isReadOnly = false,
    this.longitude,
    this.latitude,
    this.locationId,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends AppStatePage<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(-7.250445, 112.768845);
  String locationInfo = "";
  String selectedLocationName = "";

  @override
  void initState() {
    super.initState();
    _selectedLocation = (widget.latitude != null && widget.longitude != null)
        ? LatLng(widget.latitude!, widget.longitude!)
        : const LatLng(-7.250445, 112.768845);

    if (widget.latitude != null && widget.longitude != null) {
      locationInfo = "Lokasi dipilih";
    }
  }

  void _moveCamera(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14.0),
      ),
    );
  }

  /// Saat pengguna mengetuk peta.
  void _onTapped(LatLng position) {
    if (!widget.isStatic || widget.isReadOnly) {
      return; // Jika dinamis, tidak perlu memilih lokasi
    }
    setState(() {
      locationInfo = "Lokasi dipilih";
      _selectedLocation = position;
      _moveCamera(position);
    });
    // Tap di peta = lokasi kustom tanpa locationId
    widget.onLocationSelected(position.latitude, position.longitude);
  }

  /// Open location search modal
  Future<void> _openLocationSearchModal() async {
    final selectedLocation = await showLocationSearchModal(context);
    if (selectedLocation != null) {
      final newPosition = LatLng(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );
      setState(() {
        locationInfo = selectedLocation.nama;
        selectedLocationName = selectedLocation.nama;
        _selectedLocation = newPosition;
        _moveCamera(newPosition);
      });
      // Pilih dari MasterLocation = ada locationId dan radiusMeter
      widget.onLocationSelected(
        selectedLocation.latitude,
        selectedLocation.longitude,
        locationId: selectedLocation.id,
        radiusMeter: selectedLocation.radiusMeter,
      );
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    // Jika locationTypeId adalah "dinamis", maka tidak perlu memilih lokasi
    if (!widget.isStatic) {
      // Misalkan ID 2 untuk Dinamis
      return const SizedBox();
    }
    return Column(
      children: [
        // Peta untuk memilih lokasi.
        SizedBox(
          height: 165,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation, // Default ke Surabaya
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCamera(_selectedLocation);
            },
            onTap: widget.isReadOnly ? null : _onTapped,
            markers: {
              Marker(
                markerId: const MarkerId("selected"),
                position: _selectedLocation,
              ),
            },
          ),
        ),
        // Informasi lokasi dan pencarian.
        Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tampilan informasi lokasi.
              // Text(
              //   locationInfo,
              //   style: const TextStyle(
              //     fontFamily: 'Roboto',
              //     fontSize: 14,
              //     fontWeight: FontWeight.w500,
              //     color: Color(0xFF2A83C6),
              //     letterSpacing: -0.2,
              //   ),
              // ),
              const SizedBox(height: 8),
              // Field pencarian lokasi - tap to open modal
              (widget.isReadOnly)
                  ? const SizedBox()
                  : GestureDetector(
                      onTap: _openLocationSearchModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFAFBACA)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedLocationName.isEmpty
                                    ? "Cari lokasi..."
                                    : selectedLocationName,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: selectedLocationName.isEmpty
                                      ? const Color(0xFF8797AE)
                                      : const Color(0xFF2D3643),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.search,
                              color: Color(0xFF8797AE),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
