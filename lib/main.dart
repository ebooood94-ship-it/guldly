import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MaterialApp.router(
      title: 'Guldly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
