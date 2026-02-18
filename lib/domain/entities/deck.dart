class Deck {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });
}

class CardEntity {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final DateTime createdAt;
  final DateTime nextReview;
  final int repetition;
  final double easeFactor;
  final int intervalDays;
  final int totalReviews;
  final int successfulReviews;

  const CardEntity({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.nextReview,
    required this.repetition,
    required this.easeFactor,
    required this.intervalDays,
    required this.totalReviews,
    required this.successfulReviews,
  });

  CardEntity copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    DateTime? createdAt,
    DateTime? nextReview,
    int? repetition,
    double? easeFactor,
    int? intervalDays,
    int? totalReviews,
    int? successfulReviews,
  }) {
    return CardEntity(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt ?? this.createdAt,
      nextReview: nextReview ?? this.nextReview,
      repetition: repetition ?? this.repetition,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      totalReviews: totalReviews ?? this.totalReviews,
      successfulReviews: successfulReviews ?? this.successfulReviews,
    );
  }
}

class DeckProgress {
  final Deck deck;
  final int totalCards;
  final int learnedCards;
  final int dueToday;

  const DeckProgress({
    required this.deck,
    required this.totalCards,
    required this.learnedCards,
    required this.dueToday,
  });

  double get progress =>
      totalCards == 0 ? 0 : learnedCards.clamp(0, totalCards) / totalCards;
}

