import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/deck.dart';
import '../../domain/entities/review_session.dart';
import '../../domain/repositories/deck_repository.dart';

class FirestoreDeckRepository implements DeckRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _decksRef {
    final uid = _userId;
    if (uid == null) throw StateError('User not signed in');
    return _firestore.collection('users').doc(uid).collection('decks');
  }

  CollectionReference<Map<String, dynamic>> _cardsRef(String deckId) =>
      _decksRef.doc(deckId).collection('cards');

  Deck _docToDeck(String id, Map<String, dynamic> doc) {
    final data = doc;
    return Deck(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  DeckProgress _docToDeckProgress(String id, Map<String, dynamic> doc) {
    final deck = _docToDeck(id, doc);
    final progressScore = (doc['progressScore'] as num?)?.toDouble();
    return DeckProgress(
      deck: deck,
      totalCards: (doc['totalCards'] as int?) ?? 0,
      learnedCards: (doc['learnedCards'] as int?) ?? 0,
      dueToday: (doc['dueToday'] as int?) ?? 0,
      progressScore: progressScore,
    );
  }

  CardEntity _docToCard(String id, Map<String, dynamic> doc) {
    return CardEntity(
      id: id,
      deckId: doc['deckId'] as String? ?? '',
      front: doc['front'] as String? ?? '',
      back: doc['back'] as String? ?? '',
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextReview:
          (doc['nextReview'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repetition: (doc['repetition'] as int?) ?? 0,
      easeFactor: (doc['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (doc['intervalDays'] as int?) ?? 0,
      totalReviews: (doc['totalReviews'] as int?) ?? 0,
      successfulReviews: (doc['successfulReviews'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> _cardToMap(CardEntity card) => {
        'deckId': card.deckId,
        'front': card.front,
        'back': card.back,
        'createdAt': Timestamp.fromDate(card.createdAt),
        'nextReview': Timestamp.fromDate(card.nextReview),
        'repetition': card.repetition,
        'easeFactor': card.easeFactor,
        'intervalDays': card.intervalDays,
        'totalReviews': card.totalReviews,
        'successfulReviews': card.successfulReviews,
      };

  Future<void> _updateDeckCounts(String deckId) async {
    final cardsSnap = await _cardsRef(deckId).get();
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    var totalCards = 0;
    var learnedCards = 0;
    var dueToday = 0;
    var progressScore = 0.0;

    for (final doc in cardsSnap.docs) {
      final data = doc.data();
      totalCards++;
      final rep = (data['repetition'] as num?)?.toInt() ?? 0;
      if (rep >= 3) {
        learnedCards++;
        progressScore += 1.0;
      } else if (rep > 0) {
        progressScore += rep / 3;
      }
      final nextReview =
          (data['nextReview'] as Timestamp?)?.toDate() ?? DateTime.now();
      if (!nextReview.isAfter(endOfDay)) dueToday++;
    }

    await _decksRef.doc(deckId).update({
      'totalCards': totalCards,
      'learnedCards': learnedCards,
      'dueToday': dueToday,
      'progressScore': progressScore,
    });
  }

  @override
  Stream<List<DeckProgress>> watchDecks() {
    if (_userId == null) return Stream.value([]);

    return _decksRef.orderBy('createdAt').snapshots().map((snap) {
      return snap.docs
          .map((d) => _docToDeckProgress(d.id, d.data()))
          .toList();
    });
  }

  @override
  Future<Deck> createDeck({
    required String name,
    required String description,
  }) async {
    final ref = _decksRef.doc();
    final deck = Deck(
      id: ref.id,
      name: name.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    await ref.set({
      'name': deck.name,
      'description': deck.description,
      'createdAt': Timestamp.fromDate(deck.createdAt),
      'totalCards': 0,
      'learnedCards': 0,
      'dueToday': 0,
      'progressScore': 0.0,
    });
    return deck;
  }

  @override
  Future<void> updateDeck(Deck deck) async {
    await _decksRef.doc(deck.id).update({
      'name': deck.name,
      'description': deck.description,
    });
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    final cardsSnap = await _cardsRef(deckId).get();
    for (final doc in cardsSnap.docs) {
      await doc.reference.delete();
    }
    await _decksRef.doc(deckId).delete();
  }

  @override
  Stream<DeckProgress> watchDeck(String deckId) {
    return _decksRef.doc(deckId).snapshots().map((doc) {
      if (!doc.exists) throw StateError('Deck not found');
      return _docToDeckProgress(doc.id, doc.data()!);
    });
  }

  @override
  Stream<List<CardEntity>> watchCards(String deckId) {
    return _cardsRef(deckId).orderBy('createdAt').snapshots().map((snap) {
      return snap.docs
          .map((d) => _docToCard(d.id, d.data()))
          .toList();
    });
  }

  @override
  Future<CardEntity> addCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final ref = _cardsRef(deckId).doc();
    final now = DateTime.now();
    final card = CardEntity(
      id: ref.id,
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
    await ref.set(_cardToMap(card));
    await _updateDeckCounts(deckId);
    return card;
  }

  @override
  Future<void> updateCard(CardEntity card) async {
    await _cardsRef(card.deckId).doc(card.id).update(_cardToMap(card));
    await _updateDeckCounts(card.deckId);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final decksSnap = await _decksRef.get();
    for (final deckDoc in decksSnap.docs) {
      final cardRef = _cardsRef(deckDoc.id).doc(cardId);
      final cardDoc = await cardRef.get();
      if (cardDoc.exists) {
        await cardRef.delete();
        await _updateDeckCounts(deckDoc.id);
        return;
      }
    }
  }

  @override
  Future<List<CardEntity>> loadDueCards({String? deckId, DateTime? today}) async {
    final now = today ?? DateTime.now();
    final endOfDay = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    if (deckId != null) {
      final snap = await _cardsRef(deckId)
          .where('nextReview', isLessThanOrEqualTo: endOfDay)
          .orderBy('nextReview')
          .get();
      return snap.docs.map((d) => _docToCard(d.id, d.data())).toList();
    }

    final decksSnap = await _decksRef.get();
    final allDue = <CardEntity>[];
    for (final deckDoc in decksSnap.docs) {
      final snap = await _cardsRef(deckDoc.id)
          .where('nextReview', isLessThanOrEqualTo: endOfDay)
          .orderBy('nextReview')
          .get();
      for (final cardDoc in snap.docs) {
        allDue.add(_docToCard(cardDoc.id, cardDoc.data()));
      }
    }
    allDue.sort((a, b) => a.nextReview.compareTo(b.nextReview));
    return allDue;
  }

  @override
  Future<CardEntity> saveReview({
    required CardEntity card,
    required int quality,
    required DateTime now,
  }) async {
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

    await _cardsRef(card.deckId).doc(card.id).update(_cardToMap(updated));
    await _updateDeckCounts(card.deckId);
    return updated;
  }

  @override
  Future<ReviewSummary> loadSummary({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    var totalCards = 0;
    var learnedCards = 0;
    var dueToday = 0;
    var reviewedToday = 0;
    var correctToday = 0;
    var progressScore = 0.0;

    final decksSnap = await _decksRef.get();
    for (final deckDoc in decksSnap.docs) {
      final cardsSnap = await _cardsRef(deckDoc.id).get();
      for (final cardDoc in cardsSnap.docs) {
        final data = cardDoc.data();
        totalCards++;
        final rep = (data['repetition'] as num?)?.toInt() ?? 0;
        if (rep >= 3) {
          learnedCards++;
          progressScore += 1.0;
        } else if (rep > 0) {
          progressScore += rep / 3;
        }
        final nextReview =
            (data['nextReview'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (!nextReview.isAfter(endOfDay)) dueToday++;

        final totalReviews = (data['totalReviews'] as num?)?.toInt() ?? 0;
        final successfulReviews =
            (data['successfulReviews'] as num?)?.toInt() ?? 0;
        if (totalReviews > 0) {
          reviewedToday += totalReviews;
          correctToday += successfulReviews;
        }
      }
    }

    return ReviewSummary(
      reviewedToday: reviewedToday,
      correctToday: correctToday,
      totalCards: totalCards,
      learnedCards: learnedCards,
      dueToday: dueToday,
      progressScore: progressScore,
    );
  }
}
