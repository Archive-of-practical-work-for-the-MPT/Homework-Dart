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

  const ReviewSummary({
    required this.reviewedToday,
    required this.correctToday,
    required this.totalCards,
    required this.learnedCards,
    required this.dueToday,
  });

  double get successRate =>
      reviewedToday == 0 ? 0 : correctToday / reviewedToday;

  double get overallProgress =>
      totalCards == 0 ? 0 : learnedCards.clamp(0, totalCards) / totalCards;
}

