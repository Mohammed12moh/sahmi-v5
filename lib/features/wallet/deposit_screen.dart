import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/format.dart';
import '../../core/support.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';
import 'deposit_rules.dart';
import 'wallet_providers.dart';

/// شحن الرصيد التجريبي / Demo balance top-up
class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});
  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  double _preset = 50;
  final _custom = TextEditingController();
  bool _loading = false;
  String? _error;

  double? get _amount => _custom.text.trim().isNotEmpty ? double.tryParse(_custom.text.trim()) : _preset;

  Future<void> _submit() async {
    final a = _amount;
    final err = validateDepositAmount(a);
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(paymentProvider).deposit(amount: a!);
      Haptics.heavy();
      if (!mounted) return;
      await _celebrate(a + bonusFor(a));
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message.contains('daily')
          ? 'وصلت الحد اليومي للشحن التجريبي'
          : 'تعذّر تنفيذ العملية');
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _celebrate(double total) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: C.card,
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: C.green, size: 80)
                .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text('تمت إضافة \$${fmtMoney(total)} إلى رصيدك التجريبي', textAlign: TextAlign.center),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تم'))],
        ),
      );

  @override
  void dispose() { _custom.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a = _amount;
    final valid = validateDepositAmount(a) == null;
    final bonus = valid ? bonusFor(a!) : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('شحن الرصيد التجريبي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [C.gold, C.green]),
          ),
          child: const Row(children: [
            Icon(Icons.card_giftcard, color: C.navy, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text('اشحن 50\$ أو أكثر واحصل على 5\$ هدية (رصيد تجريبي)',
                  style: TextStyle(color: C.navy, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
          child: const Row(children: [
            Icon(Icons.info_outline, color: C.gold),
            SizedBox(width: 10),
            Expanded(
              child: Text('نسخة تجريبية: الرصيد افتراضي ولا يوجد أي دفع أو تحويل أموال حقيقية.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('اختر المبلغ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in depositPresets)
            ChoiceChip(
              label: Text('\$$p'),
              selected: _custom.text.trim().isEmpty && _preset == p.toDouble(),
              selectedColor: C.green,
              labelStyle: TextStyle(
                  color: _custom.text.trim().isEmpty && _preset == p.toDouble() ? C.navy : Colors.white),
              onSelected: (_) => setState(() { _custom.clear(); _preset = p.toDouble(); _error = null; }),
            ),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _custom,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(labelText: 'مبلغ مخصص (10 - 1000)', prefixText: '\$ '),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            _row('المبلغ', valid ? '\$${fmtMoney(a!)}' : '—'),
            _row('الهدية', '\$${fmtMoney(bonus)}'),
            const Divider(color: Colors.white12),
            _row('الإجمالي', valid ? '\$${fmtMoney(a! + bonus)}' : '—', bold: true),
            _row('الطريقة', 'رصيد تجريبي'),
          ]),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: C.red))),
        const SizedBox(height: 20),
        GlowButton(valid ? 'شحن \$${fmtMoney(a!)}' : 'شحن', loading: _loading, onPressed: _submit),
        const SizedBox(height: 12),
        const SupportButton(topic: 'الشحن'),
      ]),
    );
  }

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(l, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(v, textDirection: TextDirection.ltr,
              style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? C.gold : null)),
        ]),
      );
}
