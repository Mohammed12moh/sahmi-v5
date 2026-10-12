import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';
import '../market/market_providers.dart';
import '../market/models.dart';
import '../market/widgets.dart';

/// الشاشة الرئيسية / Home
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final signals = ref.watch(signalsProvider);
    final profile = ref.watch(profileProvider);
    final watch = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سهمي', style: TextStyle(color: C.gold, fontWeight: FontWeight.w800)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: C.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
            child: const Text('تجريبي', style: TextStyle(color: C.gold, fontSize: 12)),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(authRepoProvider).signOut()),
        ],
      ),
      body: RefreshIndicator(
        color: C.green,
        onRefresh: () async => ref.invalidate(marketProvider),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _BalanceCard(profile: profile, watchCount: watch.length),
          const SizedBox(height: 16),
          const _QuickActions(),
          const SizedBox(height: 20),
          ...market.when<List<Widget>>(
            loading: () => [const SkeletonList(count: 4)],
            error: (_, __) => [ErrorView(message: 'تعذّر تحميل السوق', onRetry: () => ref.invalidate(marketProvider))],
            data: (stocks) => _sections(context, stocks, signals, watch),
          ),
          const Disclaimer(),
        ]),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, List<Stock> stocks, Map<String, Signal> signals, Set<String> watch) {
    final byChange = [...stocks]..sort((a, b) => b.changePct.compareTo(a.changePct));
    final gainers = byChange.take(3).toList();
    final losers = byChange.reversed.take(3).toList();
    final top = [...stocks]..sort((a, b) => (signals[b.symbol]?.score ?? 0).compareTo(signals[a.symbol]?.score ?? 0));
    final watched = stocks.where((s) => watch.contains(s.symbol)).toList();

    Widget title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)));
    Widget row(List<Stock> l) => SizedBox(
        height: 84,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final s in l) _MiniCard(stock: s, onTap: () => context.push('/stock/${s.symbol}')),
        ]));

    return [
      title('قائمة المراقبة'),
      if (watched.isEmpty)
        const EmptyView(message: 'أضف أسهماً للمراقبة من شاشة السوق', icon: Icons.star_border)
      else
        row(watched),
      const SizedBox(height: 20),
      title('الأعلى ارتفاعاً'),
      row(gainers),
      const SizedBox(height: 20),
      title('الأكثر هبوطاً'),
      row(losers),
      const SizedBox(height: 20),
      title('أقوى الإشارات'),
      for (final s in top.take(4))
        StockTile(stock: s, signal: signals[s.symbol], onTap: () => context.push('/stock/${s.symbol}')),
    ];
  }
}

class _BalanceCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> profile;
  final int watchCount;
  const _BalanceCard({required this.profile, required this.watchCount});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [Color(0xFF1E2A4A), Color(0xFF0E5E4E)]),
          border: Border.all(color: C.gold.withValues(alpha: .4)),
        ),
        child: profile.when<Widget>(
          loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: C.gold))),
          error: (_, __) => const SizedBox(height: 90, child: Center(child: Text('تعذّر تحميل الحساب'))),
          data: (p) {
            final bal = ((p?['demo_balance'] as num?) ?? 0).toDouble();
            final xp = (p?['xp'] as num?)?.toInt() ?? 0;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('الرصيد التجريبي', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('\$${fmtMoney(bal)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: C.gold)),
              const SizedBox(height: 14),
              Row(children: [
                _Stat('XP', '$xp'),
                _Stat('المراقبة', '$watchCount'),
                _Stat('🔥 الأيام المتتالية', '${(p?['streak'] as num?)?.toInt() ?? 0}'),
              ]),
            ]);
          },
        ),
      );
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    Widget a(IconData i, String l, VoidCallback f) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: f,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Icon(i, color: C.green),
                const SizedBox(height: 6),
                Text(l, style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        );
    return Row(children: [
      a(Icons.add_card, 'شحن تجريبي', () => context.push('/deposit')),
      const SizedBox(width: 8),
      a(Icons.card_giftcard, 'دعوة', () => context.push('/referral')),
      const SizedBox(width: 8),
      a(Icons.receipt_long, 'المعاملات', () => context.push('/transactions')),
      const SizedBox(width: 8),
      a(Icons.candlestick_chart, 'السوق', () => context.go('/market')),
    ]);
  }
}

class _MiniCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;
  const _MiniCard({required this.stock, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final col = stock.changePct >= 0 ? C.green : C.red;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Material(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 128,
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('\$${fmtMoney(stock.price)}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13)),
              Text(fmtPct(stock.changePct), textDirection: TextDirection.ltr, style: TextStyle(color: col, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
