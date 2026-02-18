import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/deck.dart';
import '../widgets/flip_card.dart';
import '../widgets/progress_circle.dart';
import 'deck_details_cubit.dart';

class DeckDetailsPage extends StatelessWidget {
  final String deckId;

  const DeckDetailsPage({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeckDetailsCubit>(
      create: (context) =>
          DeckDetailsCubit(context.read(), deckId)..init(),
      child: const _DeckDetailsView(),
    );
  }
}

class _DeckDetailsView extends StatelessWidget {
  const _DeckDetailsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<DeckDetailsCubit, DeckDetailsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final deck = state.deck?.deck;
        return Scaffold(
          appBar: AppBar(
            title: Text(deck?.name ?? 'Набор'),
          ),
          body: SafeArea(
            child: state.isLoading && state.deck == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.deck != null) _Header(progress: state.deck!),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Карточки',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text('${state.cards.length}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: state.cards.isEmpty
                              ? _EmptyCards(
                                  onCreate: () =>
                                      _showAddCardDialog(context),
                                )
                              : ListView.separated(
                                  itemCount: state.cards.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final card = state.cards[index];
                                    return Dismissible(
                                      key: ValueKey(card.id),
                                      background: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.error,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 24),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) async {
                                        return await _confirmDeleteCard(
                                          context,
                                          card.front,
                                        );
                                      },
                                      onDismissed: (_) {
                                        context
                                            .read<DeckDetailsCubit>()
                                            .deleteCard(card.id);
                                      },
                                      child: FlipCard(
                                        front: card.front,
                                        back: card.back,
                                        subtitle:
                                            'Следующее повторение: ${_formatDate(card.nextReview)}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCardDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Добавить карточку'),
          ),
        );
      },
    );
  }

  Future<void> _showAddCardDialog(BuildContext context) async {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новая карточка'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: frontController,
                  decoration: const InputDecoration(labelText: 'Слово'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Введите слово';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: backController,
                  decoration: const InputDecoration(labelText: 'Перевод'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Введите перевод';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  context.read<DeckDetailsCubit>().addCard(
                        frontController.text,
                        backController.text,
                      );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDeleteCard(
    BuildContext context,
    String front,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить карточку?'),
          content: Text('Вы действительно хотите удалить карточку "$front"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}

class _Header extends StatelessWidget {
  final DeckProgress progress;

  const _Header({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        ProgressCircle(
          progress: progress.progress,
          size: 72,
          label: '${(progress.progress * 100).round()}%',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.deck.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (progress.deck.description.isNotEmpty)
                Text(
                  progress.deck.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Text(
                'Карточек: ${progress.totalCards} • Сегодня к повторению: ${progress.dueToday}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCards extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCards({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('В этом наборе ещё нет карточек'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Добавить первую карточку'),
          ),
        ],
      ),
    );
  }
}

