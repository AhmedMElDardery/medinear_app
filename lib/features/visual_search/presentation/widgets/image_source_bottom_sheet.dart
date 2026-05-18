import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSourceBottomSheet extends StatelessWidget {
  const ImageSourceBottomSheet({Key? key}) : super(key: key);

  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ImageSourceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'كيف تود إدخال الصورة؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildOption(
              context: context,
              icon: Icons.camera_alt_rounded,
              color: theme.colorScheme.primary,
              title: 'التقاط صورة بالكاميرا',
              onTap: () => Navigator.pop(context, ImageSource.camera),
              isDark: isDark,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context: context,
              icon: Icons.photo_library_rounded,
              color: Colors.purple,
              title: 'اختيار من الاستوديو',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
              isDark: isDark,
              theme: theme,
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }
}
