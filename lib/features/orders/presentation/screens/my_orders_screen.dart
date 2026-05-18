import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart'; // 🚀 للتعامل مع الـ Provider
import '../../data/models/order_model.dart';
import '../manager/order_provider.dart'; // 🚀 استدعاء المدير
import '../widgets/order_card.dart';
import 'order_details_screen.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String _searchText = "";
  String _selectedStatus = "All";
  String _selectedPharmacy = "All";

  @override
  void initState() {
    super.initState();
    // 🚀 طلب جلب البيانات أول ما الشاشة تفتح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.watch(orderProvider).fetchOrders();
    });
  }

  // 🚀 دالة الفلترة الذكية (بتطبق على الداتا اللي جاية من البروفايدر)
  List<OrderModel> _getFilteredOrders(List<OrderModel> allOrders) {
    return allOrders.where((order) {
      final matchesSearch = order.pharmacyName
              .toLowerCase()
              .contains(_searchText.toLowerCase()) ||
          order.id.contains(_searchText);
      final matchesStatus =
          _selectedStatus == "All" || order.status == _selectedStatus;
      final matchesPharmacy =
          _selectedPharmacy == "All" || order.pharmacyName == _selectedPharmacy;
      return matchesSearch && matchesStatus && matchesPharmacy;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "My Orders",
      ),
      // 🚀 استخدام Consumer لمراقبة حالة الطلبات
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(orderProvider);
          // جلب القائمة المفلترة
          final filteredOrders = _getFilteredOrders(provider.orders);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. خانة البحث
                TextField(
                  onChanged: (value) => setState(() => _searchText = value),
                  decoration: InputDecoration(
                    hintText: "Search pharmacy or order ID...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. فلاتر الحالة والصيدلية
                Row(
                  children: [
                    Expanded(
                        child: _buildFilterMenu(
                            title: "Filter By Status",
                            currentValue: _selectedStatus,
                            items: ["All", "Completed", "Pending", "Canceled"],
                            onSelected: (val) =>
                                setState(() => _selectedStatus = val))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildFilterMenu(
                            title: "Filter By Pharmacy",
                            currentValue: _selectedPharmacy,
                            items: [
                              "All",
                              "MediNear",
                              "El-Ezaby",
                              "Seif Pharmacy"
                            ],
                            onSelected: (val) =>
                                setState(() => _selectedPharmacy = val))),
                  ],
                ),
                const SizedBox(height: 25),

                // 3. عرض النتائج أو حالة التحميل
                Expanded(
                  child: provider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary))
                      : filteredOrders.isEmpty
                          ? _buildEmptyState(textColor)
                          : ListView.builder(
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                return OrderCard(
                                  order: filteredOrders[index],
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                OrderDetailsScreen(
                                                    order: filteredOrders[
                                                        index])));
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Widgets مساعدة ---

  Widget _buildFilterMenu(
      {required String title,
      required String currentValue,
      required List<String> items,
      required Function(String) onSelected}) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => items
          .map((choice) => PopupMenuItem(value: choice, child: Text(choice)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(currentValue,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color? textColor) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off,
          size: 80, color: Colors.grey.withValues(alpha: 0.5)),
      const SizedBox(height: 15),
      Text("No orders found!",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor))
    ]));
  }
}