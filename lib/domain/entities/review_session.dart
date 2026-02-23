import 'deck.dart';

class ReviewCard {
  final CardEntity card;
  final int index;
  final int total;

  const ReviewCard({
    required this.card,
    required this.index,
    required this.total,
  });
}

class ReviewSummary {
  final int reviewedToday;
  final int correctToday;
  final int totalCards;
  final int learnedCards;
  final int dueToday;
  final double? progressScore;

  const ReviewSummary({
    required this.reviewedToday,
    required this.correctToday,
    required this.totalCards,
    required this.learnedCards,
    required this.dueToday,
    this.progressScore,
  });

  double get successRate =>
      reviewedToday == 0 ? 0 : correctToday / reviewedToday;

  /// Прогресс изучения: даёт частичный зачёт за карточки с repetition 1–2
  /// (repetition/3), полный зачёт за repetition >= 3
  double get overallProgress {
    if (totalCards == 0) return 0;
    if (progressScore != null) {
      return (progressScore! / totalCards).clamp(0.0, 1.0);
    }
    return learnedCards.clamp(0, totalCards) / totalCards;
  }
}

