import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/format.dart';
import '../../core/theme.dart';
import '../market/widgets.dart';
import 'wallet_providers.dart';

/// سجل المعاملات / Transactions history
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _f = 'all'; // all | demo_deposit | demo_bonus
  static const _filters = {'all': 'الكل', 'demo_deposit': 'شحن', 'demo_bonus': 'هدايا'};

  @override
  Widget build(BuildContext context) {
    final tx = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المعاملات')),
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final e in _filters.entries)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _f == e.key,
                  selectedColor: C.green,
                  labelStyle: TextStyle(color: _f == e.key ? C.navy : Colors.white),
                  onSelected: (_) => setState(() => _f = e.key),
                ),
              ),
          ]),
        ),
        Expanded(
          child: tx.when<Widget>(
            loading: () => const SingleChildScrollView(padding: EdgeInsets.all(16), child: SkeletonList(count: 6)),
            error: (_, __) => ErrorView(message: 'تعذّر تحميل المعاملات', onRetry: () => ref.invalidate(transactionsProvider)),
            data: (rows) {
              final list = rows.where((r) => _f == 'all' || r['type'] == _f).toList();
              if (list.isEmpty) return const EmptyView(message: 'لا توجد معاملات بعد', icon: Icons.receipt_long);
              return RefreshIndicator(
                color: C.green,
                onRefresh: () async => ref.invalidate(transactionsProvider),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  for (final r in list) _tile(r),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _tile(Map<String, dynamic> r) {
    final bonus = r['type'] == 'demo_bonus';
    final date = DateTime.tryParse('${r['created_at']}')?.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: C.surface,
          child: Icon(bonus ? Icons.card_giftcard : Icons.add_card, color: bonus ? C.gold : C.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r['note'] ?? (bonus ? 'هدية' : 'شحن تجريبي')}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (date != null)
              Text(DateFormat('yyyy-MM-dd HH:mm', 'en').format(date), style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        Text('+\$${fmtMoney(((r['amount'] as num?) ?? 0).toDouble())}',
            textDirection: TextDirection.ltr, style: const TextStyle(color: C.green, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
