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
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.home);
      case 1:
        context.push(Routes.buy);
      case 2:
        context.go(Routes.wallet);
      case 3:
        context.go(Routes.portfolio);
      case 4:
        context.go(Routes.more);
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
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'HEM'),
      _NavItem(icon: Icons.shopping_bag_outlined, label: 'KÖP'),
      _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'PLÅNBOK'),
      _NavItem(icon: Icons.pie_chart_outline_rounded, label: 'PORTFÖLJ'),
      _NavItem(icon: Icons.menu_rounded, label: 'MER'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.card,
        border: Border(
          top: BorderSide(color: AppConstants.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        e.value.icon,
                        color: selected ? AppConstants.gold : AppConstants.subtitle,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.value.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: selected ? AppConstants.gold : AppConstants.subtitle,
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
