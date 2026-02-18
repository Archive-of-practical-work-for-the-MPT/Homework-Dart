import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/deck.dart';
import '../../domain/repositories/deck_repository.dart';

class DecksState extends Equatable {
  final bool isLoading;
  final List<DeckProgress> decks;
  final String? error;

  const DecksState({
    required this.isLoading,
    required this.decks,
    this.error,
  });

  factory DecksState.initial() => const DecksState(isLoading: true, decks: []);

  DecksState copyWith({
    bool? isLoading,
    List<DeckProgress>? decks,
    String? error,
  }) {
    return DecksState(
      isLoading: isLoading ?? this.isLoading,
      decks: decks ?? this.decks,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, decks, error];
}

class DecksCubit extends Cubit<DecksState> {
  final DeckRepository _deckRepository;
  StreamSubscription<List<DeckProgress>>? _subscription;

  DecksCubit(this._deckRepository) : super(DecksState.initial());

  void init() {
    _subscription?.cancel();
    emit(state.copyWith(isLoading: true, error: null));
    _subscription = _deckRepository.watchDecks().listen(
      (decks) {
        emit(
          state.copyWith(
            isLoading: false,
            decks: decks,
            error: null,
          ),
        );
      },
      onError: (error, _) {
        emit(
          state.copyWith(
            isLoading: false,
            error: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> createDeck(String name, String description) async {
    if (name.trim().isEmpty) return;
    try {
      await _deckRepository.createDeck(name: name, description: description);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      await _deckRepository.deleteDeck(deckId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

