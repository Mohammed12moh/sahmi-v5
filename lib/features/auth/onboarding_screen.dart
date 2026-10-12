import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/haptics.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;
  final _answers = <int, int>{};

  static const _quiz = [
    ('كم مدة استثمارك المتوقعة؟', ['أقل من شهر', 'عدة أشهر', 'سنة أو أكثر']),
    ('كيف تتصرف إذا هبط السهم 10%؟', ['أبيع فوراً', 'أنتظر', 'أشتري أكثر']),
    ('ما هدفك الأساسي؟', ['حماية رأس المال', 'نمو متوازن', 'أقصى عائد']),
    ('خبرتك في التداول؟', ['مبتدئ', 'متوسط', 'خبير']),
    ('كم تتحمل من التذبذب؟', ['قليل', 'متوسط', 'كبير']),
  ];

  void _next() {
    Haptics.selection();
    if (_page < 4) {
      _pc.nextPage(duration: 350.ms, curve: Curves.easeOut);
    } else {
      context.go('/register');
    }
  }

  Widget _slide(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 100, color: C.gold)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(.9, .9), end: const Offset(1.1, 1.1), duration: 1400.ms),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.7), textAlign: TextAlign.center),
        ]),
      );

  Widget _quizPage() => ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 16),
        const Text('اختبار المخاطر', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Text('تعليمي فقط / for education only', style: TextStyle(color: Colors.white54)),
        for (var i = 0; i < _quiz.length; i++) ...[
          const SizedBox(height: 18),
          Text('${i + 1}. ${_quiz[i].$1}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (var j = 0; j < 3; j++)
              ChoiceChip(
                label: Text(_quiz[i].$2[j]),
                selected: _answers[i] == j,
                selectedColor: C.green,
                labelStyle: TextStyle(color: _answers[i] == j ? C.navy : Colors.white),
                onSelected: (_) => setState(() => _answers[i] = j),
              ),
          ]),
        ],
      ]);

  @override
  Widget build(BuildContext context) {
    final last = _page == 4;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => context.go('/login'), child: const Text('لدي حساب')),
          ),
          Expanded(
            child: PageView(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _slide(Icons.auto_awesome, 'أهلاً بك في سهمي', 'تعلّم التداول بتجربة ممتعة وبرصيد تجريبي بلا مخاطر.'),
                _slide(Icons.insights, 'إشارات دقيقة', 'مؤشرات RSI وMACD وBollinger مجمّعة في إشارة واضحة مع سبب وثقة.'),
                _slide(Icons.group_add, 'ادعُ أصدقاءك', 'اجمع نقاط XP وارتقِ من برونزي إلى ماسي.'),
                _quizPage(),
                _slide(Icons.rocket_launch, 'خلّينا نبدأ', 'حسابك التجريبي جاهز في دقيقة.'),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 5; i++)
              AnimatedContainer(
                duration: 250.ms,
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                    color: i == _page ? C.gold : Colors.white24, borderRadius: BorderRadius.circular(8)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: GlowButton(last ? 'ابدأ الآن' : 'التالي',
                onPressed: (_page == 3 && _answers.length < 5) ? null : _next),
          ),
        ]),
      ),
    );
  }
}
