import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:medinear_app/core/localization/translate_helper.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(homeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: context.tr("all_categories"),
      ),
      body: provider.isLoading 
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final cat = provider.categories[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to specific category later
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        // Image Container takes most of the space naturally
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: CachedNetworkImage(
                              imageUrl: cat.image,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Icon(
                                Icons.medication_liquid_rounded,
                              color: Theme.of(context).unselectedWidgetColor,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            cat.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}