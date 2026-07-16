import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.district,
    required this.state,
    required this.country,
  });

  final double latitude;
  final double longitude;
  final String area;
  final String district;
  final String state;
  final String country;

  String get shortAddress {
    final parts = <String>[
      area,
      district,
      state,
      country,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

class LocationService {
  LocationService._();

  static Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<ResolvedLocation?> resolveCurrentLocation() async {
    final granted = await ensurePermission();
    if (!granted) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return null;

    final place = placemarks.first;
    return ResolvedLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      area: _firstNonEmpty(<String?>[
        place.subLocality,
        place.locality,
        place.street,
      ]),
      district: _firstNonEmpty(<String?>[
        place.subAdministrativeArea,
        place.locality,
      ]),
      state: _firstNonEmpty(<String?>[place.administrativeArea]),
      country: _firstNonEmpty(<String?>[place.country]),
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
