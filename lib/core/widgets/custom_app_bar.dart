import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const CustomBackButton({super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        size: 24,
        color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
      ),
      splashRadius: 24,
      onPressed: onPressed ?? () {
        if (Navigator.canPop(context)) {
          Navigator.maybePop(context);
        }
      },
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final bool showBackButton;
  final Widget? leading;
  final TextStyle? titleStyle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.showBackButton = true,
    this.leading,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return AppBar(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      scrolledUnderElevation: 0, // Prevents unwanted color changes on scroll
      leading: leading ??
          (showBackButton && Navigator.canPop(context)
              ? const CustomBackButton()
              : null),
      title: Text(
        title,
        style: titleStyle ??
            TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
