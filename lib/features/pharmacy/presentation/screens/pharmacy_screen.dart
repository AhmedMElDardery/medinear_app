import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medinear_app/core/routes/routes.dart';
import 'package:medinear_app/features/home/domain/entities/medicine_entity.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import '../manager/pharmacy_provider.dart';
import '../widgets/pharmacy_cards.dart';
import '../../../../features/saved_items/presentation/manager/saved_items_provider.dart';
import '../../../../core/widgets/app_shimmer.dart';
import 'package:medinear_app/core/theme/app_colors.dart';

class PharmacyScreen extends ConsumerStatefulWidget {
  final String pharmacyId; // 🚀 ضفنا الـ ID هنا عشان نبعته للـ API
  final String pharmacyName;
  final String doctorName;
  final String? pharmacyImage;

  const PharmacyScreen({
    super.key,
    required this.pharmacyId, // 🚀 خليناه مطلوب
    required this.pharmacyName,
    this.doctorName = 'Al-Noor Pharmacy',
    this.pharmacyImage,
  });
//...

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Countdown timer
  Timer? _timer;
  int _seconds = 10 * 3600 + 20 * 60 + 29; // 10:20:29

  static const _greenLight = Color(0xFFE0F5F2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLocallySaved = ref.read(savedItemsProvider).isPharmacySaved(widget.pharmacyId);
      final pharmacyProv = ref.read(pharmacyProvider);
      
      // 🚀 تصفير البحث القديم عشان لو اليوزر كان بيبحث وخرج، ميفضلش متعلق
      pharmacyProv.search('');
      
      // 🚀 هنا بنقول للبروفايدر: "روح هات بيانات الصيدلية بالـ ID بتاعها"
      pharmacyProv.fetchPharmacyData(widget.pharmacyId, isSavedLocally: isLocallySaved);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _formattedTime {
    final h = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Consumer(
          builder: (context, ref, _) {
            final provider = ref.watch(pharmacyProvider);
            
            if (provider.isLoading) {
              return Column(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: AppShimmer(width: double.infinity, height: 120),
                      ),
                    ),
                  ),
                ],
              );
            }

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      Consumer(builder: (context, ref, child) {
                        final provider = ref.watch(pharmacyProvider);
                        return GestureDetector(
                          onTap: () async {
                            await provider.togglePharmacySave();
                            if (context.mounted) {
                              ref.read(savedItemsProvider).fetchSavedItems(silent: true);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                                provider.isPharmacySaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: Colors.white,
                                size: 28),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final top = constraints.biggest.height;
                        final expandedHeight = 200.0;
                        final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
                        final double collapsePercentage = (top - collapsedHeight) / (expandedHeight - collapsedHeight);
                        final bool isCollapsed = collapsePercentage < 0.4;

                        return FlexibleSpaceBar(
                          centerTitle: true,
                          titlePadding: const EdgeInsets.only(bottom: 16, left: 50, right: 50),
                          title: isCollapsed ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.pharmacyImage != null && widget.pharmacyImage!.isNotEmpty)
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: widget.pharmacyImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  widget.pharmacyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ) : null,
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primaryContainer
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                                child: _buildHeaderContent(isCollapsed: isCollapsed),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFlashSaleBanner(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSearchBar(provider, isDark),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      _buildTabBar(isDark),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(
                    isDark: isDark,
                    isEmpty: provider.filteredMedicines.isEmpty,
                    emptyMsg: 'No medicines found',
                    emptyIcon: Icons.medication_outlined,
                    itemCount: provider.filteredMedicines.length,
                    itemBuilder: (i) {
                      final pharmacyMed = provider.filteredMedicines[i];
                      return GestureDetector(
                        onTap: () {
                          final medEntity = MedicineEntity(
                            id: pharmacyMed.id.toString(),
                            name: pharmacyMed.name,
                            imageUrl: pharmacyMed.image,
                            price: pharmacyMed.price,
                            pharmacyId: widget.pharmacyId,
                            pharmacyName: widget.pharmacyName,
                          );
                          context.push(AppRoutes.medicineDetails, extra: medEntity);
                        },
                        child: PharmacyMedicineCard(
                          medicine: pharmacyMed,
                          onToggleSave: () async {
                            await provider.toggleMedicineSaved(pharmacyMed.id);
                            if (context.mounted) {
                              ref.read(savedItemsProvider).fetchSavedItems(silent: true);
                            }
                          },
                          onToggleNotify: () => provider.toggleMedicineNotify(pharmacyMed.id),
                          onAddToCart: () async {
                            await provider.toggleMedicineInCart(pharmacyMed.id);
                            if (context.mounted) {
                              ref.read(cartProvider).loadCartPharmacies();
                              if (pharmacyMed.inCart) {
                                _showAddedToCart(pharmacyMed.name);
                              } else {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                  _buildList(
                    isDark: isDark,
                    isEmpty: provider.filteredDoctors.isEmpty,
                    emptyMsg: 'No doctors found',
                    emptyIcon: Icons.person_outline_rounded,
                    itemCount: provider.filteredDoctors.length,
                    itemBuilder: (i) => PharmacyDoctorCard(
                      doctor: provider.filteredDoctors[i],
                    ),
                  ),
                  _buildList(
                    isDark: isDark,
                    isEmpty: provider.filteredServices.isEmpty,
                    emptyMsg: 'No services found',
                    emptyIcon: Icons.medical_services_outlined,
                    itemCount: provider.filteredServices.length,
                    itemBuilder: (i) => PharmacyServiceCard(
                      service: provider.filteredServices[i],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────
  Widget _buildHeaderContent({required bool isCollapsed}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isCollapsed ? 0.0 : 1.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.pharmacyImage != null &&
                          widget.pharmacyImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.pharmacyImage!,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          memCacheWidth: 160,
                          placeholder: (context, url) => Icon(
                              Icons.local_pharmacy_rounded,
                              size: 42,
                              color: Theme.of(context).colorScheme.primary),
                          errorWidget: (context, url, error) => Icon(
                              Icons.local_pharmacy_rounded,
                              size: 42,
                              color: Theme.of(context).colorScheme.primary),
                        )
                      : Icon(Icons.local_pharmacy_rounded,
                          size: 42, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pharmacyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Open badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  size: 8, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Open Now',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FLASH SALE BANNER
  // ──────────────────────────────────────────────────────────
  Widget _buildFlashSaleBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⚡', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                'Flash Sale!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8),
              Text('⚡', style: TextStyle(fontSize: 22)),
            ],
          ),

          const SizedBox(height: 4),

          // Subtitle
          const Text(
            'Up to 50% off on all medicines',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Timer box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Time remaining',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────
  Widget _buildSearchBar(PharmacyProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          provider.search(val);
          setState(() {});
        },
        style: TextStyle(
            fontSize: 14, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search medicines, doctors...',
          hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    provider.search('');
                    setState(() {});
                  },
                  child: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 18),
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // TAB BAR
  // ──────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.medication_rounded, size: 17),
            text: 'Medicines',
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
          Tab(
            icon: Icon(Icons.person_rounded, size: 17),
            text: 'Doctors',
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
          Tab(
            icon: Icon(Icons.medical_services_rounded, size: 17),
            text: 'Services',
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // GENERIC LIST
  // ──────────────────────────────────────────────────────────
  Widget _buildList({
    required bool isDark,
    required bool isEmpty,
    required String emptyMsg,
    required IconData emptyIcon,
    required int itemCount,
    required Widget Function(int) itemBuilder,
  }) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(emptyIcon, size: 34, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 14),
            Text(emptyMsg,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Text('Try adjusting your search',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      itemBuilder: (ctx, i) => itemBuilder(i),
    );
  }

  void _showAddedToCart(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_cart_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$name added to cart')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final Widget _tabBar;

  @override
  double get minExtent => 48.0; 
  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, 
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

