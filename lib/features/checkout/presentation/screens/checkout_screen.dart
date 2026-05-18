import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/features/cart/data/models/cart_item_model.dart';
import '../manager/checkout_provider.dart';
import '../widgets/shipping_info_card.dart';
import '../widgets/payment_method_card.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

final checkoutProvider =
    ChangeNotifierProvider.autoDispose<CheckoutProvider>((ref) {
  return CheckoutProvider();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  final double subtotal;
  final List<CartItemModel> pharmacyItems;
  final String pharmacyName;

  const CheckoutScreen({
    super.key,
    required this.subtotal,
    required this.pharmacyItems,
    required this.pharmacyName,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _handleConfirmOrder() async {
    setState(() => _isProcessing = true);

    // ⏳ محاكاة مؤقتة — استبدلها بـ API حقيقي لاحقاً
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // تحديث الـ Cart
    ref.read(cartProvider).loadCartPharmacies();

    // ✅ عرض رسالة النجاح ثم الانتقال للـ Home
    await _showSuccessSheet();
  }

  Future<void> _showSuccessSheet() async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        onDone: () {
          // إغلاق الـ sheet ثم الرجوع لأول شاشة وتغيير الـ tab للـ Home
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(navigationProvider).changeIndex(0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Check Out",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const ShippingInfoCard(),
            const SizedBox(height: 25),
            const PaymentMethodCard(),
            const SizedBox(height: 25),
            _buildOrderSummary(context, cardColor, textColor, widget.subtotal),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isProcessing ? null : _handleConfirmOrder,
                child: _isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text("Confirm Order",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
      BuildContext context, Color cardColor, Color? textColor, double subtotal) {
    const double deliveryFee = 0.0;
    final double grandTotal = subtotal + deliveryFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Order Summary",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]),
          child: Column(
            children: [
              _summaryRow(
                  "Subtotal", "${subtotal.toStringAsFixed(2)} EGP", textColor),
              const SizedBox(height: 10),
              _summaryRow("Delivery Fee", "Free",
                  Theme.of(context).colorScheme.primary,
                  isBold: true),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(thickness: 0.5)),
              _summaryRow("Grand Total", "${grandTotal.toStringAsFixed(2)} EGP",
                  textColor,
                  isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String title, String value, Color? color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                color: isBold ? color : Colors.grey[600],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// ===== Success Bottom Sheet =====
class _SuccessSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _SuccessSheet({required this.onDone});

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),

            // Animated checkmark circle
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: primary, size: 56),
              ),
            ),

            const SizedBox(height: 24),

            Text("Order Placed Successfully! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),

            const SizedBox(height: 10),

            Text(
              "Your order is being prepared.\nWe'll notify you once it's on the way!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text("Back to Home",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
