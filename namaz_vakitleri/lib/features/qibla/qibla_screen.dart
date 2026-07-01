import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakitleri/core/constants/app_colors.dart';
import 'package:namaz_vakitleri/core/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _permissionGranted = false;
  bool _checking = true;

  double? _qiblaAngle;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkPermissionAndLocation();
  }

  Future<void> _checkPermissionAndLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final loc = await LocationService.getCurrentLocation();
      if (loc != null) {
        _qiblaAngle = _calculateQibla(loc.latitude, loc.longitude);
      }
    }
    
    if (mounted) {
      setState(() {
        _permissionGranted = status.isGranted;
        _checking = false;
      });
    }
  }

  double _calculateQibla(double lat, double lng) {
    const double meccaLat = 21.422487;
    const double meccaLng = 39.826206;

    final double lat1 = lat * math.pi / 180.0;
    final double lng1 = lng * math.pi / 180.0;
    final double lat2 = meccaLat * math.pi / 180.0;
    final double lng2 = meccaLng * math.pi / 180.0;

    final double dLng = lng2 - lng1;

    final double y = math.sin(dLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    double qibla = math.atan2(y, x) * 180.0 / math.pi;
    if (qibla < 0) {
      qibla += 360.0;
    }
    return qibla;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_checking)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
            else if (!_permissionGranted)
              _buildPermissionDenied()
            else
              _buildQiblaCompass(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldGradient.createShader(bounds),
                child: const Text(
                  '🕌',
                  style: TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Kıble',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mekke\'nin bulunduğu yönü gösterir',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaCompass() {
    return Expanded(
      child: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final heading = snapshot.data?.heading;
          if (heading == null) {
            return _buildError('Pusula verisi alınamadı.\nCihazınızda pusula sensörü olmayabilir.');
          }

          // If location hasn't been determined yet
          final targetQibla = _qiblaAngle ?? 0.0;
          
          // Calculate the difference between current heading and qibla
          final currentQiblaOffset = (targetQibla - heading) % 360;

          final qiblaAngleRad = currentQiblaOffset * (math.pi / 180);
          final compassAngleRad = -heading * (math.pi / 180);

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Compass
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) => Transform.scale(
                  scale: _isAligned(currentQiblaOffset) ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isAligned(currentQiblaOffset)
                                  ? AppColors.gold.withOpacity(0.3)
                                  : AppColors.green.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Compass rose (rotates with device)
                      Transform.rotate(
                        angle: compassAngleRad,
                        child: _buildCompassRose(),
                      ),
                      // Qibla needle (always points to Mecca)
                      Transform.rotate(
                        angle: qiblaAngleRad,
                        child: _buildQiblaNeedle(),
                      ),
                      // Center dot
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Angle info
              _buildInfoCard(targetQibla, currentQiblaOffset),
              const SizedBox(height: 10),
              // Calibration tip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kalibre etmek için telefonu 8 şeklinde hareket ettirin',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isAligned(double offset) {
    final normOffset = offset % 360;
    return normOffset.abs() < 5 || (360 - normOffset.abs()) < 5;
  }

  Widget _buildCompassRose() {
    return CustomPaint(
      size: const Size(230, 230),
      painter: _CompassRosePainter(),
    );
  }

  Widget _buildQiblaNeedle() {
    return SizedBox(
      width: 230,
      height: 230,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Kaabe icon at tip
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Text('🕋', style: TextStyle(fontSize: 16)),
            ),
          ),
          // Needle body
          Container(
            width: 3,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.gold, AppColors.gold.withOpacity(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double targetQibla, double currentOffset) {
    if (_qiblaAngle == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text('Konum hesaplanıyor...', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final targetStr = targetQibla.toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoItem(
            label: 'Kıble Açısı',
            value: '$targetStr°',
            icon: Icons.explore,
          ),
          Container(width: 1, height: 40, color: AppColors.surfaceLight),
          const _InfoItem(
            label: 'Koordinat',
            value: '21.4°K 39.8°D',
            icon: Icons.location_on,
          ),
          Container(width: 1, height: 40, color: AppColors.surfaceLight),
          _InfoItem(
            label: 'Durum',
            value: _isAligned(currentOffset) ? '✅ Doğru' : '🔄 Çevir',
            icon: null,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off,
                  color: AppColors.textMuted, size: 64),
              const SizedBox(height: 20),
              Text(
                'Konum İzni Gerekli',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kıble yönünü hesaplamak için konum izniniz gerekiyor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: Text('Ayarlara Git',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Expanded(
      child: Center(
        child: Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: AppColors.gold, size: 18),
        if (icon != null) const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final ringPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, ringPaint);

    // Degree ticks
    final tickPaint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1;
    for (int i = 0; i < 360; i += 10) {
      final angle = i * math.pi / 180;
      final isMain = i % 90 == 0;
      final isMinor = i % 30 == 0;
      final tickLen = isMain ? 18.0 : isMinor ? 12.0 : 6.0;
      final outer = Offset(
        center.dx + (radius - 2) * math.sin(angle),
        center.dy - (radius - 2) * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - 2 - tickLen) * math.sin(angle),
        center.dy - (radius - 2 - tickLen) * math.cos(angle),
      );
      tickPaint.color =
          isMain ? AppColors.gold : AppColors.textMuted.withOpacity(0.5);
      tickPaint.strokeWidth = isMain ? 2 : 1;
      canvas.drawLine(outer, inner, tickPaint);
    }

    // Cardinal letters
    const letters = ['K', 'D', 'G', 'B'];
    const angles = [0.0, 90.0, 180.0, 270.0];
    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * math.pi / 180;
      final pos = Offset(
        center.dx + (radius - 30) * math.sin(angle),
        center.dy - (radius - 30) * math.cos(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: TextStyle(
            color: i == 0 ? AppColors.gold : AppColors.textSecondary,
            fontSize: i == 0 ? 16 : 13,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

