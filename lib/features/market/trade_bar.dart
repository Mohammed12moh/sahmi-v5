// TradeBar — شريط الشراء/البيع أسفل شاشة تفاصيل السهم.
// يأخذ الكمية (أسهم كاملة) ويستدعي onBuy/onSell، والتنفيذ الفعلي بورقة التأكيد (TradeSheet).
// Quick buy/sell bar: quantity input, calls onBuy/onSell; execution happens in the confirm sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/format.dart';
import '../../core/theme.dart';

class TradeBar extends StatefulWidget {
  final String symbol;
  final double price;
  final ValueChanged<int> onBuy;
  final ValueChanged<int> onSell;

  const TradeBar({
    super.key,
    required this.symbol,
    required this.price,
    required this.onBuy,
    required this.onSell,
  });

  @override
  State<TradeBar> createState() => _TradeBarState();
}

class _TradeBarState extends State<TradeBar> {
  final _qty = TextEditingController(text: '1');

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  int get _q => int.tryParse(_qty.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final ok = q > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: C.navy,
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('${widget.symbol} • \$${fmtMoney(widget.price)}',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Text(ok ? 'الإجمالي ≈ \$${fmtMoney(widget.price * q)}' : 'أدخل الكمية',
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: C.gold, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'الكمية',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.green,
                  foregroundColor: C.navy,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: ok ? () => widget.onBuy(q) : null,
                child: const Text('شراء', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: ok ? () => widget.onSell(q) : null,
                child: const Text('بيع', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
