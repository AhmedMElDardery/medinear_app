import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

import '../widgets/notification_item_widget.dart';

// The notificationsProvider is now defined in global_providers.dart

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = ref.watch(notificationsProvider);
    final notifications = provider.displayedNotifications;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.primaryColor.withOpacity(0.05),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    theme.primaryColor.withOpacity(0.05),
                    theme.scaffoldBackgroundColor,
                  ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: provider.isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: provider.refresh,
                    color: theme.primaryColor,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          pinned: true,
                          leading: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CustomBackButton(color: theme.textTheme.bodyLarge?.color),
                          ),
                          expandedHeight: 120,
                          flexibleSpace: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                color: isDark 
                                  ? Colors.black.withValues(alpha: 0.2) 
                                  : Colors.white.withValues(alpha: 0.2),
                                child: FlexibleSpaceBar(
                                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                                  title: Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildFilterButton(context, ref, 'All', theme.primaryColor, isDark),
                                const SizedBox(width: 12),
                                _buildFilterButton(context, ref, 'Unread', theme.primaryColor, isDark),
                              ],
                            ),
                          ),
                        ),
                        if (notifications.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(theme.textTheme.bodyMedium?.color),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == notifications.length) {
                                    return _buildLoadMoreButton(context, ref, theme.primaryColor);
                                  }

                                  final item = notifications[index];
                                  final delay = index * 100; // Staggered delay

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 50 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Dismissible(
                                      key: Key(item.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 24),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
                                      ),
                                      onDismissed: (_) {
                                        final deletedItem = provider.deleteItem(item.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Notification deleted'),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            action: SnackBarAction(
                                              label: 'UNDO',
                                              textColor: theme.primaryColorLight,
                                              onPressed: () {
                                                if (deletedItem != null) provider.restoreItem(deletedItem);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: NotificationItemWidget(
                                        item: item,
                                        onTap: () => provider.markAsRead(item.id),
                                      ),
                                    ),
                                  );
                                },
                                childCount: notifications.length + (provider.hasMoreItems ? 1 : 0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomActionArea(context, ref, theme.primaryColor, theme.cardColor),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, WidgetRef ref, String text,
      Color activeColor, bool isDark) {
    final provider = ref.watch(notificationsProvider);
    bool isSelected = provider.currentFilter == text;
    return GestureDetector(
      onTap: () => provider.setFilter(text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).dividerColor.withOpacity(isDark ? 0.3 : 0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(
      BuildContext context, WidgetRef ref, Color color) {
    final provider = ref.read(notificationsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Center(
        child: TextButton.icon(
          onPressed: provider.loadMore,
          icon: Icon(Icons.expand_more, color: color),
          label: Text('Load More',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color? textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 40, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No notifications',
              style: TextStyle(
                  color: textColor ?? Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea(
      BuildContext context, WidgetRef ref, Color color, Color backgroundColor) {
    final provider = ref.read(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : color.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              provider.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All marked as read')));
            },
            icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
            label: const Text('Mark All as Read',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 4,
              shadowColor: color.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
