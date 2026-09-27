import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/tokens.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: "Gestion Simplifiée",
      description: "Gérez vos opérations de transfert et de crédit de manière fluide et intuitive.",
      image: "assets/images/onboarding/ob1.jpg",
    ),
    _OnboardingData(
      title: "Calcul Automatique",
      description: "Calcul automatique de vos commissions en fonction de vos différents forfaits.",
      image: "assets/images/onboarding/ob2.jpg",
    ),
    _OnboardingData(
      title: "Statistiques Claires",
      description: "Générez des rapports et exportez en PDF pour visualiser l'évolution de vos bénéfices.",
      image: "assets/images/onboarding/ob3.jpg",
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.darkBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  "Passer",
                  style: TextStyle(
                    color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingContent(
                    data: _pages[index],
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTokens.primary500
                              : (isDark ? AppTokens.darkBorder : AppTokens.lightBorderHover),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next / Start Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? "Commencer" : "Suivant",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (_currentPage < _pages.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String image;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}

class _OnboardingContent extends StatelessWidget {
  final _OnboardingData data;
  final bool isDark;

  const _OnboardingContent({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                data.image,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
