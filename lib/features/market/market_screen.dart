import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../chat/chat_room.dart';
import 'market_providers.dart';
import 'models.dart';
import 'widgets.dart';

enum _F { all, buy, hold, sell, watch }

const _labels = {
  _F.all: 'الكل', _F.buy: 'شراء', _F.hold: 'انتظار', _F.sell: 'بيع', _F.watch: 'مراقبتي',
};

/// شاشة السوق: بحث + فلترة / Market: search + filters
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});
  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _q = '';
  _F _f = _F.all;

  bool _match(Stock s, Signal? sig, Set<String> watch) {
    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty &&
        !(s.symbol.toLowerCase().contains(q) || s.nameAr.contains(q) || s.sector.contains(q))) {
      return false;
    }
    final a = sig?.action;
    switch (_f) {
      case _F.all: return true;
      case _F.buy: return a == SignalAction.buy || a == SignalAction.strongBuy;
      case _F.hold: return a == SignalAction.hold;
      case _F.sell: return a == SignalAction.sell || a == SignalAction.strongSell;
      case _F.watch: return watch.contains(s.symbol);
    }
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final signals = ref.watch(signalsProvider);
    final watch = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('السوق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'غرف الدردشة',
            onPressed: () => showRoomsDialog(context),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(hintText: 'ابحث بالاسم أو الرمز', prefixIcon: Icon(Icons.search)),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final f in _F.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_labels[f]!),
                    selected: _f == f,
                    selectedColor: C.green,
                    labelStyle: TextStyle(color: _f == f ? C.navy : Colors.white),
                    onSelected: (_) => setState(() => _f = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: market.when<Widget>(
            loading: () => const SingleChildScrollView(padding: EdgeInsets.all(16), child: SkeletonList(count: 7)),
            error: (_, __) => ErrorView(message: 'تعذّر تحميل السوق', onRetry: () => ref.invalidate(marketProvider)),
            data: (stocks) {
              final list = stocks.where((s) => _match(s, signals[s.symbol], watch)).toList();
              if (list.isEmpty) return const EmptyView(message: 'لا نتائج مطابقة');
              return ListView(padding: const EdgeInsets.all(16), children: [
                for (final s in list)
                  StockTile(stock: s, signal: signals[s.symbol], onTap: () => context.push('/stock/${s.symbol}')),
                const Disclaimer(),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
