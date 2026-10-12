import 'dart:math' show min, max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import '../portfolio/trade_sheet.dart';
import 'trade_bar.dart';
import 'market_providers.dart';
import 'models.dart';
import 'widgets.dart';

/// تفاصيل السهم والإشارة / Stock + signal details
class StockDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});
  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  int _range = 90;

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final stock = ref.watch(stockProvider(widget.symbol));
    final signal = ref.watch(signalsProvider)[widget.symbol];
    final watched = ref.watch(watchlistProvider).contains(widget.symbol);

    return Scaffold(
      bottomNavigationBar: stock == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: TradeBar(
                symbol: stock.symbol,
                price: stock.price,
                onBuy: (q) => showTradeSheet(context, stock.symbol, 'buy', initialQty: q),
                onSell: (q) => showTradeSheet(context, stock.symbol, 'sell', initialQty: q),
              ),
            ),
      appBar: AppBar(
        title: Text(stock?.nameAr ?? widget.symbol),
        actions: [
          IconButton(
            icon: Icon(watched ? Icons.star : Icons.star_border, color: C.gold),
            onPressed: () {
              Haptics.light();
              ref.read(watchlistProvider.notifier).toggle(widget.symbol);
            },
          ),
        ],
      ),
      body: market.isLoading && stock == null
          ? const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3))
          : market.hasError && stock == null
              ? ErrorView(message: 'تعذّر تحميل البيانات', onRetry: () => ref.invalidate(marketProvider))
              : stock == null
                  ? const EmptyView(message: 'السهم غير موجود')
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      _header(stock),
                      const SizedBox(height: 12),
                      _chart(stock),
                      _rangeChips(),
                      const SizedBox(height: 16),
                      if (signal != null) ..._signalSection(stock, signal),
                      const Disclaimer(),
                    ]),
    );
  }

  Widget _header(Stock s) {
    final col = s.changePct >= 0 ? C.green : C.red;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('\$${fmtMoney(s.price)}',
          textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
      const SizedBox(width: 12),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(fmtPct(s.changePct), textDirection: TextDirection.ltr, style: TextStyle(color: col, fontWeight: FontWeight.w700)),
      ),
      const Spacer(),
      Text(s.symbol, style: const TextStyle(color: Colors.white54)),
    ]);
  }

  Widget _chart(Stock s) {
    final n = min(_range, s.closes.length);
    final data = s.closes.sublist(s.closes.length - n);
    final col = data.last >= data.first ? C.green : C.red;
    final lo = data.reduce(min), hi = data.reduce(max);
    final pad = (hi - lo) * .1;
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
              isCurved: true,
              curveSmoothness: .2,
              color: col,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [col.withValues(alpha: .3), col.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  Widget _rangeChips() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final r in const [(30, 'شهر'), (90, '3 أشهر'), (260, 'سنة')])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(r.$2),
              selected: _range == r.$1,
              selectedColor: C.green,
              labelStyle: TextStyle(color: _range == r.$1 ? C.navy : Colors.white),
              onSelected: (_) => setState(() => _range = r.$1),
            ),
          ),
      ]);

  List<Widget> _signalSection(Stock s, Signal g) {
    final col = g.action.color;
    Widget metric(String l, String v, [Color? c]) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(v, textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
              const SizedBox(height: 4),
              Text(l, style: const TextStyle(color: Colors.white60, fontSize: 11), textAlign: TextAlign.center),
            ]),
          ),
        );

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: col.withValues(alpha: .5)),
        ),
        child: Row(children: [
          SizedBox(
            width: 92, height: 92,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                    value: g.score / 100, strokeWidth: 9, color: col, backgroundColor: Colors.white12),
              ),
              Text('${g.score.round()}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: col)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الإشارة', style: TextStyle(color: Colors.white60)),
              Text('${g.action.emoji} ${g.action.label}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: col)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Row(children: [
        metric('الثقة', '${g.confidence.round()}%'),
        metric('وقف الخسارة', '\$${fmtMoney(g.stopLoss)}', C.red),
        metric('هدف الربح', '\$${fmtMoney(g.takeProfit)}', C.green),
        metric('مخاطرة/مكافأة', '1:${g.riskReward.toStringAsFixed(1)}'),
      ]),
      const SizedBox(height: 16),
      const Text('أسباب الإشارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      for (final r in g.reasons)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: C.gold)),
            const SizedBox(width: 8),
            Expanded(child: Text(r, style: const TextStyle(height: 1.5))),
          ]),
        ),
      const SizedBox(height: 12),
      const Text('تفصيل المؤشرات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      for (final c in g.components)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 80, child: Text('${c.name} ${(c.weight * 100).round()}%', style: const TextStyle(fontSize: 12))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: c.score / 100, minHeight: 8, backgroundColor: Colors.white12,
                  color: actionForScore(c.score).color,
                ),
              ),
            ),
            SizedBox(width: 36, child: Text('${c.score.round()}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 12))),
          ]),
        ),
    ];
  }
}
