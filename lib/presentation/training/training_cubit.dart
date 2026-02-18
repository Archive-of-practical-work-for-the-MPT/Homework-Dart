import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/deck.dart';
import '../../domain/entities/review_session.dart';
import '../../domain/repositories/deck_repository.dart';

class TrainingState extends Equatable {
  final List<CardEntity> queue;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final String? error;

  const TrainingState({
    required this.queue,
    required this.currentIndex,
    required this.isFlipped,
    required this.isLoading,
    this.error,
  });

  factory TrainingState.initial() => const TrainingState(
        queue: [],
        currentIndex: 0,
        isFlipped: false,
        isLoading: false,
      );

  bool get hasCards => queue.isNotEmpty;

  ReviewCard? get currentCard {
    if (!hasCards || currentIndex >= queue.length) return null;
    return ReviewCard(
      card: queue[currentIndex],
      index: currentIndex + 1,
      total: queue.length,
    );
  }

  TrainingState copyWith({
    List<CardEntity>? queue,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    String? error,
  }) {
    return TrainingState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [queue, currentIndex, isFlipped, isLoading, error];
}

class TrainingCubit extends Cubit<TrainingState> {
  final DeckRepository _deckRepository;

  TrainingCubit(this._deckRepository) : super(TrainingState.initial());

  Future<void> load({String? deckId}) async {
    emit(state.copyWith(isLoading: true, error: null, isFlipped: false));
    try {
      final cards = await _deckRepository.loadDueCards(deckId: deckId);
      emit(
        state.copyWith(
          queue: cards,
          currentIndex: 0,
          isLoading: false,
          isFlipped: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void flip() {
    if (!state.hasCards) return;
    emit(state.copyWith(isFlipped: !state.isFlipped));
  }

  Future<void> answer(int quality) async {
    final current = state.currentCard;
    if (current == null) return;
    try {
      final updated = await _deckRepository.saveReview(
        card: current.card,
        quality: quality,
        now: DateTime.now(),
      );

      final newQueue = [...state.queue];
      newQueue[state.currentIndex] = updated;

      var nextIndex = state.currentIndex + 1;
      var isFlipped = false;
      if (nextIndex >= newQueue.length) {
        nextIndex = newQueue.length; // конец тренировки
      }

      emit(
        state.copyWith(
          queue: newQueue,
          currentIndex: nextIndex,
          isFlipped: isFlipped,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

