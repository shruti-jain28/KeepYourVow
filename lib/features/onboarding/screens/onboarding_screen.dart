// lib/features/onboarding/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../features/today/services/notification_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: "\ud83e\udd1d",
      title: "Make a vow.",
      body:
          "Write a commitment to yourself in your own words. Not a task \u2014 a promise.",
    ),
    _Slide(
      emoji: "\ud83d\udcaa",
      title: "Build habits.",
      body:
          "Attach daily habits to your goals, or create standalone habits to keep you on track.",
    ),
    _Slide(
      emoji: "\ud83d\udd25",
      title: "Build the streak.",
      body:
          "Every day you show up, the streak grows. Miss a day \u2014 no shame. Just reset and continue.",
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);

    try {
      await NotificationService.instance.scheduleDailyReminder(
        hour: 8,
        minute: 0,
      );
    } catch (_) {
      // Notification scheduling may fail if plugin isn't ready yet;
      // don't block onboarding completion.
    }

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KYVColors.pale,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text("Skip", style: KYVText.caption(context)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? KYVColors.sky : KYVColors.light,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _page < _slides.length - 1
                    ? () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut)
                    : _finish,
                child: Text(
                    _page < _slides.length - 1 ? 'Next' : 'Get started'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final String emoji, title, body;
  const _Slide(
      {required this.emoji, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 32),
          Text(slide.title,
              style: KYVText.display(context),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(slide.body,
              style: KYVText.body(context), textAlign: TextAlign.center),
        ]),
      );
}
