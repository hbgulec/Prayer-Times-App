import 'package:adhan/adhan.dart';
import 'package:namaz_vakitleri/core/models/location_model.dart';
import 'package:namaz_vakitleri/core/models/prayer_time_model.dart';
import 'package:namaz_vakitleri/core/services/storage_service.dart';

class PrayerService {
  static List<PrayerTimeModel> getPrayerTimes(LocationModel location, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();

    final coordinates = Coordinates(location.latitude, location.longitude);
    final dateComponents = DateComponents(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // Diyanet İşleri method (Turkey standard)
    final params = CalculationMethod.turkey.getParameters();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    final alarms = StorageService.getAllAlarms();

    return [
      PrayerTimeModel(
        name: PrayerName.fajr,
        time: prayerTimes.fajr,
        alarmEnabled: alarms[PrayerName.fajr.index] ?? false,
        alarmMinutesBefore: StorageService.getAlarmMinutesBefore(PrayerName.fajr.index),
        alarmRecurring: StorageService.isAlarmRecurring(PrayerName.fajr.index),
      ),
      PrayerTimeModel(
        name: PrayerName.sunrise,
        time: prayerTimes.sunrise,
        alarmEnabled: alarms[PrayerName.sunrise.index] ?? false,
        alarmMinutesBefore: StorageService.getAlarmMinutesBefore(PrayerName.sunrise.index),
        alarmRecurring: StorageService.isAlarmRecurring(PrayerName.sunrise.index),
      ),
      PrayerTimeModel(
        name: PrayerName.dhuhr,
        time: prayerTimes.dhuhr,
        alarmEnabled: alarms[PrayerName.dhuhr.index] ?? false,
        alarmMinutesBefore: StorageService.getAlarmMinutesBefore(PrayerName.dhuhr.index),
        alarmRecurring: StorageService.isAlarmRecurring(PrayerName.dhuhr.index),
      ),
      PrayerTimeModel(
        name: PrayerName.asr,
        time: prayerTimes.asr,
        alarmEnabled: alarms[PrayerName.asr.index] ?? false,
        alarmMinutesBefore: StorageService.getAlarmMinutesBefore(PrayerName.asr.index),
        alarmRecurring: StorageService.isAlarmRecurring(PrayerName.asr.index),
      ),
      PrayerTimeModel(
        name: PrayerName.maghrib,
        time: prayerTimes.maghrib,
        alarmEnabled: alarms[PrayerName.maghrib.index] ?? false,
        alarmMinutesBefore: StorageService.getAlarmMinutesBefore(PrayerName.maghrib.index),
        alarmRecurring: StorageService.isAlarmRecurring(PrayerName.maghrib.index),
      ),
      PrayerTimeModel(
        name: PrayerName.isha,
        time: prayerTimes.isha,
        alarmEnabled: alarms[PrayerName.isha.index] ?? false,
        alarmMinutesBefore: StorageService.getAlarmMinutesBefore(PrayerName.isha.index),
        alarmRecurring: StorageService.isAlarmRecurring(PrayerName.isha.index),
      ),
    ];
  }

  static PrayerTimeModel? getNextPrayer(List<PrayerTimeModel> prayers) {
    final now = DateTime.now();
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null; // All prayers passed today
  }

  static Duration? getTimeUntilNextPrayer(PrayerTimeModel? nextPrayer) {
    if (nextPrayer == null) return null;
    final now = DateTime.now();
    final diff = nextPrayer.time.difference(now);
    return diff.isNegative ? null : diff;
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
