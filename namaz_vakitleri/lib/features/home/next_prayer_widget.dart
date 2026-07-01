import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakitleri/core/constants/app_colors.dart';
import 'package:namaz_vakitleri/core/models/prayer_time_model.dart';
import 'package:namaz_vakitleri/core/services/prayer_service.dart';
import 'package:namaz_vakitleri/core/constants/app_strings.dart';

class NextPrayerWidget extends StatelessWidget {
  final PrayerTimeModel? nextPrayer;
  final Duration? timeRemaining;

  const NextPrayerWidget({
    super.key,
    required this.nextPrayer,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    if (nextPrayer == null) {
      return _buildAllPrayedCard();
    }
    return _buildNextPrayerCard();
  }

  Widget _buildNextPrayerCard() {
    final prayer = nextPrayer!;
    final timeStr = timeRemaining != null
        ? PrayerService.formatDuration(timeRemaining!)
        : '--:--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            prayer.color.withOpacity(0.3),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: prayer.color.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: prayer.color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: prayer.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  prayer.iconPath,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.nextPrayer,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        prayer.turkishName,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        prayer.arabicName,
                        style: GoogleFonts.amiri(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                prayer.formattedTime,
                style: GoogleFonts.inter(
                  color: prayer.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                AppStrings.remainingTime,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              _CountdownText(timeStr: timeStr, color: prayer.color),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _getProgress(),
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(prayer.color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  double _getProgress() {
    if (timeRemaining == null || nextPrayer == null) return 0;
    // Approximate 4 hours max between prayers
    const maxSeconds = 4 * 60 * 60;
    final remaining = timeRemaining!.inSeconds;
    return 1.0 - (remaining / maxSeconds).clamp(0.0, 1.0);
  }

  Widget _buildAllPrayedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Bugünkü namazlarınız tamamlandı',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hayırlı geceler 🤲',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownText extends StatefulWidget {
  final String timeStr;
  final Color color;

  const _CountdownText({required this.timeStr, required this.color});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_CountdownText old) {
    super.didUpdateWidget(old);
    if (old.timeStr != widget.timeStr) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.timeStr,
      style: GoogleFonts.inter(
        color: widget.color,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
