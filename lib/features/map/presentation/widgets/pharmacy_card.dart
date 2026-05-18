import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 🚀 لازم تضيفها في الـ pubspec.yaml
import '../../domain/entities/pharmacy_entity.dart';

class PharmacyCard extends StatelessWidget {
  final PharmacyEntity item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onNotify;
  final VoidCallback? onAddToCart; // 🆕
  final VoidCallback? onGoTap;
  final bool isMapMode;

  const PharmacyCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onNotify,
    this.onAddToCart,
    this.onGoTap,
    this.isMapMode = false,
  });

  // 🚀 دالة لفتح الروابط الخارجية (خرائط أو اتصال)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.04)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.storefront,
                          color: Theme.of(context).unselectedWidgetColor,
                          size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyLarge?.color)),
                          const SizedBox(height: 4),
                          Text(
                            "${item.address} • ${item.distance.toStringAsFixed(1)} km",
                            style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: accentYellow),
                              const SizedBox(width: 4),
                              const Text("4.8",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              if (!isMapMode) ...[
                                const SizedBox(width: 10),
                                // 🚀 حالة التوفر بناءً على الداتا الحقيقية
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: item.hasMedicine
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    item.hasMedicine
                                        ? "In Stock"
                                        : "Out of Stock",
                                    style: TextStyle(
                                        color: item.hasMedicine
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // --- زرار الاتجاهات (Route) ---
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 🚀 بيفتح خرائط جوجل ويرسم الطريق لموقع الصيدلية
                          _launchURL(
                              'https://www.google.com/maps/search/?api=1&query=${item.lat},${item.lng}');
                        },
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text("Route"),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                            side: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // --- الزرار الثاني (ديناميكي) ---
                    Expanded(
                      child: isMapMode
                          ? ElevatedButton.icon(
                              onPressed: onGoTap ?? onTap,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: Colors.white),
                              label: const Text("Go",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: item.hasMedicine
                                  ? () => _launchURL(
                                      'tel:123456789') // 🚀 حط هنا رقم الصيدلية لو موجود في الـ Entity
                                  : onNotify,
                              icon: Icon(
                                  item.hasMedicine
                                      ? Icons.call
                                      : Icons.notifications_active,
                                  size: 16,
                                  color: Colors.white),
                              label: Text(
                                  item.hasMedicine ? "Call" : "Notify Me",
                                  style: const TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: item.hasMedicine
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                    ),
                  ],
                )
              ],
            ),
            // 🚀 أيقونة السلة (Shopping Cart) تظهر فقط لو العلاج متاح
            if (item.hasMedicine)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black26
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: onAddToCart == null
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.add_shopping_cart_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
