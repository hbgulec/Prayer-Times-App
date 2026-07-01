import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:namaz_vakitleri/core/models/location_model.dart';

class LocationService {
  static Future<LocationModel?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition();

    return await _positionToLocationModel(position);
  }

  static Future<LocationModel?> _positionToLocationModel(
      Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Bilinmeyen Şehir';
        final country = place.country ?? 'Bilinmeyen Ülke';
        final countryCode = place.isoCountryCode ?? 'XX';
        final timezone = await _getTimezoneForCoords(
            position.latitude, position.longitude);

        return LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          city: city,
          country: country,
          countryCode: countryCode,
          timezone: timezone,
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<String> _getTimezoneForCoords(double lat, double lng) async {
    // Simple timezone approximation by longitude
    // More precise: use flutter_timezone or a TZ API
    return 'UTC';
  }

  static bool hasLocationPermission = false;

  static Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    hasLocationPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    return hasLocationPermission;
  }
}

// Popular cities data for search
class CityData {
  static const List<Map<String, dynamic>> popularCities = [
    {'city': 'İstanbul', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 41.0082, 'lng': 28.9784, 'tz': 'Europe/Istanbul'},
    {'city': 'Ankara', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 39.9334, 'lng': 32.8597, 'tz': 'Europe/Istanbul'},
    {'city': 'İzmir', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 38.4189, 'lng': 27.1287, 'tz': 'Europe/Istanbul'},
    {'city': 'Bursa', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 40.1885, 'lng': 29.0610, 'tz': 'Europe/Istanbul'},
    {'city': 'Antalya', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 36.8969, 'lng': 30.7133, 'tz': 'Europe/Istanbul'},
    {'city': 'Konya', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 37.8716, 'lng': 32.4844, 'tz': 'Europe/Istanbul'},
    {'city': 'Adana', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 37.0000, 'lng': 35.3213, 'tz': 'Europe/Istanbul'},
    {'city': 'Gaziantep', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 37.0662, 'lng': 37.3833, 'tz': 'Europe/Istanbul'},
    {'city': 'Trabzon', 'country': 'Türkiye', 'countryCode': 'TR', 'lat': 41.0015, 'lng': 39.7178, 'tz': 'Europe/Istanbul'},
    {'city': 'Mekke', 'country': 'Suudi Arabistan', 'countryCode': 'SA', 'lat': 21.3891, 'lng': 39.8579, 'tz': 'Asia/Riyadh'},
    {'city': 'Medine', 'country': 'Suudi Arabistan', 'countryCode': 'SA', 'lat': 24.5247, 'lng': 39.5692, 'tz': 'Asia/Riyadh'},
    {'city': 'Riyad', 'country': 'Suudi Arabistan', 'countryCode': 'SA', 'lat': 24.7136, 'lng': 46.6753, 'tz': 'Asia/Riyadh'},
    {'city': 'Dubai', 'country': 'BAE', 'countryCode': 'AE', 'lat': 25.2048, 'lng': 55.2708, 'tz': 'Asia/Dubai'},
    {'city': 'Kahire', 'country': 'Mısır', 'countryCode': 'EG', 'lat': 30.0444, 'lng': 31.2357, 'tz': 'Africa/Cairo'},
    {'city': 'Londra', 'country': 'İngiltere', 'countryCode': 'GB', 'lat': 51.5074, 'lng': -0.1278, 'tz': 'Europe/London'},
    {'city': 'Berlin', 'country': 'Almanya', 'countryCode': 'DE', 'lat': 52.5200, 'lng': 13.4050, 'tz': 'Europe/Berlin'},
    {'city': 'Paris', 'country': 'Fransa', 'countryCode': 'FR', 'lat': 48.8566, 'lng': 2.3522, 'tz': 'Europe/Paris'},
    {'city': 'Amsterdam', 'country': 'Hollanda', 'countryCode': 'NL', 'lat': 52.3676, 'lng': 4.9041, 'tz': 'Europe/Amsterdam'},
    {'city': 'New York', 'country': 'ABD', 'countryCode': 'US', 'lat': 40.7128, 'lng': -74.0060, 'tz': 'America/New_York'},
    {'city': 'Los Angeles', 'country': 'ABD', 'countryCode': 'US', 'lat': 34.0522, 'lng': -118.2437, 'tz': 'America/Los_Angeles'},
    {'city': 'Toronto', 'country': 'Kanada', 'countryCode': 'CA', 'lat': 43.6532, 'lng': -79.3832, 'tz': 'America/Toronto'},
    {'city': 'Kuala Lumpur', 'country': 'Malezya', 'countryCode': 'MY', 'lat': 3.1390, 'lng': 101.6869, 'tz': 'Asia/Kuala_Lumpur'},
    {'city': 'Jakarta', 'country': 'Endonezya', 'countryCode': 'ID', 'lat': -6.2088, 'lng': 106.8456, 'tz': 'Asia/Jakarta'},
    {'city': 'Tahran', 'country': 'İran', 'countryCode': 'IR', 'lat': 35.6892, 'lng': 51.3890, 'tz': 'Asia/Tehran'},
    {'city': 'Bağdat', 'country': 'Irak', 'countryCode': 'IQ', 'lat': 33.3152, 'lng': 44.3661, 'tz': 'Asia/Baghdad'},
    {'city': 'Amman', 'country': 'Ürdün', 'countryCode': 'JO', 'lat': 31.9454, 'lng': 35.9284, 'tz': 'Asia/Amman'},
    {'city': 'Beyrut', 'country': 'Lübnan', 'countryCode': 'LB', 'lat': 33.8938, 'lng': 35.5018, 'tz': 'Asia/Beirut'},
    {'city': 'Karachi', 'country': 'Pakistan', 'countryCode': 'PK', 'lat': 24.8607, 'lng': 67.0011, 'tz': 'Asia/Karachi'},
    {'city': 'Dakka', 'country': 'Bangladeş', 'countryCode': 'BD', 'lat': 23.8103, 'lng': 90.4125, 'tz': 'Asia/Dhaka'},
    {'city': 'Lagos', 'country': 'Nijerya', 'countryCode': 'NG', 'lat': 6.5244, 'lng': 3.3792, 'tz': 'Africa/Lagos'},
  ];

  static List<Map<String, dynamic>> search(String query) {
    if (query.isEmpty) return popularCities;
    final q = query.toLowerCase();
    return popularCities.where((c) {
      return (c['city'] as String).toLowerCase().contains(q) ||
          (c['country'] as String).toLowerCase().contains(q);
    }).toList();
  }

  static LocationModel toLocationModel(Map<String, dynamic> data) {
    return LocationModel(
      latitude: (data['lat'] as num).toDouble(),
      longitude: (data['lng'] as num).toDouble(),
      city: data['city'] as String,
      country: data['country'] as String,
      countryCode: data['countryCode'] as String,
      timezone: data['tz'] as String,
    );
  }
}
