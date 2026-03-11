// lib/features/goals/models/goal.dart

class Goal {
  final int? id; // null until saved to DB
  final String title; // short name, e.g. 'Marathon Training'
  final String identityPhrase; // 'I am becoming someone who runs every day'
  final DateTime endDate; // when this chapter ends
  final bool strengthenFocus; // enables Guardian lock mode
  final DateTime createdAt;

  const Goal({
    this.id,
    required this.title,
    required this.identityPhrase,
    required this.endDate,
    required this.strengthenFocus,
    required this.createdAt,
  });

  Goal copyWith({
    int? id,
    String? title,
    String? identityPhrase,
    DateTime? endDate,
    bool? strengthenFocus,
    DateTime? createdAt,
  }) =>
      Goal(
        id: id ?? this.id,
        title: title ?? this.title,
        identityPhrase: identityPhrase ?? this.identityPhrase,
        endDate: endDate ?? this.endDate,
        strengthenFocus: strengthenFocus ?? this.strengthenFocus,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'identityPhrase': identityPhrase,
        'endDate': endDate.toIso8601String(),
        'strengthenFocus': strengthenFocus ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as int?,
        title: map['title'] as String,
        identityPhrase: map['identityPhrase'] as String,
        endDate: DateTime.parse(map['endDate'] as String),
        strengthenFocus: (map['strengthenFocus'] as int) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
