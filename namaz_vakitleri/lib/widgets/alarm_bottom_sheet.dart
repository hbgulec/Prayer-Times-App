import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakitleri/core/constants/app_colors.dart';
import 'package:namaz_vakitleri/core/models/prayer_time_model.dart';
import 'package:namaz_vakitleri/core/services/storage_service.dart';

class AlarmBottomSheet extends StatefulWidget {
  final PrayerTimeModel prayer;
  final Future<void> Function(bool enable, int minutesBefore, bool recurring) onAlarmSet;

  const AlarmBottomSheet({
    super.key,
    required this.prayer,
    required this.onAlarmSet,
  });

  @override
  State<AlarmBottomSheet> createState() => _AlarmBottomSheetState();
}

class _AlarmBottomSheetState extends State<AlarmBottomSheet>
    with SingleTickerProviderStateMixin {
  late bool _alarmEnabled;
  late int _selectedMinutes;
  late bool _recurring;
  bool _loading = false;
  late AnimationController _bellCtrl;
  late Animation<double> _bellAnim;

  static const List<int> _minuteOptions = [0, 5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _alarmEnabled = widget.prayer.alarmEnabled;
    _selectedMinutes = widget.prayer.alarmMinutesBefore;
    _recurring = widget.prayer.alarmRecurring;

    // If alarm not set yet, default to 15 min before
    if (!_alarmEnabled && _selectedMinutes == 0) {
      _selectedMinutes = 15;
    }

    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bellAnim = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _bellCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    super.dispose();
  }

  Future<void> _setAlarm() async {
    setState(() => _loading = true);
    try {
      await widget.onAlarmSet(true, _selectedMinutes, _recurring);
      if (mounted) {
        setState(() {
          _alarmEnabled = true;
          _loading = false;
        });
        _bellCtrl.forward(from: 0).then((_) => _bellCtrl.reverse());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm kurulurken hata: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _cancelAlarm() async {
    setState(() => _loading = true);
    try {
      await widget.onAlarmSet(false, 0, false);
      if (mounted) {
        setState(() {
          _alarmEnabled = false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _minuteLabel(int m) {
    if (m == 0) return 'Tam\nVakitte';
    return '$m dk\nÖnce';
  }

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: prayer.color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Prayer icon + name
          AnimatedBuilder(
            animation: _bellAnim,
            builder: (context, child) => Transform.rotate(
              angle: _alarmEnabled ? _bellAnim.value : 0,
              child: child,
            ),
            child: Text(prayer.iconPath, style: const TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 8),
          Text(
            prayer.turkishName,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            prayer.arabicName,
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prayer.formattedTime,
            style: GoogleFonts.inter(
              color: prayer.color,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),

          // If alarm is active, show current status
          if (_alarmEnabled) ...[
            _buildActiveAlarmCard(prayer),
            const SizedBox(height: 16),
            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _cancelAlarm,
                  icon: const Icon(Icons.notifications_off, color: Colors.white),
                  label: Text(
                    'Alarmı İptal Et',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Minutes selection
            _buildMinutesSelector(),
            const SizedBox(height: 16),
            // Recurring toggle
            _buildRecurringToggle(),
            const SizedBox(height: 20),
            // Set alarm button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.green, AppColors.greenLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _setAlarm,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.notifications_active, color: Colors.white),
                    label: Text(
                      _selectedMinutes == 0
                          ? 'Tam Vakitte Uyar'
                          : '$_selectedMinutes Dakika Önce Uyar',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActiveAlarmCard(PrayerTimeModel prayer) {
    final earlyTime = prayer.time.subtract(Duration(minutes: _selectedMinutes));
    final h = earlyTime.hour.toString().padLeft(2, '0');
    final m = earlyTime.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: AppColors.gold, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Aktif ✅',
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _selectedMinutes == 0
                          ? '$timeStr saatinde bildirim alacaksınız'
                          : '$timeStr saatinde ($_selectedMinutes dk önce) bildirim alacaksınız',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_recurring) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 42),
                Icon(Icons.repeat, color: AppColors.gold.withOpacity(0.7), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Her gün tekrar edecek',
                  style: GoogleFonts.inter(
                    color: AppColors.gold.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinutesSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ne zaman uyarılmak istersiniz?',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _minuteOptions.map((m) {
              final isSelected = _selectedMinutes == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMinutes = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.2)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.surfaceLight,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      _minuteLabel(m),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(
              _recurring ? Icons.repeat : Icons.today,
              color: _recurring ? AppColors.gold : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recurring ? 'Her Gün Tekrarla' : 'Sadece Bugün',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _recurring
                        ? 'Alarm her gün aynı saatte çalacak'
                        : 'Alarm yalnızca bugün çalacak',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
              activeColor: AppColors.gold,
              inactiveTrackColor: AppColors.surfaceLight,
            ),
          ],
        ),
      ),
    );
  }
}
