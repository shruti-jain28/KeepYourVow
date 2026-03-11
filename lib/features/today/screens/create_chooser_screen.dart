// lib/features/today/screens/create_chooser_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/copy.dart';

class CreateChooserScreen extends StatelessWidget {
  const CreateChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text("Create New", style: KYVText.heading(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What would you like to create?",
                style: KYVText.body(context)),
            const SizedBox(height: 24),
            _OptionCard(
              icon: Icons.flag_rounded,
              iconColor: KYVColors.deep,
              title: "Goal",
              description: KYVCopy.createGoalDesc,
              onTap: () => context.push('/goals/new'),
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.repeat_rounded,
              iconColor: KYVColors.teal,
              title: "Habit",
              description: KYVCopy.createHabitDesc,
              onTap: () => context.push('/habits/new'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KYVColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KYVColors.light, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KYVText.subheading(context)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: KYVText.caption(context),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: KYVColors.darkGray),
            ],
          ),
        ),
      );
}
