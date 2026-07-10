import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppConstants.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppConstants.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.splashBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding,
            ),
            child: Column(
              children: [
                const Spacer(),
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppConstants.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'guldly',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.gold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      'Äkta guld. Enkelt sparande.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: AppConstants.subtitle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        height: AppConstants.buttonHeight,
                        decoration: BoxDecoration(
                          color: AppConstants.gold,
                          borderRadius: BorderRadius.circular(
                            AppConstants.buttonRadius,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'KOM IGÅNG',
                          style: GoogleFonts.inter(
                            color: AppConstants.onGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
