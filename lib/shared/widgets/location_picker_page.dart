import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../models/address.dart';
import 'primary_button.dart';

/// Full-screen map picker. The user pans the map to move a fixed center pin,
/// or uses their current location, then confirms to return an [Address]
/// carrying the picked latitude/longitude and a best-effort text label.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.title = 'เลือกตำแหน่งบนแผนที่',
    this.initialAddress,
  });

  final String title;
  final Address? initialAddress;

  final LatLng defaultCenter = const LatLng(13.7563, 100.5018); // Bangkok

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late LatLng _center;

  String? _addressLabel;
  bool _isResolvingAddress = false;
  bool _isLocating = false;
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    final initialAddress = widget.initialAddress;
    _center = initialAddress?.hasCoordinates == true
        ? LatLng(initialAddress!.latitude!, initialAddress.longitude!)
        : widget.defaultCenter;
    _addressLabel = initialAddress?.addressLine;

    if (_addressLabel == null || _addressLabel!.isEmpty) {
      _resolveAddress(_center);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Forward geocoding (place name/address -> coordinates) via the
  /// `geocoding` package, which resolves through the device's native
  /// geocoder (Android `Geocoder` / iOS `CLGeocoder`) — free, no API key or
  /// billing, same as the reverse-geocoding already used in
  /// [_resolveAddress]. Unlike Google Places Autocomplete this has no
  /// autocomplete-as-you-type suggestions, just a submit-and-resolve search.
  Future<void> _searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await locationFromAddress(trimmed);
      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchError = 'ไม่พบสถานที่ที่ค้นหา ลองระบุที่อยู่ให้ละเอียดขึ้น';
        });
        return;
      }

      final point = LatLng(results.first.latitude, results.first.longitude);
      setState(() {
        _center = point;
        _isSearching = false;
      });
      _mapController.move(point, 16);
      await _resolveAddress(point);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _resolveAddress(LatLng point) async {
    setState(() => _isResolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (!mounted) return;
      final label = placemarks.isEmpty ? null : _formatPlacemark(placemarks.first);
      setState(() {
        _addressLabel = label ?? _formatLatLng(point);
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressLabel = _formatLatLng(point);
        _isResolvingAddress = false;
      });
    }
  }

  String _formatPlacemark(Placemark p) {
    final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
        .where((part) => part != null && part.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? _formatLatLng(_center) : parts.join(', ');
  }

  String _formatLatLng(LatLng point) =>
      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตการเข้าถึงตำแหน่งเพื่อใช้งานฟีเจอร์นี้')),
        );
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิดบริการตำแหน่ง (GPS) ของอุปกรณ์')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _center = point;
        _isLocating = false;
      });
      _mapController.move(point, 16);
      await _resolveAddress(point);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถระบุตำแหน่งปัจจุบันได้')),
      );
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      Address(
        addressLine: _addressLabel ?? _formatLatLng(_center),
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (!hasGesture) return;
                _center = position.center;
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd && event.source != MapEventSource.mapController) {
                  _resolveAddress(_center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.caremate.client_app',
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, size: 44, color: AppColors.primary),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'ค้นหาสถานที่ เช่น ชื่อสถานที่หรือที่อยู่',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            ),
                            onSubmitted: _searchLocation,
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchError = null;
                            }),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                            onPressed: () => _searchLocation(_searchController.text),
                          ),
                      ],
                    ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                        child: Text(
                          _searchError!,
                          style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 210,
            child: FloatingActionButton(
              heroTag: 'location-picker-my-location',
              onPressed: _isLocating ? null : _useCurrentLocation,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isResolvingAddress
                              ? Text('กำลังค้นหาที่อยู่...', style: textTheme.bodyMedium)
                              : Text(
                                  _addressLabel ?? _formatLatLng(_center),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'ยืนยันตำแหน่งนี้',
                      icon: Icons.check_circle_rounded,
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
