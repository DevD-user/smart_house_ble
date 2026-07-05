import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme/theme_provider.dart';

/// Data class holding current theme palette colors to avoid hardcoded colors in the tree.
class ThemePalette {
  final Color background;
  final Color card;
  final Color accent;
  final Color secondaryAccent;
  final Color text;
  final Color subText;
  final bool isDark;

  const ThemePalette({
    required this.background,
    required this.card,
    required this.accent,
    required this.secondaryAccent,
    required this.text,
    required this.subText,
    required this.isDark,
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Resolve global theme state once
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // 2. Map current theme state to approved design specification colors
    final palette = ThemePalette(
      background: isDark ? const Color(0xFF0F1115) : const Color(0xFFF7F9FC),
      card: isDark ? const Color(0xFF1A1D24) : Colors.white,
      accent: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E),
      secondaryAccent: isDark ? const Color(0xFF2979FF) : const Color(0xFF0288D1),
      text: isDark ? Colors.white : const Color(0xFF0F1115),
      subText: isDark ? Colors.white54 : Colors.black54,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Smart House BLE',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: palette.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              palette.isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: palette.text,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConnectionStatusCard(palette: palette),
              const SizedBox(height: 16),
              VoltageGaugeCard(palette: palette),
              const SizedBox(height: 16),
              TelemetryGraphCard(palette: palette),
              const SizedBox(height: 16),
              QuickControlsCard(palette: palette),
              const SizedBox(height: 16),
              ActiveDeviceCard(palette: palette),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Connection Status Card
class ConnectionStatusCard extends StatefulWidget {
  final ThemePalette palette;

  const ConnectionStatusCard({super.key, required this.palette});

  @override
  State<ConnectionStatusCard> createState() => _ConnectionStatusCardState();
}

class _ConnectionStatusCardState extends State<ConnectionStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: widget.palette.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.palette.accent.withValues(alpha: _pulseAnimation.value),
                        boxShadow: [
                          BoxShadow(
                            color: widget.palette.accent.withValues(alpha: 0.4 * _pulseAnimation.value),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  'Connection Status: ',
                  style: TextStyle(
                    color: widget.palette.subText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Connected',
                  style: TextStyle(
                    color: widget.palette.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Board', 'CC2640R2 LaunchPad'),
                _buildInfoCol('RSSI', '-61 dBm'),
                _buildInfoCol('Uptime', '12m 42s'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.palette.subText.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: widget.palette.text,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// 3. Circular Voltage Gauge Card
class VoltageGaugeCard extends StatelessWidget {
  final ThemePalette palette;

  const VoltageGaugeCard({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    // Current calibrated hardware maximum is 3832.5 ADC count ceiling.
    // At current ADC reading of 3066, this equals exactly 80.0% of the ceiling.
    const double currentAdc = 3066;
    const double maxAdc = 3832.5;
    const double percentage = (currentAdc / maxAdc) * 100;

    return Card(
      color: palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Text(
              'Voltage Sensor',
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 12,
                        backgroundColor: palette.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '2.47 V',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ADC: ${currentAdc.toInt()}',
                          style: TextStyle(
                            color: palette.subText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4. Live Telemetry Graph Card
class TelemetryGraphCard extends StatelessWidget {
  final ThemePalette palette;

  const TelemetryGraphCard({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Monitoring',
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: TelemetryGraphPainter(palette: palette),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelemetryGraphPainter extends CustomPainter {
  final ThemePalette palette;

  TelemetryGraphPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Premium simulated wave points (fitting inside visual limits)
    final points = [
      Offset(0, height * 0.75),
      Offset(width * 0.15, height * 0.60),
      Offset(width * 0.3, height * 0.35),
      Offset(width * 0.45, height * 0.85),
      Offset(width * 0.6, height * 0.45),
      Offset(width * 0.75, height * 0.55),
      Offset(width * 0.9, height * 0.20),
      Offset(width, height * 0.40),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final xc = (p0.dx + p1.dx) / 2;
      final yc = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Create gradient fill structure underneath the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.accent.withValues(alpha: 0.20),
          palette.accent.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTRB(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TelemetryGraphPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}

/// 5. Quick Controls Section
class QuickControlsCard extends StatelessWidget {
  final ThemePalette palette;

  const QuickControlsCard({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Controls',
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildControlTile(
                    label: 'Red LED',
                    icon: Icons.lightbulb_outline,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlTile(
                    label: 'Green LED',
                    icon: Icons.lightbulb_outline,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlTile(
                    label: 'Emergency OFF',
                    icon: Icons.power_settings_new,
                    color: Colors.red,
                    isEmergency: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTile({
    required String label,
    required IconData icon,
    required Color color,
    bool isEmergency = false,
  }) {
    final bool isDark = palette.isDark;
    final Color buttonBg = isEmergency
        ? color.withValues(alpha: 0.15)
        : isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02);

    final Color borderCol = isEmergency
        ? color.withValues(alpha: 0.35)
        : isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);

    return InkWell(
      onTap: () {
        // UI-only placeholder for now
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: buttonBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEmergency ? color : palette.accent,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. Active Device Card
class ActiveDeviceCard extends StatelessWidget {
  final ThemePalette palette;

  const ActiveDeviceCard({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Device',
                  style: TextStyle(
                    color: palette.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'CC2640R2 LaunchPad',
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Sync: 0.2 sec ago',
                  style: TextStyle(
                    color: palette.subText.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Healthy',
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
