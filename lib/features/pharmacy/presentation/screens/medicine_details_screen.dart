import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/localization/translate_helper.dart';
import 'package:medinear_app/features/home/domain/entities/medicine_entity.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:medinear_app/features/saved_items/data/datasources/saved_items_remote_data_source.dart';
import 'pharmacy_screen.dart';

class MedicineDetailsScreen extends ConsumerStatefulWidget {
  final MedicineEntity medicine;

  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  ConsumerState<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends ConsumerState<MedicineDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isSaved = ref.read(savedItemsProvider).medications.any(
          (m) => m.id == widget.medicine.id && m.isSaved);
      setState(() {
        _isFavorite = isSaved;
      });
    });
  }

  Map<String, String> _getPharmacyData(BuildContext context, WidgetRef ref) {
    final med = widget.medicine;
    
    String pId = med.pharmacyId ?? ref.read(pharmacyProvider).currentPharmacyId;
    if (pId.isEmpty || pId == "0") pId = "1";
    
    String pName = "صيدلية ميدينير المركزية";
    String pImage = "";
    
    if (med.pharmacyName != null && med.pharmacyName!.isNotEmpty) {
      pName = med.pharmacyName!;
    }
    
    if (pId != "0") {
      try {
        final pharmacies = ref.read(homeProvider).pharmacies;
        final p = pharmacies.firstWhere((element) => element.id.toString() == pId);
        pName = p.name;
        pImage = p.image;
      } catch (e) {}
    }
    
    return {
      "id": pId,
      "name": pName,
      "image": pImage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gallery = med.gallery != null && med.gallery!.isNotEmpty ? med.gallery! : [med.imageUrl];

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Hero Section
                _buildHeroSection(gallery, isDark),
                
                const SizedBox(height: 24),
                
                // Title and Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        med.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          context.tr("painRelief"),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF00C47A) : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        med.description ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Pharmacy Name Card
                      GestureDetector(
                        onTap: () {
                          final pData = _getPharmacyData(context, ref);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PharmacyScreen(
                                pharmacyId: pData['id']!,
                                pharmacyName: pData['name']!,
                                doctorName: pData['name']!,
                                pharmacyImage: pData['image']!,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 28),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final pImage = _getPharmacyData(context, ref)['image'];
                                  if (pImage != null && pImage.isNotEmpty) {
                                    return Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(pImage),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(Icons.storefront_rounded, size: 24, color: Theme.of(context).colorScheme.primary),
                                    );
                                  }
                                }
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Sold by",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPharmacyData(context, ref)['name'] ?? 'Local Pharmacy',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black87,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      

                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Custom Top App Bar (Floating)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(Icons.arrow_back, () => context.pop(), isDark),
                    _buildIconButton(
                      _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                      () async {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        
                        // Call API in background
                        final pIdStr = widget.medicine.pharmacyId ?? ref.read(pharmacyProvider).currentPharmacyId;
                        final pId = pIdStr.isNotEmpty ? pIdStr : '0';
                        
                        try {
                          bool success = await SavedItemsRemoteDataSource().toggleSaveMedicine(widget.medicine.id, pId);
                          if (!success && context.mounted) {
                             // Revert UI if API fails
                             setState(() {
                               _isFavorite = !_isFavorite;
                             });
                          } else {
                            if (context.mounted) {
                              ref.read(savedItemsProvider).fetchSavedItems(silent: true);
                            }
                          }
                        } catch(e) {
                          if (context.mounted) {
                             setState(() {
                               _isFavorite = !_isFavorite;
                             });
                          }
                        }
                      }, 
                      isDark,
                      color: _isFavorite ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Sticky Bottom Navigation Bar (Price + Cart)
      bottomNavigationBar: _buildBottomBar(med.price, isDark),
    );
  }

  Widget _buildHeroSection(List<String> gallery, bool isDark) {
    return Stack(
      children: [
        // Curved background with subtle gradient
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF12241F), const Color(0xFF1A332C)]
                  : [const Color(0xFFD8F3EC), const Color(0xFFF0FBF8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        
        // Carousel
        Column(
          children: [
            const SizedBox(height: 100), // Space for AppBar
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: gallery.length,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: _currentImageIndex == index ? 0 : 20, // scale effect
                    ),
                    child: CachedNetworkImage(
                      imageUrl: gallery[index],
                      fit: BoxFit.contain,
                      errorWidget: (c, u, e) => const Icon(Icons.medication_liquid, size: 80, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Custom Animated Dots
            if (gallery.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  gallery.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? (isDark ? Colors.white : Colors.black87), size: 22),
      ),
    );
  }

  Widget _buildPropertyRow(String title, String value, IconData icon, bool isDark, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F9F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }

  Widget _buildBottomBar(double price, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), // Floating effect padding
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 25,
                spreadRadius: -5,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final mId = int.tryParse(widget.medicine.id) ?? 0;
                      final pIdStr = widget.medicine.pharmacyId ?? ref.read(pharmacyProvider).currentPharmacyId;
                      int pId = int.tryParse(pIdStr) ?? 0;
                      
                      if (pId == 0) {
                        pId = 1; // Fallback to pharmacy 1 if not specified to allow adding to cart
                      }

                      // 🚀 Add to Cart Logic
                      bool success = await CartRemoteDataSource().toggleCartItem(
                        medicineId: mId,
                        pharmacyId: pId,
                        quantity: 1,
                      );

                      if (context.mounted) {
                        if (success) {
                          ref.read(cartProvider).loadCartPharmacies();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${widget.medicine.name} added to cart',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.all(20),
                              duration: const Duration(seconds: 2),
                              elevation: 10,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text("Failed to add to cart", style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ), 
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.all(20),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.tr("addToCart"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.tr("price"),
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price.toStringAsFixed(0),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          context.tr("egp"),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}