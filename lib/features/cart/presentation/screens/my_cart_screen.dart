import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/core/widgets/app_shimmer.dart';
import 'package:medinear_app/features/cart/presentation/manager/cart_provider.dart';
import 'package:medinear_app/features/cart/presentation/widgets/cart_pharmacy_header.dart';
import 'package:medinear_app/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:medinear_app/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class MyCartScreen extends ConsumerStatefulWidget {
  final int pharmacyId;
  final String pharmacyName;

  const MyCartScreen({
    super.key, 
    required this.pharmacyId, 
    required this.pharmacyName
  });

  @override
  ConsumerState<MyCartScreen> createState() => _MyCartScreenState();
}

class _MyCartScreenState extends ConsumerState<MyCartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider).loadPharmacyItems(widget.pharmacyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(cartProvider);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: widget.pharmacyName,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: provider.isLoadingPharmacyItems
                ? ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: AppShimmer(width: double.infinity, height: 120, borderRadius: 16),
                    ),
                  )
                : (provider.currentPharmacyDetails == null || provider.currentPharmacyDetails!.items.isEmpty)
                    ? Center(child: Text("Cart is empty for this pharmacy.", style: TextStyle(color: textColor)))
                    : Column(
                        children: [
                          CartPharmacyHeader(
                            pharmacyName: widget.pharmacyName,
                            location: "",
                            productsCount: provider.currentPharmacyDetails!.totalItems,
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: ListView.builder(
                              itemCount: provider.currentPharmacyDetails!.items.length,
                              itemBuilder: (itemContext, index) {
                                final item = provider.currentPharmacyDetails!.items[index];
                                return CartItemCard(
                                  item: item,
                                  onAdd: () => provider.incrementQuantity(item),
                                  onRemove: () => provider.decrementQuantity(item),
                                  onDelete: () async {
                                    await provider.deleteItem(item);
                                    if (provider.currentPharmacyDetails == null || 
                                        provider.currentPharmacyDetails!.items.isEmpty) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        provider.loadCartPharmacies();
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          SafeArea(
                            child: _buildBottomSummary(
                                context, 
                                provider.currentPharmacyDetails!.totalPrice,
                                provider.currentPharmacyDetails!.items, 
                                cardColor, 
                                textColor),
                          )
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSummary(BuildContext context, double total,
      List<dynamic> items, Color cardColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text("${total.toStringAsFixed(2)} EGP",
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                            subtotal: total,
                            pharmacyItems: List.from(items), 
                            pharmacyName: widget.pharmacyName,
                          )),
                );
              },
              child: const Text("Checkout",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}