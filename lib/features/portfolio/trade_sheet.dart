import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../game/game_defs.dart';
import '../game/game_providers.dart';
import '../market/market_providers.dart';
import 'portfolio_models.dart';
import 'portfolio_providers.dart';

Future<void> showTradeSheet(BuildContext context, String symbol, String side, {int? initialQty}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => TradeSheet(symbol: symbol, side: side, initialQty: initialQty),
    );

/// ورقة التداول التجريبي / demo trade sheet
class TradeSheet extends ConsumerStatefulWidget {
  final String symbol, side;
  final int? initialQty;
  const TradeSheet({super.key, required this.symbol, required this.side, this.initialQty});
  @override
  ConsumerState<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<TradeSheet> {
  late final TextEditingController _qty = TextEditingController(text: '${widget.initialQty ?? 1}');
  bool _loading = false;
  String? _error;

  bool get _buy => widget.side == 'buy';
  int? get _q => int.tryParse(_qty.text.trim());

  @override
  void dispose() { _qty.dispose(); super.dispose(); }

  Future<void> _go() async {
    final q = _q;
    final price = ref.read(stockProvider(widget.symbol))?.price;
    if (q == null || q <= 0) { setState(() => _error = 'أدخل كمية صحيحة'); return; }
    if (price == null) { setState(() => _error = 'السعر غير متاح الآن'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ref.read(tradeRepoProvider).execute(widget.symbol, widget.side, q, price);
      Haptics.heavy();
      ref.invalidate(holdingsProvider);
      ref.invalidate(tradesProvider);
      ref.invalidate(challengeProgressProvider);
      ref.invalidate(myBadgesProvider);
      if (!mounted) return;
      final m = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      final msg = _buy
          ? 'تم شراء $q ${widget.symbol} بسعر \$${fmtMoney(price)}'
          : 'تم بيع $q ${widget.symbol} • ${r.pnl >= 0 ? 'ربح' : 'خسارة'} \$${fmtMoney(r.pnl.abs())}';
      m.showSnackBar(SnackBar(content: Text(msg)));
      if (r.newBadges.isNotEmpty) m.showSnackBar(SnackBar(content: Text(badgeToast(r.newBadges))));
    } on PostgrestException catch (e) {
      setState(() => _error = tradeErrorMessage(e.message));
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = ref.watch(stockProvider(widget.symbol))?.price;
    final bal = ((ref.watch(profileProvider).valueOrNull?['demo_balance'] as num?) ?? 0).toDouble();
    final held = ref.watch(holdingsProvider).valueOrNull
            ?.where((h) => h.symbol == widget.symbol).fold<double>(0, (a, h) => a + h.qty) ?? 0;
    final q = _q ?? 0;
    final total = (price ?? 0.0) * q;
    final max = price == null || price == 0 ? 0 : (_buy ? (bal / price).floor() : held.floor());
    final col = _buy ? C.green : C.red;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_buy ? 'شراء' : 'بيع'} ${widget.symbol}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: col)),
        const SizedBox(height: 4),
        Text('السعر الحالي: ${price == null ? '—' : '\$${fmtMoney(price)}'}',
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 14),
        TextField(
          controller: _qty,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: 'الكمية (أسهم)',
            suffix: TextButton(onPressed: () => setState(() => _qty.text = '${max < 1 ? 1 : max}'), child: const Text('الأقصى')),
          ),
        ),
        const SizedBox(height: 12),
        _row('الإجمالي', '\$${fmtMoney(total)}'),
        _row(_buy ? 'رصيدك التجريبي' : 'تملك', _buy ? '\$${fmtMoney(bal)}' : '${held.toStringAsFixed(0)} سهم'),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: C.red))),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _go,
          style: ElevatedButton.styleFrom(backgroundColor: col, foregroundColor: _buy ? C.navy : Colors.white),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(_buy ? 'تأكيد الشراء' : 'تأكيد البيع'),
        ),
        const SizedBox(height: 8),
        const Text('تداول تجريبي برصيد افتراضي.', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(l, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(v, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}
