import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(Routes.wallet)) return 2;
    if (location.startsWith(Routes.portfolio)) return 3;
    if (location.startsWith(Routes.more)) return 4;
    return 0; // home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.push(Routes.buy);
        break; // Buy is outside shell
      case 2:
        context.go(Routes.wallet);
        break;
      case 3:
        context.go(Routes.portfolio);
        break;
      case 4:
        context.go(Routes.more);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(firstLoginSetupProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _GuldlyBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _GuldlyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GuldlyBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.shopping_bag_outlined, label: 'Buy'),
      const _NavItem(
          icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
      const _NavItem(icon: Icons.pie_chart_outline_rounded, label: 'Portfolio'),
      const _NavItem(icon: Icons.menu_rounded, label: 'More'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((e) {
            final selected = e.key == currentIndex;
            return GestureDetector(
              onTap: () => onTap(e.key),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.value.icon,
                      color:
                          selected ? AppConstants.gold : AppConstants.subtitle,
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        color: selected
                            ? AppConstants.gold
                            : AppConstants.subtitle,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
