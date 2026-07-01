import 'package:flutter/material.dart';
import 'package:namaz_vakitleri/core/constants/app_colors.dart';
import 'package:namaz_vakitleri/core/constants/app_strings.dart';

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerTimeModel {
  final PrayerName name;
  final DateTime time;
  bool alarmEnabled;
  int alarmMinutesBefore;
  bool alarmRecurring;

  PrayerTimeModel({
    required this.name,
    required this.time,
    this.alarmEnabled = false,
    this.alarmMinutesBefore = 0,
    this.alarmRecurring = false,
  });

  String get turkishName {
    switch (name) {
      case PrayerName.fajr:
        return AppStrings.fajr;
      case PrayerName.sunrise:
        return AppStrings.sunrise;
      case PrayerName.dhuhr:
        return AppStrings.dhuhr;
      case PrayerName.asr:
        return AppStrings.asr;
      case PrayerName.maghrib:
        return AppStrings.maghrib;
      case PrayerName.isha:
        return AppStrings.isha;
    }
  }

  String get arabicName {
    switch (name) {
      case PrayerName.fajr:
        return AppStrings.fajrAr;
      case PrayerName.sunrise:
        return AppStrings.sunriseAr;
      case PrayerName.dhuhr:
        return AppStrings.dhuhrAr;
      case PrayerName.asr:
        return AppStrings.asrAr;
      case PrayerName.maghrib:
        return AppStrings.maghribAr;
      case PrayerName.isha:
        return AppStrings.ishaAr;
    }
  }

  String get formattedTime {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color get color {
    switch (name) {
      case PrayerName.fajr:
        return AppColors.fajrColor;
      case PrayerName.sunrise:
        return AppColors.sunriseColor;
      case PrayerName.dhuhr:
        return AppColors.dhuhrColor;
      case PrayerName.asr:
        return AppColors.asrColor;
      case PrayerName.maghrib:
        return AppColors.maghribColor;
      case PrayerName.isha:
        return AppColors.ishaColor;
    }
  }

  String get iconPath {
    switch (name) {
      case PrayerName.fajr:
        return '🌙';
      case PrayerName.sunrise:
        return '🌅';
      case PrayerName.dhuhr:
        return '☀️';
      case PrayerName.asr:
        return '🌤️';
      case PrayerName.maghrib:
        return '🌇';
      case PrayerName.isha:
        return '🌃';
    }
  }

  int get notificationId => name.index;
}
