import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import 'app_card.dart';

/// Pickup/destination summary with a live map preview — ported from the
/// Partner app's `RouteMapCard` (`apps/partner_app/lib/features/shared`).
/// Booking status/detail on this app show these two addresses as plain
/// text today with no visual sense of the route; this gives that same
/// "trip in miniature" the partner-side job detail already had. A straight
/// dashed line between the two points, not a real routed path — no
/// Directions API call, so it never claims a route it hasn't drawn.
class RouteMapCard extends StatelessWidget {
  const RouteMapCard({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.mapHeight = 160,
  });

  final String pickupAddress;
  final String destinationAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final double mapHeight;

  bool get _hasCoords =>
      pickupLat != null &&
      pickupLng != null &&
      destinationLat != null &&
      destinationLng != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: _hasCoords
                  ? _LiveRouteMap(
                      pickup: LatLng(pickupLat!, pickupLng!),
                      destination: LatLng(destinationLat!, destinationLng!),
                    )
                  : const ColoredBox(
                      color: AppColors.surfaceAlt,
                      child: CustomPaint(
                        painter: _RoutePathPainter(),
                        size: Size.infinite,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _TimelineRow(
            dotColor: AppColors.success,
            label: 'จุดรับ',
            value: pickupAddress,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.5),
            child: Container(width: 1, height: 16, color: AppColors.border),
          ),
          _TimelineRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.primary,
            label: 'ปลายทาง',
            value: destinationAddress,
          ),
        ],
      ),
    );
  }
}

/// Non-interactive Google Map preview: pickup + destination markers, camera
/// fit to both, a straight dashed line between them.
class _LiveRouteMap extends StatefulWidget {
  const _LiveRouteMap({required this.pickup, required this.destination});

  final LatLng pickup;
  final LatLng destination;

  @override
  State<_LiveRouteMap> createState() => _LiveRouteMapState();
}

class _LiveRouteMapState extends State<_LiveRouteMap> {
  GoogleMapController? _controller;

  // Reused whenever the caller rebuilds with a new pickup/destination —
  // GoogleMap's initialCameraPosition only applies on first creation, so
  // without this the camera stays parked on the original bounds even
  // though the markers themselves move on rebuild.
  @override
  void didUpdateWidget(covariant _LiveRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller != null &&
        (widget.pickup != oldWidget.pickup ||
            widget.destination != oldWidget.destination)) {
      _fitBounds(controller);
    }
  }

  void _fitBounds(GoogleMapController controller) {
    final south = math.min(widget.pickup.latitude, widget.destination.latitude);
    final north = math.max(widget.pickup.latitude, widget.destination.latitude);
    final west = math.min(
      widget.pickup.longitude,
      widget.destination.longitude,
    );
    final east = math.max(
      widget.pickup.longitude,
      widget.destination.longitude,
    );
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final midpoint = LatLng(
      (widget.pickup.latitude + widget.destination.latitude) / 2,
      (widget.pickup.longitude + widget.destination.longitude) / 2,
    );

    // The map is a static preview, every gesture below is disabled — wrap
    // in IgnorePointer so the native platform view never claims touches
    // that should fall through to the parent scroll view.
    return IgnorePointer(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: midpoint, zoom: 12),
        onMapCreated: (controller) {
          _controller = controller;
          _fitBounds(controller);
        },
        markers: {
          Marker(
            markerId: const MarkerId('pickup'),
            position: widget.pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [widget.pickup, widget.destination],
            color: AppColors.primary,
            width: 3,
            patterns: [PatternItem.dash(12), PatternItem.gap(8)],
          ),
        },
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    this.dotColor,
    this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 10,
          height: 20,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 16, color: iconColor)
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Faint dashed "as the crow flies" placeholder shown when either point has
/// no coordinates yet, so the card never has to sit empty.
class _RoutePathPainter extends CustomPainter {
  const _RoutePathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = AppColors.border.withValues(alpha: 0.7);
    const step = 14.0;
    for (double y = 7; y < size.height; y += step) {
      for (double x = 7; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.6, dotPaint);
      }
    }

    final startX = size.width * 0.09;
    final endX = size.width * 0.91;
    final startY = size.height * 0.71;
    final endY = size.height * 0.29;

    final path = Path()
      ..moveTo(startX, startY)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.29,
        size.width * 0.62,
        size.height * 0.86,
        endX,
        endY,
      );

    final dashPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashLength = 1.0;
    const gapLength = 8.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), dashPaint);
        distance = next + gapLength;
      }
    }

    void dot(Offset center, Color color) {
      canvas.drawCircle(center, 6, Paint()..color = Colors.white);
      canvas.drawCircle(center, 4, Paint()..color = color);
    }

    dot(Offset(startX, startY), AppColors.success);
    dot(Offset(endX, endY), AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
