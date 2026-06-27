import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../tasks/models/task_model.dart';
import '../services/location_service.dart';
import '../services/navigation_route_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final TaskLocation? initialLocation;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallbackTarget = LatLng(10.776889, 106.700806);

  final _locationService = const LocationService();
  final _navigationService = const NavigationRouteService();
  final _searchController = TextEditingController();

  final _mapController = MapController();
  LatLng _cameraTarget = _fallbackTarget;
  LatLng? _deviceLocation;
  TaskLocation? _selected;
  bool _loading = true;
  bool _searching = false;
  bool _resolvingTap = false;
  bool _useDeviceLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final initial = widget.initialLocation;
    if (initial?.isValid == true) {
      final target = LatLng(initial!.latitude, initial.longitude);
      setState(() {
        _selected = initial;
        _cameraTarget = target;
        _loading = false;
      });
      return;
    }

    try {
      final current = await _locationService.getCurrentLatLng();
      if (!mounted) return;
      if (!_isInVietnam(current)) {
        setState(() {
          _cameraTarget = _fallbackTarget;
          _useDeviceLocation = false;
          _loading = false;
          _error = LocaleService.tr(
            'Vi tri thiet bi dang o ngoai Viet Nam. Ban do duoc mo tai TP.HCM de de chon dia diem demo.',
            en: 'Device location is outside Vietnam. The map starts in Ho Chi Minh City for this demo.',
          );
        });
        return;
      }
      setState(() {
        _cameraTarget = current;
        _deviceLocation = current;
        _useDeviceLocation = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LocaleService.tr(
          'Khong lay duoc vi tri hien tai. Ban van co the chon tren ban do.',
          en: 'Could not get current location. You can still pick on the map.',
        );
      });
    }
  }

  bool _isInVietnam(LatLng point) {
    return point.latitude >= 8.18 &&
        point.latitude <= 23.39 &&
        point.longitude >= 102.14 &&
        point.longitude <= 109.46;
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final location = await _navigationService.geocodeAddress(query);
      if (!mounted) return;
      await _setSelected(location, animate: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isEmpty) {
      return LocaleService.tr(
        'Khong tim thay dia diem nay',
        en: 'Could not find this place',
      );
    }
    return text;
  }

  Future<void> _pickPoint(LatLng point) async {
    setState(() {
      _resolvingTap = true;
      _selected = TaskLocation(
        placeName: LocaleService.tr('Vi tri da chon', en: 'Selected location'),
        address: '',
        latitude: point.latitude,
        longitude: point.longitude,
      );
      _error = null;
    });

    try {
      final location = await _navigationService.reverseGeocode(point);
      if (!mounted) return;
      await _setSelected(location, animate: false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selected = TaskLocation(
          placeName:
              LocaleService.tr('Vi tri da chon', en: 'Selected location'),
          address: '',
          latitude: point.latitude,
          longitude: point.longitude,
        );
      });
    } finally {
      if (mounted) setState(() => _resolvingTap = false);
    }
  }

  Future<void> _setSelected(TaskLocation location,
      {required bool animate}) async {
    final target = LatLng(location.latitude, location.longitude);
    setState(() {
      _selected = location;
      _cameraTarget = target;
    });
    if (animate) {
      _mapController.move(target, 16);
    }
  }

  List<Marker> _markers() {
    final selected = _selected;
    if (selected == null) return const [];
    return [
      Marker(
        point: LatLng(selected.latitude, selected.longitude),
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

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.pop(context, selected);
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
          LocaleService.tr('Chon dia diem', en: 'Pick location'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _cameraTarget,
                    initialZoom: 15,
                    onTap: (_, point) => _pickPoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.prm_app',
                    ),
                    if (_useDeviceLocation)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _deviceLocation ?? _cameraTarget,
                            width: 28,
                            height: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    MarkerLayer(markers: _markers()),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: _SearchCard(
                    controller: _searchController,
                    searching: _searching,
                    error: _error,
                    onSearch: _searchAddress,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: _PickedLocationCard(
                    selected: _selected,
                    resolvingTap: _resolvingTap,
                    textColor: textColor,
                    captionColor: captionColor,
                    onConfirm: _selected == null ? null : _confirm,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final String? error;
  final VoidCallback onSearch;

  const _SearchCard({
    required this.controller,
    required this.searching,
    required this.error,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: textColor),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: LocaleService.tr(
                      'Tim dia diem hoac tap tren ban do',
                      en: 'Search or tap on the map',
                    ),
                    hintStyle: TextStyle(color: captionColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: captionColor),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: searching ? null : onSearch,
                icon: searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore_rounded),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickedLocationCard extends StatelessWidget {
  final TaskLocation? selected;
  final bool resolvingTap;
  final Color textColor;
  final Color captionColor;
  final VoidCallback? onConfirm;

  const _PickedLocationCard({
    required this.selected,
    required this.resolvingTap,
    required this.textColor,
    required this.captionColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);
    final title = selected?.displayName ??
        LocaleService.tr('Tap tren ban do de chon', en: 'Tap the map to pick');
    final subtitle = selected?.address.isNotEmpty == true
        ? selected!.address
        : selected == null
            ? LocaleService.tr(
                'Ban co the tim dia diem hoac cham vao vi tri can den.',
                en: 'Search for a place or tap the destination.',
              )
            : '${selected!.latitude.toStringAsFixed(6)}, ${selected!.longitude.toStringAsFixed(6)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: resolvingTap
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF06B6D4),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onConfirm,
            child: Text(LocaleService.tr('Chon', en: 'Use')),
          ),
        ],
      ),
    );
  }
}
