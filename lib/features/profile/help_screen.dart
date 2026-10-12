import 'package:flutter/material.dart';
import '../../core/support.dart';
import '../../core/theme.dart';

const _faq = [
  ('ما هو سهمي؟', 'تطبيق تعليمي لمحاكاة التداول. الأسعار والرصيد والمكافآت كلها افتراضية.'),
  ('هل الأموال حقيقية؟', 'لا. الرصيد تجريبي ولا يمكن سحبه أو تحويله إلى مال حقيقي.'),
  ('كيف تعمل الإشارات؟', 'نجمع RSI والمتوسطات وMACD والحجم وبولينجر والأخبار (محاكاة) بأوزان محددة لنتيجة من 0 إلى 100. للتعلّم فقط وليست نصيحة استثمارية.'),
  ('كيف أجمع نقاط XP؟', 'بالدخول اليومي، تنفيذ الصفقات، الشارات، التحديات، ودعوة الأصدقاء.'),
  ('ما هو الـ Streak؟', 'عدد الأيام المتتالية التي فتحت فيها التطبيق. تفوّت يوماً فيعود العدّاد إلى 1.'),
  ('كيف أتواصل مع الدعم؟', 'من زر "تواصل مع الدعم" أدناه، يفتح تلغرام وينسخ رسالة جاهزة.'),
];

/// المساعدة / Help & FAQ
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المساعدة')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final q in _faq)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(q.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.centerRight,
                  children: [Text(q.$2, style: const TextStyle(color: Colors.white70, height: 1.6))],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const SupportButton(topic: 'مساعدة'),
        ]),
      );
}
