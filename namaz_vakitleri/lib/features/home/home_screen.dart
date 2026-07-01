import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakitleri/core/constants/app_colors.dart';
import 'package:namaz_vakitleri/core/constants/app_strings.dart';
import 'package:namaz_vakitleri/core/models/location_model.dart';
import 'package:namaz_vakitleri/core/models/prayer_time_model.dart';
import 'package:namaz_vakitleri/core/services/location_service.dart';
import 'package:namaz_vakitleri/core/services/prayer_service.dart';
import 'package:namaz_vakitleri/core/services/storage_service.dart';
import 'package:namaz_vakitleri/features/home/prayer_card.dart';
import 'package:namaz_vakitleri/features/home/next_prayer_widget.dart';
import 'package:namaz_vakitleri/features/location/location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  LocationModel _location = LocationModel.defaultLocation();
  List<PrayerTimeModel> _prayers = [];
  Timer? _timer;
  Duration? _timeUntilNext;
  PrayerTimeModel? _nextPrayer;

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = StorageService.getSavedLocation();
    if (saved != null) {
      _location = saved;
    }
    _calculatePrayers();
    _startTimer();
    _headerAnimController.forward();
  }

  void _calculatePrayers() {
    setState(() {
      _prayers = PrayerService.getPrayerTimes(_location);
      _nextPrayer = PrayerService.getNextPrayer(_prayers);
      _timeUntilNext = PrayerService.getTimeUntilNextPrayer(_nextPrayer);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _timeUntilNext = PrayerService.getTimeUntilNextPrayer(_nextPrayer);
        // Recalculate at midnight or if next prayer passed
        if (_timeUntilNext == null || _timeUntilNext!.isNegative) {
          _calculatePrayers();
        }
      });
    });
  }

  Future<void> _openLocationScreen() async {
    final result = await Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(builder: (_) => const LocationScreen()),
    );
    if (result != null) {
      setState(() => _location = result);
      await StorageService.saveLocation(result);
      _calculatePrayers();
      _headerAnimController.reset();
      _headerAnimController.forward();
    }
  }

  void _onPrayerUpdated(PrayerTimeModel updated) {
    setState(() {
      final idx = _prayers.indexWhere((p) => p.name == updated.name);
      if (idx != -1) _prayers[idx] = updated;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(dateStr),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: NextPrayerWidget(
                  nextPrayer: _nextPrayer,
                  timeRemaining: _timeUntilNext,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final prayer = _prayers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PrayerCard(
                      prayer: prayer,
                      isNext: _nextPrayer?.name == prayer.name,
                      onAlarmChanged: _onPrayerUpdated,
                    ),
                  );
                },
                childCount: _prayers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(String dateStr) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      expandedHeight: 130,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1F3C), AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.prayerTimes,
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _openLocationScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.gold, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _location.city,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down,
                                  color: AppColors.textSecondary, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
