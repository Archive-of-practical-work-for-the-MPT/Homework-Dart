import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/deck.dart';
import '../widgets/progress_circle.dart';
import 'deck_details_page.dart';
import 'decks_cubit.dart';

class DecksPage extends StatelessWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DecksCubit, DecksState>(
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
        if (state.isLoading && state.decks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ваши наборы',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${state.decks.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: state.decks.isEmpty
                        ? _EmptyDecks(onCreate: () => _showCreateDeckDialog(context))
                        : ListView.separated(
                            itemCount: state.decks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final deck = state.decks[index];
                              return _DeckCard(
                                deckProgress: deck,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DeckDetailsPage(deckId: deck.deck.id),
                                    ),
                                  );
                                },
                                onDelete: () =>
                                    _confirmDeleteDeck(context, deck.deck.id, deck.deck.name),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateDeckDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Новый набор'),
          ),
        );
      },
    );
  }

  Future<void> _showCreateDeckDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новый набор'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Введите название набора';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (необязательно)',
                  ),
                  maxLines: 2,
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
                  context.read<DecksCubit>().createDeck(
                        nameController.text,
                        descriptionController.text,
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

  Future<void> _confirmDeleteDeck(
    BuildContext context,
    String deckId,
    String deckName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить набор?'),
          content: Text('Вы действительно хотите удалить набор "$deckName" и все его карточки?'),
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

    if (result == true && context.mounted) {
      await context.read<DecksCubit>().deleteDeck(deckId);
    }
  }
}

class _EmptyDecks extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyDecks({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('Пока нет ни одного набора'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Создать первый набор'),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final DeckProgress deckProgress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deckProgress,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deck = deckProgress.deck;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ProgressCircle(
              progress: deckProgress.progress,
              size: 56,
              label: '${(deckProgress.progress * 100).round()}%',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (deck.description.isNotEmpty)
                    Text(
                      deck.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Карточек: ${deckProgress.totalCards} • Сегодня к повторению: ${deckProgress.dueToday}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

