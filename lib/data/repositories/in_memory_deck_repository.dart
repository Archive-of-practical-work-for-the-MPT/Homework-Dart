import 'dart:async';
import 'dart:math';

import '../../domain/entities/deck.dart';
import '../../domain/entities/review_session.dart';
import '../../domain/repositories/deck_repository.dart';

class InMemoryDeckRepository implements DeckRepository {
  final _decks = <String, Deck>{};
  final _cards = <String, CardEntity>{};

  final _decksController = StreamController<List<DeckProgress>>.broadcast();
  final _deckControllers = <String, StreamController<DeckProgress>>{};
  final _cardsControllers = <String, StreamController<List<CardEntity>>>{};

  InMemoryDeckRepository() {
    _seedDemoData();
  }

  void _seedDemoData() {
    final now = DateTime.now();
    final deckId = 'demo-deck';
    final deck = Deck(
      id: deckId,
      name: 'Базовый английский',
      description: 'Самые частые слова английского языка',
      createdAt: now,
    );
    _decks[deckId] = deck;

    final demoCards = <CardEntity>[
      CardEntity(
        id: 'c1',
        deckId: deckId,
        front: 'apple',
        back: 'яблоко',
        createdAt: now,
        nextReview: now,
        repetition: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        totalReviews: 0,
        successfulReviews: 0,
      ),
      CardEntity(
        id: 'c2',
        deckId: deckId,
        front: 'book',
        back: 'книга',
        createdAt: now,
        nextReview: now,
        repetition: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        totalReviews: 0,
        successfulReviews: 0,
      ),
      CardEntity(
        id: 'c3',
        deckId: deckId,
        front: 'house',
        back: 'дом',
        createdAt: now,
        nextReview: now,
        repetition: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        totalReviews: 0,
        successfulReviews: 0,
      ),
    ];

    for (final card in demoCards) {
      _cards[card.id] = card;
    }

    _emitAll();
  }

  void _emitAll() {
    _decksController.add(_buildDeckProgressList());
    for (final entry in _deckControllers.entries) {
      final deckId = entry.key;
      final controller = entry.value;
      final deck = _decks[deckId];
      if (deck != null) {
        controller.add(_buildDeckProgress(deck));
      }
    }
    for (final entry in _cardsControllers.entries) {
      final deckId = entry.key;
      final controller = entry.value;
      controller.add(_cards.values.where((c) => c.deckId == deckId).toList());
    }
  }

  List<DeckProgress> _buildDeckProgressList() {
    return _decks.values.map(_buildDeckProgress).toList()..sort(
        (a, b) => a.deck.createdAt.compareTo(b.deck.createdAt),
      );
  }

  DeckProgress _buildDeckProgress(Deck deck) {
    final deckCards = _cards.values.where((c) => c.deckId == deck.id).toList();
    final now = DateTime.now();
    final total = deckCards.length;
    final learned = deckCards.where((c) => c.repetition >= 3).length;
    final dueToday = deckCards
        .where((c) => !c.nextReview.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59)))
        .length;

    return DeckProgress(
      deck: deck,
      totalCards: total,
      learnedCards: learned,
      dueToday: dueToday,
    );
  }

  @override
  Stream<List<DeckProgress>> watchDecks() {
    _decksController.add(_buildDeckProgressList());
    return _decksController.stream;
  }

  @override
  Future<Deck> createDeck({
    required String name,
    required String description,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final deck = Deck(
      id: id,
      name: name.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _decks[id] = deck;
    _emitAll();
    return deck;
  }

  @override
  Future<void> updateDeck(Deck deck) async {
    if (!_decks.containsKey(deck.id)) return;
    _decks[deck.id] = deck;
    _emitAll();
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    _decks.remove(deckId);
    _cards.removeWhere((key, value) => value.deckId == deckId);
    _deckControllers[deckId]?.addError(StateError('Deck deleted'));
    _cardsControllers[deckId]?.add([]);
    _emitAll();
  }

  @override
  Stream<DeckProgress> watchDeck(String deckId) {
    final controller = _deckControllers.putIfAbsent(
      deckId,
      () => StreamController<DeckProgress>.broadcast(),
    );
    final deck = _decks[deckId];
    if (deck != null) {
      controller.add(_buildDeckProgress(deck));
    }
    return controller.stream;
  }

  @override
  Stream<List<CardEntity>> watchCards(String deckId) {
    final controller = _cardsControllers.putIfAbsent(
      deckId,
      () => StreamController<List<CardEntity>>.broadcast(),
    );
    controller.add(_cards.values.where((c) => c.deckId == deckId).toList());
    return controller.stream;
  }

  @override
  Future<CardEntity> addCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final now = DateTime.now();
    final id = '${deckId}_${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}';
    final card = CardEntity(
      id: id,
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      createdAt: now,
      nextReview: now,
      repetition: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      totalReviews: 0,
      successfulReviews: 0,
    );
    _cards[id] = card;
    _emitAll();
    return card;
  }

  @override
  Future<void> updateCard(CardEntity card) async {
    if (!_cards.containsKey(card.id)) return;
    _cards[card.id] = card;
    _emitAll();
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final card = _cards.remove(cardId);
    if (card != null) {
      _emitAll();
    }
  }

  @override
  Future<List<CardEntity>> loadDueCards({String? deckId, DateTime? today}) async {
    final now = today ?? DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    Iterable<CardEntity> cards = _cards.values;
    if (deckId != null) {
      cards = cards.where((c) => c.deckId == deckId);
    }
    return cards
        .where((c) => !c.nextReview.isAfter(endOfDay))
        .toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
  }

  @override
  Future<CardEntity> saveReview({
    required CardEntity card,
    required int quality,
    required DateTime now,
  }) async {
    // Реализация SM-2
    final q = quality.clamp(0, 5);
    var ef = card.easeFactor;
    var repetition = card.repetition;
    var interval = card.intervalDays;

    if (q < 3) {
      repetition = 0;
      interval = 1;
    } else {
      if (repetition == 0) {
        interval = 1;
      } else if (repetition == 1) {
        interval = 6;
      } else {
        interval = (interval * ef).round().clamp(1, 3650);
      }
      repetition += 1;

      ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
      if (ef < 1.3) ef = 1.3;
    }

    final updated = card.copyWith(
      repetition: repetition,
      easeFactor: ef,
      intervalDays: interval,
      nextReview: now.add(Duration(days: interval)),
      totalReviews: card.totalReviews + 1,
      successfulReviews: card.successfulReviews + (q >= 3 ? 1 : 0),
    );
    _cards[card.id] = updated;
    _emitAll();
    return updated;
  }

  @override
  Future<ReviewSummary> loadSummary({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final totalCards = _cards.length;
    final learnedCards = _cards.values.where((c) => c.repetition >= 3).length;
    final dueToday =
        _cards.values.where((c) => !c.nextReview.isAfter(endOfDay)).length;

    final reviewedToday = _cards.values
        .where(
          (c) =>
              c.totalReviews > 0 &&
              c.nextReview.difference(c.createdAt).inDays >= 0,
        )
        .fold<int>(0, (prev, c) => prev + c.totalReviews);

    final correctToday = _cards.values
        .where((c) => c.successfulReviews > 0)
        .fold<int>(0, (prev, c) => prev + c.successfulReviews);

    return ReviewSummary(
      reviewedToday: reviewedToday,
      correctToday: correctToday,
      totalCards: totalCards,
      learnedCards: learnedCards,
      dueToday: dueToday,
    );
  }
}

