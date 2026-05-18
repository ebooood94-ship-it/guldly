import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/dashboard/home_screen.dart';
import '../../presentation/screens/buy_gold/buy_gold_screen.dart';
import '../../presentation/screens/buy_gold/buy_recurring_screen.dart';
import '../../presentation/screens/buy_gold/buy_onetime_screen.dart';
import '../../presentation/screens/wallet/wallet_screen.dart';
import '../../presentation/screens/wallet/add_funds_screen.dart';
import '../../presentation/screens/portfolio/portfolio_screen.dart';
import '../../presentation/screens/more/more_screen.dart';
import '../../presentation/screens/more/profile_screen.dart';
import '../../presentation/screens/more/security_screen.dart';
import '../../presentation/screens/more/notifications_screen.dart';
import '../../presentation/screens/more/calculator_screen.dart';
import '../../presentation/screens/sell/sell_screen.dart';
import '../../presentation/screens/gift/gift_screen.dart';
import '../../presentation/screens/delivery/delivery_screen.dart';
import '../../presentation/screens/transaction/receipt_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../providers/providers.dart';

// Route name constants
class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const buy = '/buy';
  static const buyRecurring = '/buy/recurring';
  static const buyOnetime = '/buy/onetime';
  static const wallet = '/wallet';
  static const addFunds = '/wallet/add-funds';
  static const portfolio = '/portfolio';
  static const more = '/more';
  static const profile = '/more/profile';
  static const security = '/more/security';
  static const notifications = '/more/notifications';
  static const calculator = '/more/calculator';
  static const sell = '/sell';
  static const gift = '/gift';
  static const delivery = '/delivery';
  static const receipt = '/receipt';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingAsync = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value?.session != null;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.splash;

      // Still loading auth or onboarding state
      if (authState.isLoading || onboardingAsync.isLoading) return null;

      // Not logged in → redirect to login (unless already on auth screen)
      if (!isLoggedIn && !isAuthRoute) return Routes.login;

      // Logged in + coming from auth → check onboarding
      if (isLoggedIn && isAuthRoute) {
        final onboardingDone = onboardingAsync.value ?? true;
        return onboardingDone ? Routes.home : Routes.onboarding;
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Shell (bottom nav) ─────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.wallet,
            builder: (_, __) => const WalletScreen(),
          ),
          GoRoute(
            path: Routes.portfolio,
            builder: (_, __) => const PortfolioScreen(),
          ),
          GoRoute(
            path: Routes.more,
            builder: (_, __) => const MoreScreen(),
          ),
        ],
      ),

      // ── Buy flow (no shell) ────────────────────────────────────────────────
      GoRoute(
        path: Routes.buy,
        builder: (_, __) => const BuyGoldScreen(),
      ),
      GoRoute(
        path: Routes.buyRecurring,
        builder: (_, __) => const BuyRecurringScreen(),
      ),
      GoRoute(
        path: Routes.buyOnetime,
        builder: (_, __) => const BuyOnetimeScreen(),
      ),

      // ── Wallet sub-screens ─────────────────────────────────────────────────
      GoRoute(
        path: Routes.addFunds,
        builder: (_, __) => const AddFundsScreen(),
      ),

      // ── More sub-screens ───────────────────────────────────────────────────
      GoRoute(
        path: Routes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.security,
        builder: (_, __) => const SecurityScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.calculator,
        builder: (_, __) => const CalculatorScreen(),
      ),

      // ── Quick action screens ───────────────────────────────────────────────
      GoRoute(
        path: Routes.sell,
        builder: (_, __) => const SellScreen(),
      ),
      GoRoute(
        path: Routes.gift,
        builder: (_, __) => const GiftScreen(),
      ),
      GoRoute(
        path: Routes.delivery,
        builder: (_, __) => const DeliveryScreen(),
      ),

      // ── Transaction receipt ────────────────────────────────────────────────
      GoRoute(
        path: Routes.receipt,
        builder: (_, state) {
          // Mobile path: data passed via extra
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null && extra.isNotEmpty) {
            return ReceiptScreen(data: extra);
          }
          // Web path: Stripe Checkout redirects back with query params
          final q = state.uri.queryParameters;
          return ReceiptScreen(data: {
            'type': q['type'] ?? 'Transaction',
            'amountSek': double.tryParse(q['amount'] ?? '0') ?? 0.0,
            'goldGrams': double.tryParse(q['grams'] ?? ''),
            'goldPricePerGramSek': double.tryParse(q['price'] ?? ''),
            'paymentMethod': q['paymentMethod'] ?? 'card',
            'frequency': q['frequency'],
            'addFunds': q['addFunds'],
            'fromStripeRedirect': q['success'] == 'true',
          });
        },
      ),
    ],
  );
});
