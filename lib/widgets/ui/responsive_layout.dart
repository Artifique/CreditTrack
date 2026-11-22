import 'package:flutter/material.dart';
import '../../core/tokens.dart';

/// Screen breakpoints for mobile-first responsive architecture
class ResponsiveBreakpoints {
  static const double mobileMax = 640.0;
  static const double tabletMax = 1024.0;
}

class ResponsiveLayout {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobileMax &&
        width < ResponsiveBreakpoints.tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tabletMax;
}

/// Container that constrains width on larger screens and centers content
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1100.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? AppTokens.space16 : AppTokens.space24,
      vertical: isMobile ? AppTokens.space16 : AppTokens.space24,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}
