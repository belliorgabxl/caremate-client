import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as places;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/app_config.dart';
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
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  late LatLng _center;

  /// Last point [_resolveAddress] ran for. `onCameraIdle` fires for both user
  /// gestures and programmatic `animateCamera` calls (unlike flutter_map's
  /// `MapEventSource`, which could tell them apart), so this is what stops a
  /// search / "my location" move from geocoding the same point twice — and
  /// stops the first idle after load from clobbering a label the caller
  /// already passed in via [LocationPickerPage.initialAddress].
  LatLng? _lastResolvedPoint;

  String? _addressLabel;
  bool _isResolvingAddress = false;
  bool _isLocating = false;
  bool _isSearching = false;
  String? _searchError;

  /// Places Autocomplete. Uses the *native* Places SDK rather than the HTTP
  /// web service, so the same key the map uses works here — an Android
  /// application restriction (package + SHA-1) can't be satisfied by a plain
  /// REST call, which would come back REQUEST_DENIED.
  late final places.FlutterGooglePlacesSdk _places;
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  List<places.AutocompletePrediction> _predictions = const [];
  bool _isPredicting = false;

  /// Autocomplete is billed per session: all keystrokes leading to one
  /// [_selectPrediction] count as a single session, so a new token is only
  /// requested at the start of each one.
  bool _startNewSession = true;

  @override
  void initState() {
    super.initState();
    _places = places.FlutterGooglePlacesSdk(
      AppConfig.googlePlacesApiKey,
      locale: const Locale('th'),
    );
    _searchController.addListener(_onSearchChanged);
    _searchFocus.addListener(() => setState(() {}));
    final initialAddress = widget.initialAddress;
    _center = initialAddress?.hasCoordinates == true
        ? LatLng(initialAddress!.latitude!, initialAddress.longitude!)
        : widget.defaultCenter;
    _addressLabel = initialAddress?.addressLine;

    if (_addressLabel == null || _addressLabel!.isEmpty) {
      _resolveAddress(_center);
    } else {
      _lastResolvedPoint = _center;
    }
  }

  /// Treats points within ~0.1m as the same, so float noise from the camera
  /// doesn't trigger a redundant geocode.
  bool _isSamePoint(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 1e-6 &&
      (a.longitude - b.longitude).abs() < 1e-6;

  void _onCameraIdle() {
    final last = _lastResolvedPoint;
    if (last != null && _isSamePoint(last, _center)) return;
    _resolveAddress(_center);
  }

  Future<void> _moveCamera(LatLng point) async {
    setState(() => _center = point);
    final controller = _mapController;
    if (controller == null) {
      // Map isn't created yet, so no camera idle will fire to resolve for us.
      await _resolveAddress(point);
      return;
    }
    await controller.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Debounced so a query goes out per pause in typing, not per keystroke —
  /// Places bills per session but the native SDK still round-trips each call.
  void _onSearchChanged() {
    setState(() {});

    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _predictions = const [];
        _isPredicting = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _requestPredictions(query),
    );
  }

  Future<void> _requestPredictions(String query) async {
    setState(() {
      _isPredicting = true;
      _searchError = null;
    });

    try {
      final result = await _places.findAutocompletePredictions(
        query,
        countries: AppConfig.placesCountries,
        newSessionToken: _startNewSession,
        // Bias toward what the user is currently looking at, so nearby places
        // outrank same-named ones on the other side of the country.
        origin: places.LatLng(lat: _center.latitude, lng: _center.longitude),
      );
      if (!mounted) return;

      _startNewSession = false;
      setState(() {
        _predictions = result.predictions;
        _isPredicting = false;
      });
    } catch (error, stack) {
      if (!mounted) return;
      // Autocomplete needs the Places API enabled on the key; if it isn't (or
      // the call fails), fall back to the submit-and-resolve geocoder search
      // rather than leaving the user with a dead search box.
      debugPrint('CAREMATE_PLACES autocomplete failed: $error\n$stack');
      setState(() {
        _predictions = const [];
        _isPredicting = false;
      });
    }
  }

  Future<void> _selectPrediction(
    places.AutocompletePrediction prediction,
  ) async {
    // Every field on the fork's prediction is nullable; without a place id
    // there's nothing to look up.
    final placeId = prediction.placeId;
    if (placeId == null) return;

    _searchFocus.unfocus();
    setState(() {
      _predictions = const [];
      _isSearching = true;
      _searchError = null;
    });

    try {
      final result = await _places.fetchPlace(
        placeId,
        fields: const [places.PlaceField.Location],
      );
      final latLng = result.place?.latLng;
      if (!mounted) return;

      // Selecting a place closes the billing session; the next keystroke
      // starts a fresh one.
      _startNewSession = true;

      if (latLng == null) {
        setState(() {
          _isSearching = false;
          _searchError = 'ไม่สามารถระบุพิกัดของสถานที่นี้ได้';
        });
        return;
      }

      final point = LatLng(latLng.lat, latLng.lng);
      setState(() {
        _isSearching = false;
        // Keep the name the user actually tapped ("สยามพารากอน") instead of
        // the street address reverse-geocoding would produce. Marking the
        // point resolved is what stops `onCameraIdle` overwriting it.
        _addressLabel = prediction.fullText ?? prediction.primaryText;
        _lastResolvedPoint = point;
      });
      await _moveCamera(point);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'เลือกสถานที่ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  /// Submit-and-resolve fallback behind [_requestPredictions]: forward
  /// geocoding via the `geocoding` package, which uses the device's native
  /// geocoder (Android `Geocoder` / iOS `CLGeocoder`) — free, no API key or
  /// billing. Still reachable by pressing enter, so search keeps working if
  /// the Places API isn't enabled on the key or autocomplete returns nothing.
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
      setState(() => _isSearching = false);
      await _moveCamera(point);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _resolveAddress(LatLng point) async {
    _lastResolvedPoint = point;
    setState(() => _isResolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      final label = placemarks.isEmpty
          ? null
          : _formatPlacemark(placemarks.first);
      setState(() {
        _addressLabel = label ?? _unresolvedAddressLabel;
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressLabel = _unresolvedAddressLabel;
        _isResolvingAddress = false;
      });
    }
  }

  String _formatPlacemark(Placemark p) {
    final parts = [
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return parts.isEmpty ? _unresolvedAddressLabel : parts.join(', ');
  }

  /// Never surface raw lat/long to the user as if it were a place name —
  /// the numeric coordinates still travel to the backend via [Address.latitude]
  /// / [Address.longitude], this is only the human-facing label shown when
  /// reverse-geocoding couldn't resolve one.
  static const _unresolvedAddressLabel = 'ตำแหน่งที่ปักหมุด (ไม่พบชื่อสถานที่)';

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาอนุญาตการเข้าถึงตำแหน่งเพื่อใช้งานฟีเจอร์นี้'),
          ),
        );
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเปิดบริการตำแหน่ง (GPS) ของอุปกรณ์'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _isLocating = false);
      await _moveCamera(point);
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
        addressLine: _addressLabel ?? _unresolvedAddressLabel,
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  Widget _buildPredictionList() {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: _predictions.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          final secondary = prediction.secondaryText;

          return InkWell(
            onTap: () => _selectPrediction(prediction),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.primaryText ?? prediction.fullText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (secondary != null && secondary.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            secondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _center = position.target,
            onCameraIdle: _onCameraIdle,
            // The pin is the fixed overlay below, not a map marker, so the
            // map's own controls would only get in its way.
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: AppColors.primary,
                ),
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
                          child: Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText:
                                  'ค้นหาสถานที่ เช่น ชื่อสถานที่หรือที่อยู่',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 10,
                              ),
                            ),
                            onSubmitted: _searchLocation,
                          ),
                        ),
                        if (_isSearching || _isPredicting)
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
                              _predictions = const [];
                            }),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () =>
                                _searchLocation(_searchController.text),
                          ),
                      ],
                    ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 10,
                        ),
                        child: Text(
                          _searchError!,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    if (_predictions.isNotEmpty) _buildPredictionList(),
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
                        const Icon(
                          Icons.place_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isResolvingAddress
                              ? Text(
                                  'กำลังค้นหาที่อยู่...',
                                  style: textTheme.bodyMedium,
                                )
                              : Text(
                                  _addressLabel ?? _unresolvedAddressLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
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
