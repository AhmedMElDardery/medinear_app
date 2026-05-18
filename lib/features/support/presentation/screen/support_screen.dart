import 'package:flutter/material.dart';
import 'package:medinear_app/core/localization/translate_helper.dart';
import 'package:medinear_app/features/support/presentation/widgets/support_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.watch(supportProvider).init(context));
  }

  void _showFeedbackBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    int selectedRating = 0;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                    Text(
                      context.tr("feedback_title"),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyLarge?.color,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr("feedback_subtitle"),
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: index < selectedRating
                                ? Colors.amber
                                : theme.dividerColor,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      maxLines: 3,
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: context.tr("feedback_hint"),
                        hintStyle: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selectedRating > 0
                          ? () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      context.tr("feedback_thanks"),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        disabledBackgroundColor: theme.dividerColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(context.tr("submit_feedback"),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: selectedRating > 0
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color)),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  Widget _buildStaticOption(String title, String subtitle, IconData iconData,
      Color primaryColor, int index,
      {VoidCallback? onTap, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: primaryColor.withValues(alpha: 0.12),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Icon(
                      iconData,
                      size: 24,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyLarge?.color,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 13,
                                height: 1.2)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(FaIconData icon, Color color,
      {required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: FaIcon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(supportProvider);
    final itemsCount = provider.items.length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.tr("support_title"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed: () {},
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.more_horiz_rounded,
                    color: theme.iconTheme.color,
                    size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Premium Gradient Top Banner
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage("assets/images/image_support.jpeg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("support_banner_title"),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr("support_banner_subtitle"),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
                child: Container(
                  margin: const EdgeInsets.only(top: 24, bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                child: TextField(
                  style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: context.tr("support_search_hint"),
                    hintStyle: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: theme.textTheme.bodyMedium?.color),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            // Active Order Support Card
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF7A2E0D), const Color(0xFF431407)]
                        : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF431407) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.orange
                                      .withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]),
                      child: Icon(Icons.local_shipping_rounded,
                          color: isDark
                              ? Colors.orangeAccent
                              : Colors.orange,
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr("support_issue"),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.orangeAccent
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(context.tr("support_active_order"),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF7C2D12),
                                  letterSpacing: -0.3)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                      ),
                      child: Text(context.tr("support_get_help"),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),

            // Dynamic provider items
            ...provider.items.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              return SupportCard(item: item, index: index);
            }).toList(),

            const SizedBox(height: 8),

            // Extra static options with premium styling and interactive feedback
            _buildStaticOption(context.tr("support_faq"), context.tr("support_faq_desc"),
                Icons.help_center_rounded, theme.colorScheme.primary, itemsCount,
                theme: theme),
            _buildStaticOption(context.tr("support_feedback"), context.tr("support_feedback_desc"),
                Icons.star_rounded, Colors.amber, itemsCount + 1,
                onTap: () => _showFeedbackBottomSheet(context), theme: theme),
            _buildStaticOption(
                "Privacy Policy",
                "Terms and privacy policy",
                Icons.privacy_tip_rounded,
                theme.colorScheme.secondary,
                itemsCount + 2,
                theme: theme),

            const SizedBox(height: 32),

            // Social Media Row
            Text(context.tr("follow_us"),
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                    FontAwesomeIcons.facebookF, const Color(0xFF1877F2),
                    theme: theme),
                const SizedBox(width: 16),
                _buildSocialIcon(
                    FontAwesomeIcons.instagram, const Color(0xFFE4405F),
                    theme: theme),
                const SizedBox(width: 16),
                _buildSocialIcon(
                    FontAwesomeIcons.twitter, const Color(0xFF1DA1F2),
                    theme: theme),
                const SizedBox(width: 16),
                _buildSocialIcon(
                    FontAwesomeIcons.youtube, const Color(0xFFFF0000),
                    theme: theme),
              ],
            ),
            const SizedBox(height: 48),

            // App Version Footer
            Column(
              children: [
                Text("MediNear App v1.0.0",
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.tr("made_with"),
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const Icon(Icons.favorite_rounded,
                        color: Colors.redAccent, size: 14),
                    Text(context.tr("for_health"),
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
