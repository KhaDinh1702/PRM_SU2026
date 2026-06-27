import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
import '../models/route_info.dart';
import '../services/location_service.dart';
import '../services/navigation_route_service.dart';

class TaskNavigationScreen extends StatefulWidget {
  final TaskModel task;

  const TaskNavigationScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskNavigationScreen> createState() => _TaskNavigationScreenState();
}

class _TaskNavigationScreenState extends State<TaskNavigationScreen> {
  final _locationService = const LocationService();
  final _routeService = const NavigationRouteService();
  final _taskService = const TaskService();

  final _mapController = MapController();
  StreamSubscription<LatLng>? _positionSub;
  LatLng? _current;
  RouteInfo? _route;
  String? _error;
  bool _loading = true;
  bool _arrivalShown = false;
  bool _completing = false;

  LatLng get _destination => LatLng(
        widget.task.location!.latitude,
        widget.task.location!.longitude,
      );

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    try {
      final current = await _locationService.getCurrentLatLng();
      final route = await _routeService.computeRoute(
        origin: current,
        destination: _destination,
      );
      if (!mounted) return;
      setState(() {
        _current = current;
        _route = route;
        _loading = false;
        _error = null;
      });
      _fitRouteBounds();
      _listenLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _listenLocation() {
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream().listen((position) {
      if (!mounted) return;
      setState(() => _current = position);
      _checkArrival(position);
    });
  }

  void _checkArrival(LatLng position) {
    if (_arrivalShown) return;
    final location = widget.task.location;
    if (location == null) return;

    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      location.latitude,
      location.longitude,
    );
    if (meters <= location.reminderRadiusMeters) {
      _arrivalShown = true;
      _showArrivalDialog();
    }
  }

  Future<void> _showArrivalDialog() async {
    if (!mounted) return;
    final complete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(LocaleService.tr('Da den gan dia diem', en: 'Arrived nearby')),
        content: Text(
          LocaleService.tr(
            'Ban co muon danh dau task nay la hoan thanh khong?',
            en: 'Mark this task as completed?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleService.tr('De sau', en: 'Later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocaleService.tr('Hoan thanh', en: 'Complete')),
          ),
        ],
      ),
    );
    if (complete == true) await _completeTask();
  }

  Future<void> _completeTask() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await _taskService.updateTaskStatus(
        taskId: widget.task.id,
        newStatus: 'Completed',
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleService.tr(
            'Khong the cap nhat task',
            en: 'Could not update task',
          )),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fitRouteBounds() async {
    final current = _current;
    if (current == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (current.latitude == _destination.latitude &&
        current.longitude == _destination.longitude) {
      _mapController.move(_destination, 16);
      return;
    }
    final points = <LatLng>[
      current,
      _destination,
      ...?_route?.points,
    ];
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(72),
      ),
    );
  }

  List<Marker> _markers() {
    final current = _current;
    return [
      if (current != null)
        Marker(
          point: current,
          width: 34,
          height: 34,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      Marker(
        point: _destination,
        width: 46,
        height: 46,
        child: const Icon(
          Icons.location_on_rounded,
          color: Colors.redAccent,
          size: 44,
        ),
      ),
    ];
  }

  List<Polyline> _polylines() {
    final route = _route;
    if (route == null || route.points.isEmpty) return const [];
    return [
      Polyline(
        points: route.points,
        color: const Color(0xFF06B6D4),
        strokeWidth: 6,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Scaffold(
      backgroundColor: ThemeService.getBackgroundColor(isDark),
      appBar: AppBar(
        backgroundColor: ThemeService.getBackgroundColor(isDark),
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          LocaleService.tr('Chi duong task', en: 'Task navigation'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _NavigationError(
              message: _error!,
              onRetry: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadRoute();
              },
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _current ?? _destination,
                initialZoom: 14,
                onMapReady: _fitRouteBounds,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.prm_app',
                ),
                PolylineLayer(polylines: _polylines()),
                MarkerLayer(markers: _markers()),
              ],
            ),
          if (!_loading && _error == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _NavigationInfoCard(
                task: widget.task,
                route: _route,
                captionColor: captionColor,
                textColor: textColor,
                completing: _completing,
                onComplete: _completeTask,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavigationInfoCard extends StatelessWidget {
  final TaskModel task;
  final RouteInfo? route;
  final Color textColor;
  final Color captionColor;
  final bool completing;
  final VoidCallback onComplete;

  const _NavigationInfoCard({
    required this.task,
    required this.route,
    required this.textColor,
    required this.captionColor,
    required this.completing,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.location!.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (task.location!.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.location!.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(
                icon: Icons.route_rounded,
                label: route?.distanceLabel ?? '--',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.schedule_rounded,
                label: route?.durationLabel ?? '--',
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: completing ? null : onComplete,
                icon: completing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(LocaleService.tr('Xong', en: 'Done')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF06B6D4)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF06B6D4),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NavigationError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, color: captionColor, size: 48),
            const SizedBox(height: 14),
            Text(
              LocaleService.tr('Khong the tai tuyen duong',
                  en: 'Could not load route'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: captionColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(LocaleService.tr('Thu lai', en: 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}
