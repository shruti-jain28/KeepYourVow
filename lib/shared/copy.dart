// lib/shared/copy.dart
// All user-facing strings in one place.
class KYVCopy {
  KYVCopy._();

  // ─── COMPLETION ─────────────────────────────────────────────────
  static const allDoneTitle = "You\u2019ve kept your promises today.";
  static const allDoneSubtitle = "Enjoy your time.";

  // ─── HABIT COMPLETION ───────────────────────────────────────────
  static const habitDone = "Nice work. That\u2019s one promise kept.";

  // ─── RECOVERY (missed day) ──────────────────────────────────────
  static const recoveryTitle = "Yesterday didn\u2019t go as planned.";
  static const recoveryAction = "Want to reset and continue?";

  // ─── EMPTY STATES ───────────────────────────────────────────────
  static const noHabitsTitle = "No habits yet.";
  static const noHabitsHint = "Add your first habit \u2192";
  static const noGoalHint = "Make your first vow";

  // ─── GOAL CREATION ──────────────────────────────────────────────
  static const goalVowButtonLabel = "I vow this \ud83e\udd1d";
  static const goalPhrasePlaceholder = "I am becoming someone who...";

  // ─── NOTIFICATIONS ──────────────────────────────────────────────
  static const notifTitle = "How are your habits today?";
  static const notifBody = "Your vow is waiting for you.";

  // ─── CREATE CHOOSER ─────────────────────────────────────────────
  static const createGoalDesc =
      "A goal is a commitment with an end date. Attach habits to stay on track.";
  static const createHabitDesc =
      "A habit is something you practice regularly \u2014 daily, weekly, or on your own schedule.";
}
