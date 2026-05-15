import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/providers/providers.dart';
import 'core/router/router.dart';
import 'core/services/stripe_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    StripeService.initialize(
        'pk_test_51TUpnp5YGUKTIsY7CugQwPteWhQm1sFJJLnmS0IzWAYt7BrNqdOxQ0FaMWT6rkmOgtbDHpyvXs9I1lUlIXI0ceQh00FT57ufJh');
  } catch (_) {
    // Stripe init is deferred on web — key is set lazily before first payment
  }

  await Supabase.initialize(
    url: 'https://njcwivpthvrpqocibrpb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qY3dpdnB0aHZycHFvY2licnBiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzODI5MDUsImV4cCI6MjA4OTk1ODkwNX0.fR1b4fnlkTjjBnAeGEVzb3C2ygj6n633LO1gJJn2BSs',
  );

  runApp(const ProviderScope(child: GuldlyApp()));
}

class GuldlyApp extends ConsumerWidget {
  const GuldlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Guldly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
