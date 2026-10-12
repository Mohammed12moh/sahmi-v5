import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import 'models.dart';

class SignalChip extends StatelessWidget {
  final SignalAction action;
  const SignalChip(this.action, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: action.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
        child: Text('${action.emoji} ${action.label}',
            style: TextStyle(color: action.color, fontWeight: FontWeight.w700, fontSize: 11)),
      );
}

class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const Sparkline(this.data, this.color, {super.key});
  @override
  Widget build(BuildContext context) => LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
              isCurved: true, color: color, barWidth: 2, dotData: const FlDotData(show: false),
            ),
          ],
        ),
        duration: Duration.zero,
      );
}

class StockTile extends StatelessWidget {
  final Stock stock;
  final Signal? signal;
  final VoidCallback onTap;
  const StockTile({super.key, required this.stock, required this.signal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final col = stock.changePct >= 0 ? C.green : C.red;
    final spark = stock.closes.sublist(stock.closes.length - 30);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: C.surface,
                child: Text(stock.symbol.substring(0, 1),
                    style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stock.nameAr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(stock.symbol, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 6),
                    if (signal != null) SignalChip(signal!.action),
                  ]),
                ]),
              ),
              SizedBox(width: 56, height: 30, child: Sparkline(spark, col)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${fmtMoney(stock.price)}',
                    textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(fmtPct(stock.changePct),
                    textDirection: TextDirection.ltr, style: TextStyle(color: col, fontSize: 12)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// هيكل تحميل / shimmer skeleton
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < count; i++)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white10),
      ]);
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: C.red),
          const SizedBox(height: 12),
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ]),
      );
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, required this.message, this.icon = Icons.search_off});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(icon, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white60)),
        ]),
      );
}

const disclaimerText =
    'بيانات محاكاة لأغراض تعليمية، وليست أسعاراً حقيقية أو نصيحة استثمارية.';

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(disclaimerText,
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
      );
}
