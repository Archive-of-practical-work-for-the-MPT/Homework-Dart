import '../entities/deck.dart';
import '../entities/review_session.dart';

abstract class DeckRepository {
  Stream<List<DeckProgress>> watchDecks();

  Future<Deck> createDeck({
    required String name,
    required String description,
  });

  Future<void> updateDeck(Deck deck);

  Future<void> deleteDeck(String deckId);

  Stream<DeckProgress> watchDeck(String deckId);

  Stream<List<CardEntity>> watchCards(String deckId);

  Future<CardEntity> addCard({
    required String deckId,
    required String front,
    required String back,
  });

  Future<void> updateCard(CardEntity card);

  Future<void> deleteCard(String cardId);

  Future<List<CardEntity>> loadDueCards({String? deckId, DateTime? today});

  Future<CardEntity> saveReview({
    required CardEntity card,
    required int quality, // 0-5
    required DateTime now,
  });

  Future<ReviewSummary> loadSummary({DateTime? today});
}

