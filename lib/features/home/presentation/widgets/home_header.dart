import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:medinear_app/core/routes/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProv = ref.watch(themeProvider);
    final isDark = themeProv.themeMode == ThemeMode.dark;
    
    // Watch notifications provider to check for unread messages
    final notifProv = ref.watch(notificationsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🌿 Logo + Name
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 38,
                width: 38,
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Medi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: "Near",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // 🌙 Theme Toggle
          _IconBtn(
            icon: isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            onTap: themeProv.toggleTheme,
            isDark: isDark,
          ),

          const SizedBox(width: 4),

          // 💬 Chat
          _IconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => context.push(AppRoutes.chats),
            isDark: isDark,
          ),

          const SizedBox(width: 4),

          // 🔔 Notifications with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconBtn(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push(AppRoutes.notification),
                isDark: isDark,
              ),
              if (notifProv.hasUnread)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends ConsumerWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 24,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
