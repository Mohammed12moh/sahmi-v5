/// حيازة / Holding
class Holding {
  final String symbol;
  final double qty, avgPrice;
  const Holding(this.symbol, this.qty, this.avgPrice);
  factory Holding.fromRow(Map<String, dynamic> r) => Holding(
      r['symbol'] as String, (r['qty'] as num).toDouble(), (r['avg_price'] as num).toDouble());
}

class HoldingView {
  final Holding h;
  final double price;
  const HoldingView(this.h, this.price);
  double get value => h.qty * price;
  double get cost => h.qty * h.avgPrice;
  double get pnl => value - cost;
  double get pnlPct => cost == 0 ? 0 : pnl / cost * 100;
}

/// الربح المحقق من صفقات البيع / realized P&L
double realizedPnl(List<Map<String, dynamic>> trades) => trades
    .where((t) => t['side'] == 'sell')
    .fold(0.0, (a, t) => a + ((t['pnl'] as num?) ?? 0).toDouble());

String tradeErrorMessage(String m) {
  if (m.contains('insufficient balance')) return 'رصيدك التجريبي غير كافٍ';
  if (m.contains('insufficient holdings')) return 'لا تملك هذه الكمية للبيع';
  if (m.contains('invalid')) return 'بيانات غير صالحة';
  return 'تعذّرت العملية، حاول مرة أخرى';
}
