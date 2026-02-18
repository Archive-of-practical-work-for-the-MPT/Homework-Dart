import 'dart:math';

import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  final String front;
  final String back;
  final String? subtitle;
  final bool isFlipped;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.subtitle,
    this.isFlipped = false,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (widget.isFlipped) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(260.0, 460.0);
        final maxHeight = constraints.maxHeight.clamp(180.0, 320.0);

        return Center(
          child: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final angle = _controller.value * pi;
                final isFront = angle <= pi / 2;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: isFront
                        ? _buildSide(
                            context,
                            title: widget.front,
                            subtitle: 'Нажмите, чтобы показать перевод',
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildSide(
                              context,
                              title: widget.back,
                              subtitle:
                                  widget.subtitle ?? 'Нажмите, чтобы скрыть',
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSide(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

