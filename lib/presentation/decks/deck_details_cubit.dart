import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/deck.dart';
import '../../domain/repositories/deck_repository.dart';

class DeckDetailsState extends Equatable {
  final DeckProgress? deck;
  final List<CardEntity> cards;
  final bool isLoading;
  final String? error;

  const DeckDetailsState({
    required this.deck,
    required this.cards,
    required this.isLoading,
    this.error,
  });

  DeckDetailsState copyWith({
    DeckProgress? deck,
    List<CardEntity>? cards,
    bool? isLoading,
    String? error,
  }) {
    return DeckDetailsState(
      deck: deck ?? this.deck,
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [deck, cards, isLoading, error];
}

class DeckDetailsCubit extends Cubit<DeckDetailsState> {
  final DeckRepository _deckRepository;
  final String deckId;

  StreamSubscription<DeckProgress>? _deckSub;
  StreamSubscription<List<CardEntity>>? _cardsSub;

  DeckDetailsCubit(this._deckRepository, this.deckId)
      : super(const DeckDetailsState(
          deck: null,
          cards: [],
          isLoading: true,
        ));

  void init() {
    emit(state.copyWith(isLoading: true, error: null));
    _deckSub?.cancel();
    _cardsSub?.cancel();

    _deckSub = _deckRepository.watchDeck(deckId).listen(
      (deck) {
        emit(state.copyWith(deck: deck, isLoading: false));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString(), isLoading: false));
      },
    );

    _cardsSub = _deckRepository.watchCards(deckId).listen(
      (cards) {
        emit(state.copyWith(cards: cards, isLoading: false));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString(), isLoading: false));
      },
    );
  }

  Future<void> addCard(String front, String back) async {
    if (front.trim().isEmpty || back.trim().isEmpty) return;
    try {
      await _deckRepository.addCard(deckId: deckId, front: front, back: back);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _deckRepository.deleteCard(cardId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _deckSub?.cancel();
    _cardsSub?.cancel();
    return super.close();
  }
}

