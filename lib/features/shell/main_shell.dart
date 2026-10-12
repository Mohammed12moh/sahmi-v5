import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../game/game_defs.dart';
import '../game/game_providers.dart';

/// الهيكل مع شريط التنقل السفلي + تسجيل الدخول اليومي (Streak)
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _paths = ['/home', '/market', '/portfolio', '/profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // يعمل مرة واحدة عند فتح التطبيق / runs once on app open
    ref.watch(dailyCheckInProvider);
    ref.listen(dailyCheckInProvider, (_, next) {
      next.whenData((r) {
        if (r.newBadges.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(badgeToast(r.newBadges))));
        }
      });
    });

    final loc = GoRouterState.of(context).matchedLocation;
    final i = _paths.indexWhere(loc.startsWith);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: i < 0 ? 0 : i,
        onDestinationSelected: (x) => context.go(_paths[x]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), selectedIcon: Icon(Icons.candlestick_chart), label: 'السوق'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'المحفظة'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
