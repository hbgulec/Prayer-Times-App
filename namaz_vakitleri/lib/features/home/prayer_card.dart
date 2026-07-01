import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakitleri/core/constants/app_colors.dart';
import 'package:namaz_vakitleri/core/models/prayer_time_model.dart';
import 'package:namaz_vakitleri/core/services/notification_service.dart';
import 'package:namaz_vakitleri/widgets/alarm_bottom_sheet.dart';

class PrayerCard extends StatefulWidget {
  final PrayerTimeModel prayer;
  final bool isNext;
  final ValueChanged<PrayerTimeModel> onAlarmChanged;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.isNext,
    required this.onAlarmChanged,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _scaleCtrl.reverse().then((_) => _scaleCtrl.forward());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AlarmBottomSheet(
        prayer: widget.prayer,
        onAlarmSet: _handleAlarmSet,
      ),
    );
  }

  Future<void> _handleAlarmSet(bool enable, int minutesBefore, bool recurring) async {
    if (enable) {
      await NotificationService.schedulePrayerNotification(
        widget.prayer,
        minutesBefore: minutesBefore,
        recurring: recurring,
      );
    } else {
      await NotificationService.cancelPrayerNotification(widget.prayer);
    }
    final updated = PrayerTimeModel(
      name: widget.prayer.name,
      time: widget.prayer.time,
      alarmEnabled: enable,
      alarmMinutesBefore: minutesBefore,
      alarmRecurring: recurring,
    );
    widget.onAlarmChanged(updated);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;
    final isNext = widget.isNext;
    final isPast = prayer.time.isBefore(DateTime.now());

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleCtrl.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isNext
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      prayer.color.withOpacity(0.25),
                      AppColors.surface,
                    ],
                  )
                : AppColors.cardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isNext
                  ? prayer.color.withOpacity(0.6)
                  : AppColors.surfaceLight,
              width: isNext ? 1.5 : 1,
            ),
            boxShadow: isNext
                ? [
                    BoxShadow(
                      color: prayer.color.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: isPast
                      ? prayer.color.withOpacity(0.3)
                      : prayer.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              // Icon
              Text(
                prayer.iconPath,
                style: TextStyle(
                  fontSize: 26,
                  color: isPast ? null : null,
                ),
              ),
              const SizedBox(width: 14),
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.turkishName,
                      style: GoogleFonts.inter(
                        color: isPast
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      prayer.arabicName,
                      style: GoogleFonts.amiri(
                        color: isPast
                            ? AppColors.textMuted
                            : AppColors.gold.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Time
              Text(
                prayer.formattedTime,
                style: GoogleFonts.inter(
                  color: isPast
                      ? AppColors.textMuted
                      : isNext
                          ? prayer.color
                          : AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 14),
              // Alarm icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: prayer.alarmEnabled
                      ? AppColors.gold.withOpacity(0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  prayer.alarmEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: prayer.alarmEnabled
                      ? AppColors.gold
                      : AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
