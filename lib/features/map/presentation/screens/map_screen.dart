import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import '../provider/map_provider.dart';
import '../widgets/pharmacy_card.dart';
import 'package:medinear_app/features/pharmacy/presentation/screens/pharmacy_screen.dart';
import 'package:medinear_app/core/localization/app_localizations.dart';
import 'package:medinear_app/core/widgets/app_shimmer.dart';
import 'package:medinear_app/core/widgets/custom_empty_state.dart';
import 'package:medinear_app/features/cart/data/datasources/cart_remote_data_source.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String medicine;
  const MapScreen({super.key, required this.medicine});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final CartRemoteDataSource _cartDataSource = CartRemoteDataSource();
  final Set<String> _addingToCart = {}; // 🆕 لتتبع الأزرار الجاري تحميلها

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider = ref.read(mapProvider);
      await provider.initLocation();

      // تأكد إننا بنحمل البيانات لو مش موجودة
      if (provider.medicineSuggestions.isEmpty) {
        provider.loadSearchData();
      }

      // البحث عن الدواء إذا تم تمريره من شاشة أخرى
      if (widget.medicine.isNotEmpty) {
        _searchController.text = widget.medicine;
        provider.isMedicineSearch = true;
        provider.search(widget.medicine);
      }
    });

    // 🚀 مراقبة الفوكس
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        ref.read(mapProvider).setShowSuggestions(false);
      }
    });

    // 🚀 الفلترة اللحظية (Real-time Filtering)
    _searchController.addListener(() {
      if (mounted) {
        setState(() {}); // بيخلي ويدجت الاقتراحات تعيد بناء نفسها مع كل حرف
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(mapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- Layer 1: Google Map ---
          Positioned.fill(
            child: provider.userLocation == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    style: isDark ? _darkMapStyle : null,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                        target: provider.userLocation!, zoom: 13.5),
                    markers: provider.getMarkers(),
                    circles: provider.getCircles(),
                    onMapCreated: (controller) {
                      if (!provider.mapController.isCompleted) {
                        provider.mapController.complete(controller);
                      }
                    },
                    onTap: (_) {
                      _searchFocusNode.unfocus(); // يقفل الكيبورد والاقتراحات
                      provider.setShowSuggestions(false);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
          ),

          // --- Layer 2: Search Suggestions Overlay ---
          if (provider.showSuggestions)
            _buildSearchSuggestions(provider, isDark),

          // --- Layer 3: Glass Search Header ---
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildGlassSearchHeader(provider, isDark)),

          // --- Layer 4: Floating My Location Button ---
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.42,
            child: FloatingActionButton(
              onPressed: () async {
                if (provider.userLocation != null) {
                  final controller = await provider.mapController.future;
                  controller.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target: provider.userLocation!, zoom: 16.0)));
                }
              },
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(Icons.my_location,
                  color: Theme.of(context).iconTheme.color),
            ),
          ),

          // --- Layer 5: Draggable Bottom Sheet ---
          if (!provider.showSuggestions)
            _buildResultsBottomSheet(provider, isDark),
        ],
      ),
    );
  }

  // 🚀 ويدجت الاقتراحات - تعرض أدوية أو صيدليات حسب نوع البحث
  Widget _buildSearchSuggestions(MapProvider provider, bool isDark) {
    final query = _searchController.text.trim().toLowerCase();

    // 1. فلترة البحث الأخير
    final filteredRecent = query.isEmpty
        ? provider.recentSearches
        : provider.recentSearches
            .where((s) => s.displayText.toLowerCase().contains(query))
            .toList();

    final bool isMedicine = provider.isMedicineSearch;

    // 2a. لو Medicine mode: فلترة الأدوية
    final filteredMedicines = isMedicine
        ? (query.isEmpty
            ? provider.medicineSuggestions
            : provider.medicineSuggestions
                .where((m) => m.name.toLowerCase().contains(query))
                .toList())
        : [];

    // 2b. لو Pharmacy mode: فلترة الصيدليات
    final filteredPharmacies = !isMedicine
        ? (query.isEmpty
            ? provider.pharmacySuggestions
            : provider.pharmacySuggestions
                .where((p) => p.name.toLowerCase().contains(query))
                .toList())
        : [];

    final bool isEmpty = filteredRecent.isEmpty &&
        filteredMedicines.isEmpty &&
        filteredPharmacies.isEmpty;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 130,
      left: 16,
      right: 16,
      bottom: 100,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 20)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: isEmpty
              ? CustomEmptyState(
                  title: 'noSuggestionsMatch'.tr(context),
                  subtitle: "Try adjusting your search criteria.",
                  icon: Icons.search_off_rounded,
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // --- Recent Searches ---
                          if (filteredRecent.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                  query.isEmpty
                                      ? 'recentSearches'.tr(context)
                                      : 'matchingRecent'.tr(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ),
                            ...filteredRecent.map((s) => ListTile(
                                  leading: const Icon(Icons.history, size: 20),
                                  title: Text(s.displayText),
                                  onTap: () {
                                    _searchController.text = s.displayText;
                                    provider.search(s.medicineId?.toString() ??
                                        s.displayText);
                                    _searchFocusNode.unfocus();
                                  },
                                )),
                          ],
                          // --- Medicine Suggestions ---
                          if (isMedicine && filteredMedicines.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                  query.isEmpty
                                      ? 'availableMedicines'.tr(context)
                                      : 'matchingMedicines'.tr(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ),
                            ...filteredMedicines.map((m) => ListTile(
                                  leading: Icon(Icons.medication_outlined,
                                      color: Theme.of(context).colorScheme.primary),
                                  title: Text(m.name),
                                  subtitle: m.categoryName != null
                                      ? Text(m.categoryName!,
                                          style: const TextStyle(fontSize: 10))
                                      : null,
                                  onTap: () {
                                    _searchController.text = m.name;
                                    provider.search(m.id.toString());
                                    _searchFocusNode.unfocus();
                                  },
                                )),
                          ],
                          // --- Pharmacy Suggestions ---
                          if (!isMedicine && filteredPharmacies.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                  query.isEmpty
                                      ? 'nearbyPharmacies'.tr(context)
                                      : 'matchingPharmacies'.tr(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ),
                            ...filteredPharmacies.map((p) => ListTile(
                                  leading: Icon(Icons.storefront,
                                      color: Theme.of(context).colorScheme.primary),
                                  title: Text(p.name),
                                  subtitle: Text(p.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11)),
                                  onTap: () {
                                    _searchController.text = p.name;
                                    provider.search(p.name);
                                    _searchFocusNode.unfocus();
                                  },
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGlassSearchHeader(MapProvider provider, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 15,
              left: 16,
              right: 16),
          child: Column(
            children: [
              Row(
                children: [
                  // 🚀 شيلنا الـ GestureDetector بتاع الدائرة البيضاء وشيلنا الـ SizedBox اللي بعده
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      // 🚀 علامة العدسة في الكيبورد
                      textInputAction: TextInputAction.search,
                      onTap: () {
                        provider.setShowSuggestions(true);
                      },
                      onChanged: (val) {
                        if (!provider.showSuggestions) {
                          provider.setShowSuggestions(true);
                        }
                      },
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          provider.search(val.trim());
                        }
                        _searchFocusNode.unfocus();
                      },
                      decoration: InputDecoration(
                        hintText: provider.isMedicineSearch
                            ? 'searchMedicineHint'.tr(context)
                            : 'searchPharmacyHint'.tr(context),
                        hintStyle: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.grey, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setShowSuggestions(true);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildSearchTypeButton('medicineTab'.tr(context), provider.isMedicineSearch,
                      isDark, () => provider.toggleSearchType(true)),
                  const SizedBox(width: 10),
                  _buildSearchTypeButton('pharmacyTab'.tr(context), !provider.isMedicineSearch,
                      isDark, () => provider.toggleSearchType(false)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTypeButton(
      String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBottomSheet(MapProvider provider, bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.40,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 5,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Column(
            children: [
              Center(
                  child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10)))),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${provider.pharmacies.length} ${'resultsFound'.tr(context)}",
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold)),
                    Icon(Icons.sort, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                        itemCount: 4,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: AppShimmer(width: double.infinity, height: 110),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                        itemCount: provider.pharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = provider.pharmacies[index];
                          final cartKey = '${provider.lastMedicineId}_${pharmacy.id}';
                          final isAdding = _addingToCart.contains(cartKey);
                          return PharmacyCard(
                            item: pharmacy,
                            isMapMode: !(provider.isMedicineSearch &&
                                provider.lastQuery.isNotEmpty),
                            isSelected:
                                provider.selectedPharmacyId == pharmacy.id,
                            onTap: () => provider.selectPharmacy(pharmacy.id),
                            onGoTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PharmacyScreen(
                                  pharmacyId: pharmacy.id.toString(),
                                  pharmacyName: pharmacy.name,
                                  doctorName: pharmacy.name,
                                ),
                              ),
                            ),
                            onNotify: () => provider.notifyApi(pharmacy.id),
                            onAddToCart: isAdding
                                ? null // عشان الزرار مايتضغطش تاني
                                : () => _handleAddToCart(
                                      context: context,
                                      provider: provider,
                                      pharmacyId: pharmacy.id,
                                      pharmacyName: pharmacy.name,
                                      cartKey: cartKey,
                                    ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 دالة الإضافة الحقيقية للـ Cart
  Future<void> _handleAddToCart({
    required BuildContext context,
    required MapProvider provider,
    required String pharmacyId,
    required String pharmacyName,
    required String cartKey,
  }) async {
    final medicineId = provider.lastMedicineId;

    // لو مفيش medicine_id (يعني البحث بالاسم مش بالـ ID)، نوضح للمستخدم
    if (medicineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "يرجى اختيار الدواء من قائمة الاقتراحات لإضافته للسلة"),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // نضيف المفتاح عشان الزرار يبقى disabled أثناء التحميل
    setState(() => _addingToCart.add(cartKey));

    try {
      final success = await _cartDataSource.toggleCartItem(
        medicineId: medicineId,
        pharmacyId: int.parse(pharmacyId),
        quantity: 1,
      );

      if (!mounted) return;

      if (success) {
        // 🆕 تحديث الـ CartProvider عشان الـ badge يتحدث
        ref.read(cartProvider).loadCartPharmacies();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                   child: Text(
                    "${'addedToCart'.tr(context)} $pharmacyName",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text("حدث خطأ، حاول مرة أخرى"),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("فشل الاتصال بالسيرفر"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart.remove(cartKey));
    }
  }
}

// 🚀 Dark Mode JSON String لخرائط جوجل
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1b1b1b"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#373737"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#4e4e4e"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3d3d3d"
      }
    ]
  }
]
''';
