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
    return width >= ResponsiveBreakpoints.mobileMax && width < ResponsiveBreakpoints.tabletMax;
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

/// Navigation item model
class AppNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// Modern adaptive navigation component:
/// Mobile: Floating bottom navigation bar with active pill indicators and min 44x44 touch targets
/// Tablet/Desktop: Sleek side navigation rail
class AppAdaptiveNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<AppNavItem> items;

  const AppAdaptiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: AppTokens.shadowSm(isDark),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return InkWell(
                onTap: () => onIndexChanged(index),
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppTokens.minTouchTarget,
                    minHeight: AppTokens.minTouchTarget,
                  ),
                  child: AnimatedContainer(
                    duration: AppTokens.durationFast,
                    curve: AppTokens.curveStandard,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0x336366F1) : AppTokens.primary50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 22,
                          color: isSelected
                              ? (isDark ? AppTokens.primary300 : AppTokens.primary600)
                              : (isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
