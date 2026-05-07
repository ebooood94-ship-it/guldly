import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guldly/core/constants/app_constants.dart';
import '../dashboard/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _iconController;
  late final AnimationController _btnController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _iconController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _btnController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _iconController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.splashBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 45,
                child: FadeTransition(
                  opacity: _logoController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.15),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _logoController, curve: Curves.easeOut)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'g',
                          style: TextStyle(
                            fontSize: 180,
                            fontWeight: FontWeight.w900,
                            color: AppConstants.gold,
                            height: 1.0,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'guldly',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 35,
                child: FadeTransition(
                  opacity: _iconController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _iconController, curve: Curves.easeOut)),
                    child: const Center(
                      child: GoldBarsIcon(size: 90),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 20,
                child: FadeTransition(
                  opacity: _btnController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: _btnController, curve: Curves.easeOut)),
                    child: Align(
                      alignment: Alignment.center,
                      child: GetStartedButton(onPressed: _onGetStarted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gold bars icon widget
class GoldBarsIcon extends StatelessWidget {
  final double size;
  const GoldBarsIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: GoldBarsPainter()),
    );
  }
}

class GoldBarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = AppConstants.gold;
    final goldDark = Paint()..color = AppConstants.goldDark;
    final goldLight = Paint()..color = const Color(0xFFE8C14A);
    final w = size.width;
    final h = size.height;

    _drawBar(canvas, Rect.fromLTWH(w * 0.0, h * 0.45, w * 0.42, h * 0.30), gold,
        goldDark, goldLight);
    _drawBar(canvas, Rect.fromLTWH(w * 0.32, h * 0.45, w * 0.42, h * 0.30),
        gold, goldDark, goldLight);
    _drawBar(canvas, Rect.fromLTWH(w * 0.16, h * 0.60, w * 0.42, h * 0.30),
        gold, goldDark, goldLight);
  }

  void _drawBar(Canvas canvas, Rect rect, Paint fill, Paint dark, Paint light) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rr, fill);
    final highlight =
        Rect.fromLTWH(rect.left + 4, rect.top + 2, rect.width - 8, 5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(highlight, const Radius.circular(2)), light);
    final shadow =
        Rect.fromLTWH(rect.left + 4, rect.bottom - 7, rect.width - 8, 5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(shadow, const Radius.circular(2)), dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class GetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;
  const GetStartedButton({super.key, required this.onPressed});

  @override
  State<GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: _pressed ? AppConstants.goldDark : AppConstants.gold,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppConstants.gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Get started',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
