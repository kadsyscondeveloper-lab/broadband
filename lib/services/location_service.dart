// lib/services/location_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final String state;
  final String city;
  final String pinCode;
  final String address; // road + suburb

  const LocationResult({
    required this.state,
    required this.city,
    required this.pinCode,
    required this.address,
  });
}

class LocationService {
  /// Returns a [LocationResult] or throws a descriptive [String] on failure.
  static Future<LocationResult> fetchCurrentLocation() async {
    // ── 1. Check / request permissions ────────────────────────────────────
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS and try again.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied. Please allow location access to use this feature.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is permanently denied. Please enable it from app settings.';
    }

    // ── 2. Get coordinates ─────────────────────────────────────────────────
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );

    // ── 3. Reverse geocode via Nominatim ───────────────────────────────────
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=${position.latitude}&lon=${position.longitude}'
      '&format=json&addressdetails=1',
    );

    final response = await http.get(
      uri,
      headers: {
        // Nominatim requires a User-Agent header
        'User-Agent': 'FlutterApp/1.0',
        'Accept-Language': 'en',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Geocoding request timed out'),
    );

    if (response.statusCode != 200) {
      throw 'Could not fetch address details. Please try again.';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final addr = data['address'] as Map<String, dynamic>? ?? {};

    // Nominatim field names vary by region; fall back gracefully
    final city = (addr['city']
            ?? addr['town']
            ?? addr['village']
            ?? addr['county']
            ?? '')
        .toString();

    final state   = (addr['state'] ?? '').toString();
    final pinCode = (addr['postcode'] ?? '').toString();

    // Build a short road/locality string for the "Address" field
    final parts = <String>[
      if (addr['road']         != null) addr['road'].toString(),
      if (addr['neighbourhood'] != null) addr['neighbourhood'].toString(),
      if (addr['suburb']       != null) addr['suburb'].toString(),
    ];
    final address = parts.join(', ');

    return LocationResult(
      state:   state,
      city:    city,
      pinCode: pinCode,
      address: address,
    );
  }
}
