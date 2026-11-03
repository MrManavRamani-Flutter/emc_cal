import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/production_provider.dart';
import 'main_layout.dart';

/// OM MAVTAR GROUP — Enterprise Animated Splash Screen
/// Features:
/// - Ultra-HD responsive embroidery backdrop with radial gradient lighting.
/// - Vector SVG OM emblem with zero pixelation at any resolution (Retina / 4K / 1080p).
/// - Dynamic embroidery hoop stitching animation (custom painter).
/// - Multi-stage database & khata initialization progress indicator.
/// - Keyboard shortcuts (Enter, Space, Esc) or click anywhere to skip.
/// - Replayable anytime from Settings.
class SplashScreen extends StatefulWidget {
  final bool isReplay;
  final Duration totalDuration;

  const SplashScreen({
    super.key,
    this.isReplay = false,
    this.totalDuration = const Duration(milliseconds: 2400),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;

  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _stitchProgress;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _progressValue;
  late final Animation<double> _exitFade;

  bool _hasNavigated = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bgFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.65),
      ),
    );

    _logoFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.08, 0.40, curve: Curves.easeIn),
    );

    _stitchProgress = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.15, 0.85, curve: Curves.easeInOutCubic),
    );

    _titleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeIn),
    );

    _titleSlide = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _progressValue = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.12, 0.94, curve: Curves.easeInOutCubic),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.92, 1.0, curve: Curves.easeOut),
      ),
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToMain();
      }
    });

    _mainController.forward();
  }

  void _navigateToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _pulseController.stop();

    if (widget.isReplay) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => const MainLayout(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getStatusText(double progress) {
    if (progress < 0.22) {
      return 'Initializing OM MAVTAR Database Engine...';
    } else if (progress < 0.48) {
      return 'Loading Khatas (Beads, 250 Area, 400 Area)...';
    } else if (progress < 0.72) {
      return 'Configuring Machine Inventories & Stitch Ledger...';
    } else if (progress < 0.92) {
      return 'Preparing Factory Production Dashboard...';
    } else {
      return 'Welcome to OM MAVTAR GROUP!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    final accent = AppTheme.parseColor(provider.settings.themeColorHex);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.escape) {
            _navigateToMain();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _navigateToMain,
        child: Scaffold(
          backgroundColor: const Color(0xFF030712),
          body: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _pulseController]),
            builder: (context, _) {
              final progress = _progressValue.value;
              final percent = (progress * 100).toInt().clamp(0, 100);

              return Opacity(
                opacity: _exitFade.value.clamp(0.0, 1.0),
                child: Stack(
                  children: [
                    // 1. High-Resolution Embroidery Machine Artwork Backdrop
                    Positioned.fill(
                      child: Opacity(
                        opacity: (_bgFade.value * 0.28).clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/images/splash_banner.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ),

                    // 2. Cinematic Radial Vignette & Gradient Overlays
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.1,
                            colors: [
                              const Color(0xFF0F172A).withValues(alpha: 0.65),
                              const Color(0xFF060B18).withValues(alpha: 0.92),
                              const Color(0xFF020617),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 3. Subtle Cross-Hatch Embroidery Thread Mesh Pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EmbroideryGridBackgroundPainter(),
                      ),
                    ),

                    // 4. Central Content Card & Branding
                    Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Central Animated Emblem with Stitched Ring
                              Transform.scale(
                                scale: _logoScale.value,
                                child: Opacity(
                                  opacity: _logoFade.value.clamp(0.0, 1.0),
                                  child: SizedBox(
                                    width: 190,
                                    height: 190,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Ambient Glow Halo
                                        Container(
                                          width: 170,
                                          height: 170,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEAB308)
                                                    .withValues(alpha: 0.22),
                                                blurRadius: 40,
                                                spreadRadius: 8,
                                              ),
                                              BoxShadow(
                                                color: accent
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 60,
                                                spreadRadius: 15,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Custom Embroidery Hoop & Needle Stitch Painter
                                        CustomPaint(
                                          size: const Size(190, 190),
                                          painter: _EmbroideryHoopPainter(
                                            stitchProgress:
                                                _stitchProgress.value,
                                            goldColor: const Color(0xFFFBBF24),
                                            accentColor: accent,
                                          ),
                                        ),

                                        // Real Master 3D Embroidered Emblem (1024x1024 Ultra-HD)
                                        Container(
                                          width: 136,
                                          height: 136,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            border: Border.all(
                                              color: const Color(0xFFFBBF24)
                                                  .withValues(alpha: 0.75),
                                              width: 2.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.65),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(26),
                                            child: Image.asset(
                                              'assets/images/om_logo.jpg',
                                              width: 136,
                                              height: 136,
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Company Name & Typography with Slide-Up Transition
                              Transform.translate(
                                offset: Offset(0, _titleSlide.value),
                                child: Opacity(
                                  opacity: _titleFade.value.clamp(0.0, 1.0),
                                  child: Column(
                                    children: [
                                      // Brand Tag Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B)
                                              .withValues(alpha: 0.8),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFEAB308)
                                                .withValues(alpha: 0.4),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFBBF24),
                                              size: 14,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'PREMIUM EMBROIDERY FACTORY SUITE',
                                              style: TextStyle(
                                                color: Color(0xFFFDE047),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      // Main Company Title
                                      ShaderMask(
                                        shaderCallback: (bounds) {
                                          return const LinearGradient(
                                            colors: [
                                              Color(0xFFFFFFFF),
                                              Color(0xFFFEF08A),
                                              Color(0xFFFBBF24),
                                              Color(0xFFF59E0B),
                                            ],
                                            stops: [0.0, 0.35, 0.75, 1.0],
                                          ).createShader(bounds);
                                        },
                                        child: const Text(
                                          'OM MAVTAR GROUP',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 4.0,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Brand Pillars / Motto
                                      const Text(
                                        'Track  •  Calculate  •  Manage  •  Grow',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2.2,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // Khata categories badge
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildCategoryDot(
                                              'Beads', const Color(0xFF8B5CF6)),
                                          const SizedBox(width: 14),
                                          _buildCategoryDot('250 Area',
                                              const Color(0xFF3B82F6)),
                                          const SizedBox(width: 14),
                                          _buildCategoryDot('400 Area',
                                              const Color(0xFF10B981)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 38),

                              // Dynamic Progress Track & Status
                              Opacity(
                                opacity: _titleFade.value.clamp(0.0, 1.0),
                                child: Container(
                                  width: 380,
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A)
                                        .withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Progress Header (Status Text & Percentage)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _getStatusText(progress),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFFCBD5E1),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAB308)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFEAB308)
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              '$percent%',
                                              style: const TextStyle(
                                                color: Color(0xFFFDE047),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Sleek Multi-stop Gradient Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Stack(
                                          children: [
                                            // Background rail
                                            Container(
                                              height: 6,
                                              width: double.infinity,
                                              color: const Color(0xFF1E293B),
                                            ),
                                            // Animated progress fill
                                            FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor:
                                                  progress.clamp(0.01, 1.0),
                                              child: Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      accent,
                                                      const Color(0xFFF59E0B),
                                                      const Color(0xFFFDE047),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          const Color(0xFFFBBF24)
                                                              .withValues(
                                                                  alpha: 0.6),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 5. Bottom Skip & Shortcut Prompt
                    Positioned(
                      bottom: 18,
                      left: 20,
                      right: 20,
                      child: Opacity(
                        opacity: _titleFade.value.clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Offline & Desktop Status
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 13,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '100% Offline Database • macOS & Windows Desktop',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Skip action button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _navigateToMain,
                                borderRadius: BorderRadius.circular(8),
                                hoverColor: Colors.white.withValues(alpha: 0.08),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B)
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Press Enter or Click to Continue',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Color(0xFFCBD5E1),
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Custom Painter: Animated Embroidery Hoop Frame & Rotating Stitches
class _EmbroideryHoopPainter extends CustomPainter {
  final double stitchProgress;
  final Color goldColor;
  final Color accentColor;

  _EmbroideryHoopPainter({
    required this.stitchProgress,
    required this.goldColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Outer subtle metallic hoop
    final hoopPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius + 4, hoopPaint);

    // Glowing Golden Thread Arc (Stitched according to animation progress)
    final sweepAngle = 2 * math.pi * stitchProgress;
    final threadPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor,
          goldColor,
          const Color(0xFFFEF08A),
          goldColor,
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      threadPaint,
    );

    // Dashed Inner Embroidery Marks
    const int totalStitches = 28;
    final int visibleStitches = (totalStitches * stitchProgress).toInt();
    final stitchPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.6)
      ..strokeWidth = 1.4;

    for (int i = 0; i < visibleStitches; i++) {
      final angle = -math.pi / 2 + (i / totalStitches) * 2 * math.pi;
      final innerP = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final outerP = Offset(
        center.dx + (radius - 1) * math.cos(angle),
        center.dy + (radius - 1) * math.sin(angle),
      );
      canvas.drawLine(innerP, outerP, stitchPaint);
    }

    // Needle Tip Marker at current stitch progress
    if (stitchProgress > 0.02 && stitchProgress < 0.99) {
      final needleAngle = -math.pi / 2 + sweepAngle;
      final needlePos = Offset(
        center.dx + radius * math.cos(needleAngle),
        center.dy + radius * math.sin(needleAngle),
      );

      final needleGlow = Paint()
        ..color = const Color(0xFFFFFBEB)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      canvas.drawCircle(needlePos, 3.5, needleGlow);

      final needleCenter = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(needlePos, 1.8, needleCenter);
    }
  }

  @override
  bool shouldRepaint(covariant _EmbroideryHoopPainter oldDelegate) {
    return oldDelegate.stitchProgress != stitchProgress ||
        oldDelegate.goldColor != goldColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Custom Painter: Elegant Subtle Background Embroidery Grid
class _EmbroideryGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
