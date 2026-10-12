import 'package:intl/intl.dart' show NumberFormat;

final _money = NumberFormat('#,##0.00', 'en');
String fmtMoney(double v) => _money.format(v);
String fmtPct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
