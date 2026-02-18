import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/review_session.dart';
import '../../domain/repositories/deck_repository.dart';

class StatsState extends Equatable {
  final bool isLoading;
  final ReviewSummary? summary;
  final String? error;

  const StatsState({
    required this.isLoading,
    this.summary,
    this.error,
  });

  factory StatsState.initial() => const StatsState(isLoading: true);

  StatsState copyWith({
    bool? isLoading,
    ReviewSummary? summary,
    String? error,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, summary, error];
}

class StatsCubit extends Cubit<StatsState> {
  final DeckRepository _deckRepository;

  StatsCubit(this._deckRepository) : super(StatsState.initial());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final summary = await _deckRepository.loadSummary();
      emit(
        state.copyWith(
          isLoading: false,
          summary: summary,
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
}

