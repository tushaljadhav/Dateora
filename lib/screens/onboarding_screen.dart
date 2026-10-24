import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      imageAsset: 'assets/illustrations/groceries_hero.png',
      icon: Icons.inventory_2_rounded,
      title: 'Track Expiry Dates',
      subtitle:
          'Never throw away spoiled groceries, expired medicines or skincare products again. Keep all your household dates effortlessly organized in one place.',
      highlight: 'Zero Food Waste',
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      title: 'Smart AI Scanner',
      subtitle:
          'Take a quick photo of the packaging. Our built-in multimodal AI automatically detects the product name, category, and expiry date.',
      highlight: 'Instant AI Autofill',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/illustrations/bell_hero.png',
      icon: Icons.notifications_active_rounded,
      title: 'Smart Reminders',
      subtitle:
          'Receive timely alerts 7 days, 3 days, and on the day of expiry. Reminders fire 100% offline on your device, even without internet or mobile data.',
      highlight: '100% Offline Alerts',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/illustrations/shield_hero.png',
      icon: Icons.shield_rounded,
      title: 'Private & Secure',
      subtitle:
          'No account or login required. All your pantry data, photos and settings are securely stored right on your phone.',
      highlight: 'No Account Needed',
    ),
  ];

  void _finish() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.completeOnboarding();
    AnalyticsService.instance.logOnboardingCompleted();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  void _handleNextOrFinish() {
    if (_currentPage == _pages.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo & Skip button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryStrong],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(Icons.eco_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DATEORA',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryStrong,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                    child: Text(AppLocalizations.of(context)?.onboardingSkip ?? 'Skip'),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration shape or Asset Image
                        if (page.imageAsset != null)
                          Container(
                            height: 190,
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              page.imageAsset!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildIconFallback(page.icon, isDark),
                            ),
                          )
                        else
                          _buildIconFallback(page.icon, isDark),

                        const SizedBox(height: 28),

                        // Pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryStrong.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            page.highlight,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryStrong,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.display.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom controls: Indicator & Next Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                children: [
                  // Smooth page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primaryStrong
                              : theme.colorScheme.outline.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Button
                  PrimaryButton(
                    text: _currentPage == _pages.length - 1
                        ? (AppLocalizations.of(context)?.onboardingGetStarted ?? 'Get Started')
                        : (AppLocalizations.of(context)?.onboardingNext ?? 'Continue'),
                    onPressed: _handleNextOrFinish,
                    icon: _currentPage == _pages.length - 1
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconFallback(IconData icon, bool isDark) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primary.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: AppColors.primaryStrong,
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String? imageAsset;
  final IconData icon;
  final String title;
  final String subtitle;
  final String highlight;

  const _OnboardingPageData({
    this.imageAsset,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlight,
  });
}
