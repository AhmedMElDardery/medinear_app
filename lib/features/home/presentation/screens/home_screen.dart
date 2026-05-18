import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medinear_app/core/localization/app_localizations.dart';
import 'package:medinear_app/core/routes/routes.dart';
import 'package:medinear_app/features/auth/presentation/auth_provider.dart';
import 'package:medinear_app/features/home/presentation/provider/home_provider.dart';
import 'package:medinear_app/features/home/presentation/widgets/ads_slider.dart';
import 'package:medinear_app/features/home/presentation/widgets/home_header.dart';
import 'package:medinear_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:medinear_app/features/home/presentation/widgets/medicine_card.dart';
import 'package:medinear_app/features/home/presentation/widgets/pharmacy_card.dart';
import 'package:medinear_app/features/pharmacy/presentation/screens/pharmacy_screen.dart';
import 'package:medinear_app/features/profile/view_models/profile_provider.dart';
import 'package:medinear_app/features/visual_search/presentation/screens/visual_search_screen.dart';
import 'package:medinear_app/features/home/domain/entities/category_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    Future.microtask(() {
      ref.read(homeProvider).loadHome();
      ref.read(profileProvider).fetchProfile();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.translate("greeting_morning");
    if (hour < 17) return AppLocalizations.of(context)!.translate("greeting_afternoon");
    return AppLocalizations.of(context)!.translate("greeting_evening");
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(homeProvider);
    final auth = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(provider, auth, profile, context),
      ),
      floatingActionButton: _buildFABs(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFABs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 📷 Camera Button
          _CameraFab(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VisualSearchScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // 🤖 AI Chatbot Button
          _AIChatFab(
            onTap: () => context.push(AppRoutes.chats),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(HomeProvider provider, AuthProvider auth,
      ProfileProvider profile, BuildContext context) {
    // ⏳ Loading
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    // 🔴 Error
    if (provider.errorMessage != null) {
      return _buildErrorState(provider);
    }

    // 🟢 Content — trigger fade in
    if (!_fadeController.isCompleted) {
      _fadeController.forward();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await provider.loadHome();
          if (context.mounted) {
            await profile.fetchProfile();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              const HomeHeader(),

              /// GREETING + USER INFO
              _buildGreetingSection(auth, profile, provider),

              /// SEARCH BAR
              HomeSearchBar(
                query: provider.searchQuery,
                onChanged: (query) => provider.search(query),
                onClear: () => provider.clearSearch(),
              ),

              /// QUICK STATS
              _buildQuickStats(provider),

              /// ADS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: AdsSlider(ads: provider.ads),
              ),

              const SizedBox(height: 24),

              /// CATEGORIES
              if (provider.categories.isNotEmpty) ...[
                _buildSectionHeader(
                  title: AppLocalizations.of(context)!.translate("categories"),
                  icon: Icons.category_rounded,
                  count: provider.categories.length,
                  onSeeAll: () => context.push('/categories'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.categories.length > 5 ? 5 : provider.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 20),
                    itemBuilder: (context, index) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final cat = provider.categories[index];
                      return _buildCategoryItem(cat, isDark);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              /// NEAR PHARMACIES
              _buildSectionHeader(
                title: AppLocalizations.of(context)!.translate("near_pharmacies"),
                icon: Icons.local_pharmacy_rounded,
                count: provider.pharmacies.length,
                onSeeAll: () {
                  final mapProv = ref.read(mapProvider);
                  if (mapProv.isMedicineSearch) mapProv.toggleSearchType(false);
                  mapProv.search(""); 
                  ref.read(navigationProvider).changeIndex(3);
                },
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 175,
                child: provider.filteredPharmacies.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.local_pharmacy_outlined,
                        message: provider.searchQuery.isNotEmpty
                            ? AppLocalizations.of(context)!.translate(
                              "no_pharmacies_match",
                              params: {"query": provider.searchQuery},
                            )
                            : AppLocalizations.of(context)!.translate("no_pharmacies_nearby")
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsetsDirectional.only(start: 16, end: 100),
                        itemCount: provider.filteredPharmacies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final pharmacy = provider.filteredPharmacies[index];
                          return PharmacyCard(
                            pharmacy: pharmacy,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PharmacyScreen(
                                  pharmacyId: pharmacy.id
                                      .toString(), // 🚀 ضفنا الـ ID بتاع الصيدلية هنا
                                  pharmacyName: pharmacy.name,
                                  doctorName: pharmacy
                                      .name, // زي ما هي مكتوبة عندك في الكود
                                  pharmacyImage: pharmacy.image,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 24),

              /// NEAR MEDICINES
              _buildSectionHeader(
                title: AppLocalizations.of(context)!.translate("near_medicines"),
                icon: Icons.medication_rounded,
                count: provider.medicines.length,
                onSeeAll: () {
                  final mapProv = ref.read(mapProvider);
                  if (!mapProv.isMedicineSearch) mapProv.toggleSearchType(true);
                  mapProv.search("");
                  ref.read(navigationProvider).changeIndex(3);
                },
              ),

              const SizedBox(height: 12),

              /// MEDICINES LIST
              SizedBox(
                height: 210,
                child: provider.filteredMedicines.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.medication_outlined,
                        message: provider.searchQuery.isNotEmpty
                            ? AppLocalizations.of(context)!.translate(
                              "no_mdicines_match",
                              params: {"query": provider.searchQuery}
                            )
                            : AppLocalizations.of(context)!.translate("no_medicines_nearby"),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsetsDirectional.only(start: 16, end: 100),
                        itemCount: provider.filteredMedicines.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => MedicineCard(
                            medicine: provider.filteredMedicines[index]),
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(
      AuthProvider auth, ProfileProvider profile, HomeProvider provider) {
    // الاسم الكامل: من البروفايل أولاً، وإلا من الأوث
    final fullName = profile.user?.name ?? auth.currentUser?.name ?? AppLocalizations.of(context)!.translate("default_user");

    // الصورة: من البروفايل أولاً (photoUrl أو avatar)، وإلا من الأوث
    final photoUrl = profile.user?.photoUrl ??
        profile.user?.avatar ??
        auth.currentUser?.imageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => ref.read(navigationProvider).changeIndex(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
          /// Avatar with border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      fullName.isNotEmpty
                          ? fullName.substring(0, 1).toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: -0.5,
                  ),
                ),
                if (provider.currentLocation != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 12, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          provider.currentLocationName ?? AppLocalizations.of(context)!.translate("locating"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.local_pharmacy_rounded,
            label: "${provider.pharmacies.length} Pharmacies",
            color: Theme.of(context).colorScheme.primary,
            bgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.medication_rounded,
            label: "${provider.medicines.length} Medicines",
            color: Colors.blue,
            bgColor: Colors.blue.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.near_me_rounded,
            label: AppLocalizations.of(context)!.translate("nearby"),
            color: Colors.orange,
            bgColor: Colors.orange.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child:  Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate("see_all"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryEntity cat, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Todo: Navigate to specific category later
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(8), // 🚀 Reduced padding to make image larger
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: cat.image,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => Icon(
                    Icons.medication_liquid_rounded,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
                size: 30,
                color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.translate("loading_title"),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.translate("loading_subtitle"),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(HomeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.location_off_rounded,
                  size: 52, color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.translate("error_title"),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.errorMessage ??
                  AppLocalizations.of(context)!.translate("error_message"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => provider.loadHome(),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label:  Text(
                  AppLocalizations.of(context)!.translate("try_again"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 🤖 AI Chatbot FAB
// ─────────────────────────────────────────
class _AIChatFab extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const _AIChatFab({required this.onTap});

  @override
  ConsumerState<_AIChatFab> createState() => _AIChatFabState();
}

class _AIChatFabState extends ConsumerState<_AIChatFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 6, end: 18).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        context.push(AppRoutes.chatbot);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, child) => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00D68F), Theme.of(context).colorScheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  blurRadius: _glowAnim.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 📷 Camera FAB
// ─────────────────────────────────────────
class _CameraFab extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const _CameraFab({required this.onTap});

  @override
  ConsumerState<_CameraFab> createState() => _CameraFabState();
}

class _CameraFabState extends ConsumerState<_CameraFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap, // Fix: Actually trigger the callback
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black26
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 26,
          ),
        ),
      ),
    );
  }
}