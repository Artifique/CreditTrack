import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Séparateur horizontal avec effet de pointillés personnalisables.
class DottedDivider extends StatelessWidget {
  final double dashWidth;
  final double dashHeight;
  final double dashSpace;
  final Color? color;

  const DottedDivider({
    super.key,
    this.dashWidth = 5.0,
    this.dashHeight = 1.0,
    this.dashSpace = 4.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = color ?? (isDark ? AppTokens.darkBorder : AppTokens.lightBorder);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: strokeColor),
              ),
            );
          }),
        );
      },
    );
  }
}
