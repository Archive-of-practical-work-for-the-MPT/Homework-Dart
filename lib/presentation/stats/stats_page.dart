import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/progress_circle.dart';
import 'stats_cubit.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StatsCubit, StatsState>(
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
                        'Статистика',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        tooltip: 'Обновить',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => context.read<StatsCubit>().load(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 24),
                  if (state.summary == null)
                    const Expanded(
                      child: Center(
                        child: Text('Пока нет данных для статистики'),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          ProgressCircle(
                            progress: state.summary!.overallProgress,
                            size: 140,
                            label:
                                '${(state.summary!.overallProgress * 100).round()}%',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Общий прогресс изучения',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          _StatTile(
                            title: 'Всего карточек',
                            value: state.summary!.totalCards.toString(),
                            icon: Icons.style,
                          ),
                          const SizedBox(height: 8),
                          _StatTile(
                            title: 'Карточек выучено (3+ повторений)',
                            value: state.summary!.learnedCards.toString(),
                            icon: Icons.check_circle,
                          ),
                          const SizedBox(height: 8),
                          _StatTile(
                            title: 'К повторению сегодня',
                            value: state.summary!.dueToday.toString(),
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(height: 8),
                          _StatTile(
                            title: 'Точность ответов',
                            value:
                                '${(state.summary!.successRate * 100).round()}%',
                            icon: Icons.insights,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

