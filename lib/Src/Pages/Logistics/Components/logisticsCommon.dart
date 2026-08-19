import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';

const googleMapsEnabled = bool.fromEnvironment(
  'GOOGLE_MAPS_ENABLED',
  defaultValue: false,
);

class LogisticsStatusBadge extends StatelessWidget {
  const LogisticsStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  (Color, Color) _colors(String value) {
    switch (value) {
      case 'ready':
      case 'posted':
        return (const Color(0xFFE5F1FF), const Color(0xFF1766A5));
      case 'in_progress':
      case 'in_transit':
      case 'out_for_delivery':
        return (const Color(0xFFFFE8D2), const Color(0xFFA65300));
      case 'completed':
      case 'delivered':
        return (const Color(0xFFD9F6EA), const Color(0xFF14734E));
      case 'cancelled':
      case 'exception':
      case 'delayed':
      case 'absent':
        return (const Color(0xFFF9DDDD), AppColors.danger);
      default:
        return (const Color(0xFFFFF1BF), const Color(0xFF806000));
    }
  }
}

class LogisticsMetricCard extends StatelessWidget {
  const LogisticsMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 178),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LogisticsRouteMap extends StatelessWidget {
  const LogisticsRouteMap({super.key, required this.route});

  final RoutePlan route;

  @override
  Widget build(BuildContext context) {
    final points = _points(route);
    if (!googleMapsEnabled || points.isEmpty) {
      return _RouteMapFallback(route: route);
    }

    final markers = <Marker>{};
    if (route.origin.hasCoordinates) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(
            route.origin.latitude!,
            route.origin.longitude!,
          ),
          infoWindow: InfoWindow(
            title: 'Origem',
            snippet: route.origin.formatted,
          ),
        ),
      );
    }
    for (final stop in route.stops) {
      if (!stop.address.hasCoordinates) continue;
      markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: LatLng(
            stop.address.latitude!,
            stop.address.longitude!,
          ),
          infoWindow: InfoWindow(
            title: '${stop.sequence}. ${stop.clientName}',
            snippet: stop.kindLabel,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: points.first, zoom: 11),
        markers: markers,
        polylines: {
          Polyline(
            polylineId: const PolylineId('optimized-route'),
            points: points,
            width: 5,
            color: AppColors.cyan,
          ),
        },
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  List<LatLng> _points(RoutePlan route) {
    if (route.polylinePoints.isNotEmpty) {
      return route.polylinePoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }
    return [
      if (route.origin.hasCoordinates)
        LatLng(route.origin.latitude!, route.origin.longitude!),
      ...route.stops
          .where((stop) => stop.address.hasCoordinates)
          .map(
            (stop) => LatLng(
              stop.address.latitude!,
              stop.address.longitude!,
            ),
          ),
    ];
  }
}

class _RouteMapFallback extends StatelessWidget {
  const _RouteMapFallback({required this.route});

  final RoutePlan route;

  @override
  Widget build(BuildContext context) {
    final previewStops = route.stops.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, color: AppColors.cyan),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Sequência otimizada',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RoutePoint(
            number: 'A',
            label: route.origin.formatted.isEmpty
                ? 'Origem da rota'
                : route.origin.formatted,
            highlighted: true,
          ),
          ...previewStops.map(
            (stop) => _RoutePoint(
              number: '${stop.sequence}',
              label: stop.clientName,
            ),
          ),
          if (route.stops.length > previewStops.length)
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 6),
              child: Text(
                '+ ${route.stops.length - previewStops.length} paradas',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          if (!googleMapsEnabled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Ative GOOGLE_MAPS_ENABLED no ambiente após configurar as chaves do Google Maps.',
                style: TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.number,
    required this.label,
    this.highlighted = false,
  });

  final String number;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? AppColors.navy : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: highlighted ? AppColors.navy : AppColors.cyan,
              ),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: highlighted ? AppColors.lime : AppColors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.ink, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

String logisticsDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String logisticsDateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${logisticsDate(local)} às ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String logisticsDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours == 0) return '${minutes}min';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
}
