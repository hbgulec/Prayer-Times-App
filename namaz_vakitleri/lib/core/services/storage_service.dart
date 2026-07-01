import 'package:hive_flutter/hive_flutter.dart';
import 'package:namaz_vakitleri/core/models/location_model.dart';

class StorageService {
  static const String _locationBoxName = 'location_box';
  static const String _alarmsBoxName = 'alarms_box';
  static const String _locationKey = 'saved_location';

  static late Box _locationBox;
  static late Box _alarmsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _locationBox = await Hive.openBox(_locationBoxName);
    _alarmsBox = await Hive.openBox(_alarmsBoxName);
  }

  // Location
  static Future<void> saveLocation(LocationModel location) async {
    await _locationBox.put(_locationKey, location.toJson());
  }

  static LocationModel? getSavedLocation() {
    final data = _locationBox.get(_locationKey);
    if (data == null) return null;
    return LocationModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // Alarms
  static Future<void> setAlarm(int prayerIndex, bool enabled) async {
    await _alarmsBox.put('alarm_$prayerIndex', enabled);
  }

  static Future<void> setAlarmDetails(int prayerIndex, {
    required bool enabled,
    required int minutesBefore,
    required bool recurring,
  }) async {
    await _alarmsBox.put('alarm_$prayerIndex', enabled);
    await _alarmsBox.put('alarm_${prayerIndex}_minutes', minutesBefore);
    await _alarmsBox.put('alarm_${prayerIndex}_recurring', recurring);
  }

  static bool isAlarmEnabled(int prayerIndex) {
    return _alarmsBox.get('alarm_$prayerIndex', defaultValue: false) as bool;
  }

  static int getAlarmMinutesBefore(int prayerIndex) {
    return _alarmsBox.get('alarm_${prayerIndex}_minutes', defaultValue: 0) as int;
  }

  static bool isAlarmRecurring(int prayerIndex) {
    return _alarmsBox.get('alarm_${prayerIndex}_recurring', defaultValue: false) as bool;
  }

  static Map<int, bool> getAllAlarms() {
    final map = <int, bool>{};
    for (int i = 0; i < 6; i++) {
      map[i] = isAlarmEnabled(i);
    }
    return map;
  }

  static Future<void> clearAll() async {
    await _locationBox.clear();
    await _alarmsBox.clear();
  }
}
