import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/features/cart/presentation/manager/cart_provider.dart';
import 'package:medinear_app/core/widgets/app_shimmer.dart';
import 'package:medinear_app/core/widgets/custom_empty_state.dart';
import 'my_cart_screen.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class CartPharmaciesScreen extends ConsumerStatefulWidget {
  const CartPharmaciesScreen({super.key});

  @override
  ConsumerState<CartPharmaciesScreen> createState() =>
      _CartPharmaciesScreenState();
}

class _CartPharmaciesScreenState extends ConsumerState<CartPharmaciesScreen> {
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider).loadCartPharmacies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        showBackButton: false,
        title: "Cart",
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(cartProvider);
          if (provider.isLoadingPharmacies) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: AppShimmer(width: double.infinity, height: 90, borderRadius: 16),
              ),
            );
          }

          if (provider.cartPharmacies.isEmpty) {
            return const CustomEmptyState(
              title: "Your Cart is Empty!",
              subtitle: "Looks like you haven't added any items to your cart yet.",
              icon: Icons.shopping_cart_outlined,
            );
          }

          final filteredPharmacies = provider.cartPharmacies.where((p) {
            return p.pharmacyName.toLowerCase().contains(_searchText.toLowerCase());
          }).toList();

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("Select a Pharmacy",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10)
                    ],
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                      suffixIcon: Icon(Icons.filter_list,
                          color: Theme.of(context).colorScheme.primary),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: filteredPharmacies.isEmpty
                    ? Center(
                        child: Text("No pharmacy found!",
                            style: TextStyle(color: textColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        itemCount: filteredPharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = filteredPharmacies[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MyCartScreen(
                                        pharmacyId: pharmacy.id, 
                                        pharmacyName: pharmacy.pharmacyName
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.2),
                                    backgroundImage: pharmacy.image != null
                                        ? NetworkImage(pharmacy.image!)
                                        : null,
                                    child: pharmacy.image == null 
                                      ? Icon(Icons.store, color: Theme.of(context).colorScheme.primary, size: 28)
                                      : null,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(pharmacy.pharmacyName,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: textColor)),
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text("${pharmacy.city} - ${pharmacy.address}",
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}