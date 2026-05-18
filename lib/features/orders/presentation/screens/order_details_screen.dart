import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../widgets/order_header_card.dart';
import '../widgets/order_item_card.dart';
import '../widgets/payment_summary_card.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Orders Details",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            OrderHeaderCard(order: order),
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Order Items",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length, // بنستخدم الطول الحقيقي
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                return OrderItemCard(
                    item: order.items[index]); // بنبعت الصنف الحقيقي
              },
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5)
                ],
              ),
              child: Text(
                "Total Price : ${order.total} EGP", // السعر المحسوب
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor),
              ),
            ),
            const SizedBox(height: 25),
            PaymentSummaryCard(totalOrderPrice: order.total),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
