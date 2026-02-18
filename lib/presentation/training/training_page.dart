import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/flip_card.dart';
import 'training_cubit.dart';

class TrainingPage extends StatelessWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrainingCubit, TrainingState>(
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
        final theme = Theme.of(context);

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
                        'Тренировка',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        tooltip: 'Обновить список карточек',
                        icon: const Icon(Icons.refresh),
                        onPressed: () =>
                            context.read<TrainingCubit>().load(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildContent(context, state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TrainingState state) {
    final theme = Theme.of(context);
    final current = state.currentCard;

    if (!state.hasCards) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 72, color: Colors.green),
            const SizedBox(height: 8),
            const Text('На сегодня нет карточек к повторению'),
            const SizedBox(height: 8),
            Text(
              'Создайте новые карточки или приходите завтра',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<TrainingCubit>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Проверить ещё раз'),
            ),
          ],
        ),
      );
    }

    if (state.currentIndex >= state.queue.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 72, color: Colors.orange),
            const SizedBox(height: 8),
            const Text('Тренировка завершена!'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.read<TrainingCubit>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Начать заново'),
            ),
          ],
        ),
      );
    }

    final progress =
        (current!.index / current.total).clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Карточка ${current.index} из ${current.total}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => context.read<TrainingCubit>().flip(),
              child: FlipCard(
                front: current.card.front,
                back: current.card.back,
                isFlipped: state.isFlipped,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Оцените, насколько легко вы вспомнили перевод:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    context.read<TrainingCubit>().answer(2),
                child: const Text('Сложно'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    context.read<TrainingCubit>().answer(4),
                child: const Text('Нормально'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () =>
                    context.read<TrainingCubit>().answer(5),
                child: const Text('Легко'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

