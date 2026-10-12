import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/format.dart';
import '../../core/theme.dart';
import '../market/market_providers.dart';
import '../market/widgets.dart';
import 'portfolio_models.dart';
import 'portfolio_providers.dart';

const _palette = [C.green, C.gold, Color(0xFF4DA3FF), Color(0xFFB57BFF), Color(0xFFFF8A5B), Color(0xFF2EE6D6), C.red];

/// المحفظة / Portfolio
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});
  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _showTrades = false;

  Future<void> _refresh() async {
    ref.invalidate(holdingsProvider);
    ref.invalidate(tradesProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(marketProvider); // أسعار حية / live prices
    final holdings = ref.watch(holdingsProvider);
    final trades = ref.watch(tradesProvider);
    final bal = ((ref.watch(profileProvider).valueOrNull?['demo_balance'] as num?) ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('المحفظة')),
      body: RefreshIndicator(
        color: C.green,
        onRefresh: _refresh,
        child: holdings.when<Widget>(
          loading: () => ListView(padding: const EdgeInsets.all(16), children: const [SkeletonList(count: 5)]),
          error: (_, __) => ListView(children: [ErrorView(message: 'تعذّر تحميل المحفظة', onRetry: _refresh)]),
          data: (hs) {
            final views = [
              for (final h in hs) HoldingView(h, ref.watch(stockProvider(h.symbol))?.price ?? h.avgPrice)
            ];
            final invested = views.fold<double>(0, (a, v) => a + v.value);
            final unrealized = views.fold<double>(0, (a, v) => a + v.pnl);
            final realized = realizedPnl(trades.valueOrNull ?? const []);
            final totalPnl = unrealized + realized;
            final equity = bal + invested;
            final pnlCol = totalPnl >= 0 ? C.green : C.red;

            return ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFF1E2A4A), Color(0xFF0E5E4E)]),
                  border: Border.all(color: C.gold.withValues(alpha: .4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('إجمالي قيمة المحفظة (تجريبي)', style: TextStyle(color: Colors.white70)),
                  Text('\$${fmtMoney(equity)}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: C.gold)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _kv('نقد', '\$${fmtMoney(bal)}'),
                    _kv('مستثمر', '\$${fmtMoney(invested)}'),
                    _kv('الربح/الخسارة', '${totalPnl >= 0 ? '+' : '-'}\$${fmtMoney(totalPnl.abs())}', pnlCol),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              if (views.isNotEmpty) _allocation(views, bal),
              const SizedBox(height: 12),
              Row(children: [
                ChoiceChip(
                  label: const Text('الحيازات'),
                  selected: !_showTrades,
                  selectedColor: C.green,
                  labelStyle: TextStyle(color: !_showTrades ? C.navy : Colors.white),
                  onSelected: (_) => setState(() => _showTrades = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('سجل الصفقات'),
                  selected: _showTrades,
                  selectedColor: C.green,
                  labelStyle: TextStyle(color: _showTrades ? C.navy : Colors.white),
                  onSelected: (_) => setState(() => _showTrades = true),
                ),
              ]),
              const SizedBox(height: 12),
              if (!_showTrades) ..._holdingsList(views) else ..._tradesList(trades),
              const Disclaimer(),
            ]);
          },
        ),
      ),
    );
  }

  Widget _kv(String l, String v, [Color? c]) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
          Text(l, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      );

  Widget _allocation(List<HoldingView> views, double cash) {
    final items = [
      for (var i = 0; i < views.length; i++) (views[i].h.symbol, views[i].value, _palette[i % _palette.length]),
      if (cash > 0) ('نقد', cash, Colors.white38),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        SizedBox(
          width: 130, height: 130,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final it in items)
                  PieChartSectionData(value: it.$2, color: it.$3, radius: 22, showTitle: false),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(children: [
            for (final it in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Icon(Icons.circle, size: 10, color: it.$3),
                  const SizedBox(width: 8),
                  Text(it.$1, style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text('\$${fmtMoney(it.$2)}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _holdingsList(List<HoldingView> views) {
    if (views.isEmpty) {
      return const [EmptyView(message: 'لا توجد حيازات بعد — اشترِ من شاشة السوق', icon: Icons.pie_chart_outline)];
    }
    return [
      for (final v in views)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/stock/${v.h.symbol}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.h.symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${v.h.qty.toStringAsFixed(0)} سهم • متوسط \$${fmtMoney(v.h.avgPrice)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('\$${fmtMoney(v.value)}', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${v.pnl >= 0 ? '+' : '-'}\$${fmtMoney(v.pnl.abs())} (${fmtPct(v.pnlPct)})',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: v.pnl >= 0 ? C.green : C.red, fontSize: 12)),
                  ]),
                ]),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _tradesList(AsyncValue<List<Map<String, dynamic>>> trades) => [
        trades.when<Widget>(
          loading: () => const SkeletonList(count: 4),
          error: (_, __) => ErrorView(message: 'تعذّر تحميل الصفقات', onRetry: () => ref.invalidate(tradesProvider)),
          data: (rows) {
            if (rows.isEmpty) return const EmptyView(message: 'لا توجد صفقات بعد', icon: Icons.receipt_long);
            return Column(children: [
              for (final t in rows) _tradeTile(t),
            ]);
          },
        ),
      ];

  Widget _tradeTile(Map<String, dynamic> t) {
    final buy = t['side'] == 'buy';
    final pnl = ((t['pnl'] as num?) ?? 0).toDouble();
    final date = DateTime.tryParse('${t['created_at']}')?.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: (buy ? C.green : C.red).withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
          child: Text(buy ? 'شراء' : 'بيع', style: TextStyle(color: buy ? C.green : C.red, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t['symbol']} × ${((t['qty'] as num?) ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (date != null)
              Text(DateFormat('yyyy-MM-dd HH:mm', 'en').format(date), style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${fmtMoney(((t['price'] as num?) ?? 0).toDouble())}', textDirection: TextDirection.ltr),
          if (!buy)
            Text('${pnl >= 0 ? '+' : '-'}\$${fmtMoney(pnl.abs())}',
                textDirection: TextDirection.ltr, style: TextStyle(color: pnl >= 0 ? C.green : C.red, fontSize: 12)),
        ]),
      ]),
    );
  }
}
