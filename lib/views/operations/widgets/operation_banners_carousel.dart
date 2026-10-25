import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

class BannerItemData {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<Color> gradient;
  final IconData icon;

  const BannerItemData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.gradient,
    required this.icon,
  });
}

/// Carrousel de bannières informatives optimisé avec RepaintBoundary et ValueNotifier.
class OperationBannersCarousel extends StatefulWidget {
  const OperationBannersCarousel({super.key});

  @override
  State<OperationBannersCarousel> createState() => _OperationBannersCarouselState();
}

class _OperationBannersCarouselState extends State<OperationBannersCarousel> {
  final PageController _controller = PageController();
  final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);

  static const List<BannerItemData> _banners = [
    BannerItemData(
      title: 'Orange Money Caisse',
      subtitle: 'Effectuez vos dépôts et retraits en toute sécurité',
      badge: 'SERVICE PRO',
      badgeColor: Color(0xFF1E293B),
      gradient: [AppTokens.primary500, AppTokens.primary600],
      icon: Icons.account_balance_wallet_rounded,
    ),
    BannerItemData(
      title: 'Orange Money Nafama',
      subtitle: 'Épargnez et faites fructifier les avoirs de vos clients',
      badge: 'ÉPARGNE SÉCURISÉE',
      badgeColor: AppTokens.primary500,
      gradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
      icon: Icons.savings_rounded,
    ),
    BannerItemData(
      title: 'E-Recharge & C2C',
      subtitle: 'Rechargez les forfaits et transférez sans attente',
      badge: 'INSTANTANÉ',
      badgeColor: Color(0xFF10B981),
      gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
      icon: Icons.phone_android_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _indexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          child: SizedBox(
            height: 104,
            child: PageView.builder(
              controller: _controller,
              itemCount: _banners.length,
              onPageChanged: (idx) => _indexNotifier.value = idx,
              itemBuilder: (context, index) {
                final b = _banners[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: b.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: b.badgeColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b.badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              b.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFF7ED),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(b.icon, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _indexNotifier,
          builder: (context, currentIndex, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentIndex == i ? 18 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: currentIndex == i ? AppTokens.primary500 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
