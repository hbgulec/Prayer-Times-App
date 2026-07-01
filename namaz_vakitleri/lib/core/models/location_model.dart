class LocationModel {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String countryCode;
  final String timezone;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.timezone,
  });

  factory LocationModel.defaultLocation() {
    return const LocationModel(
      latitude: 41.0082,
      longitude: 28.9784,
      city: 'İstanbul',
      country: 'Türkiye',
      countryCode: 'TR',
      timezone: 'Europe/Istanbul',
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
      timezone: json['timezone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'timezone': timezone,
    };
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? countryCode,
    String? timezone,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  String toString() => '$city, $country';
}
