import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/visual_search_provider.dart';
import '../widgets/image_source_bottom_sheet.dart';
import '../../visual_search_dependency_injection.dart';

class VisualSearchScreen extends ConsumerStatefulWidget {
  const VisualSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends ConsumerState<VisualSearchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(visualSearchChangeNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('البحث البصري', 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, 
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBody(context, provider, isDark, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, VisualSearchProvider provider, bool isDark, ThemeData theme) {
    if (provider.state == VisualSearchState.loading) {
      return _buildLoadingState(theme, isDark);
    }

    if (provider.state == VisualSearchState.error) {
      return _buildErrorState(context, provider, isDark, theme);
    }

    if (provider.state == VisualSearchState.success) {
      return _buildSuccessState(context, provider, isDark, theme);
    }

    return _buildInitialState(context, provider, isDark, theme);
  }

  Widget _buildInitialState(BuildContext context, VisualSearchProvider provider, bool isDark, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        // Premium Scan Card
        SliverToBoxAdapter(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                    : [Colors.white, const Color(0xFFF8FBFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.primary.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    Icon(CupertinoIcons.viewfinder_circle_fill, size: 55, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'التصوير الذكي',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: theme.textTheme.bodyLarge?.color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'اختر نوع الفحص المطلوب:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 24),
                
                // Grid of 4 options
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildScanOptionCard(
                      context,
                      title: 'فحص علبة',
                      icon: CupertinoIcons.cube_box_fill,
                      color: theme.colorScheme.primary,
                      onTap: () async {
                        final source = await ImageSourceBottomSheet.show(context);
                        if (source != null) provider.startVisualSearch(source);
                      },
                    ),
                    _buildScanOptionCard(
                      context,
                      title: 'قراءة روشتة',
                      icon: CupertinoIcons.doc_text_viewfinder,
                      color: Colors.blueAccent,
                      onTap: () async {
                        final source = await ImageSourceBottomSheet.show(context);
                        if (source != null) provider.startPrescriptionScan(source);
                      },
                    ),
                    _buildScanOptionCard(
                      context,
                      title: 'حبة دواء',
                      icon: Icons.medication,
                      color: Colors.purpleAccent,
                      onTap: () async {
                        final source = await ImageSourceBottomSheet.show(context);
                        if (source != null) provider.startPillIdentification(source);
                      },
                    ),
                    _buildScanOptionCard(
                      context,
                      title: 'كشف غش',
                      icon: CupertinoIcons.shield_lefthalf_fill,
                      color: Colors.redAccent,
                      onTap: () async {
                        final source = await ImageSourceBottomSheet.show(context);
                        if (source != null) provider.startCounterfeitCheck(source);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Food Interaction Button (Full Width)
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final source = await ImageSourceBottomSheet.show(context);
                      if (source != null) provider.startFoodInteractionCheck(source);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('محلل الأطعمة والمكملات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // History Section
        SliverFillRemaining(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'العمليات السابقة',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.history.length} عمليات',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: provider.history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(CupertinoIcons.archivebox, size: 40, color: theme.dividerColor),
                              ),
                              const SizedBox(height: 16),
                              Text('لم تقم بأي عمليات فحص بعد', 
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 15)
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: provider.history.length,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 30),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = provider.history[index];
                            return Dismissible(
                              key: Key(item.key.toString()),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) {
                                provider.deleteHistoryItem(item);
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 28),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: isDark ? 0.1 : 0.05)),
                                  boxShadow: isDark ? [] : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'image_${item.imagePath}',
                                          child: Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              image: DecorationImage(
                                                image: FileImage(File(item.imagePath)),
                                                fit: BoxFit.cover,
                                              )
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.text, 
                                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(CupertinoIcons.clock, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat('MMM dd, hh:mm a').format(item.timestamp),
                                                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(CupertinoIcons.arrow_right, size: 18, color: theme.colorScheme.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  strokeWidth: 8,
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(CupertinoIcons.viewfinder, size: 30, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 32),
          Text('جاري التحليل...', 
            style: TextStyle(fontSize: 20, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text('يقوم الذكاء الاصطناعي باستخراج اسم الدواء', 
            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, VisualSearchProvider provider, bool isDark, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.exclamationmark_square_fill, color: theme.colorScheme.error, size: 55),
            ),
            const SizedBox(height: 28),
            Text(
              'تعذر الفحص',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: provider.reset,
                icon: const Icon(CupertinoIcons.refresh_thick, color: Colors.white),
                label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  elevation: 0,
                  shadowColor: theme.colorScheme.error.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScanOptionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, VisualSearchProvider provider, bool isDark, ThemeData theme) {
    final result = provider.searchResult;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 28),
            Text(
              'التطابق ناجح!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 24),
            if (provider.prescriptionResult != null)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.prescriptionResult!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final med = provider.prescriptionResult![index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.medication, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${med['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                              if (med['dosage'] != null && med['dosage'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('${med['dosage']}', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else if (result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                        : [Colors.white, const Color(0xFFF0FDF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Column(
                  children: [
                    Icon(Icons.medication_rounded, size: 30, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('${result['name']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    Text('${result['description']}', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.5)),
                  ],
                ),
              )
            else if (provider.pillResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                        : [Colors.white, const Color(0xFFF3E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.medication, size: 40, color: Colors.purple),
                    const SizedBox(height: 16),
                    Text('${provider.pillResult!['name']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('ثقة التعرف: ${provider.pillResult!['confidence']}', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Text('${provider.pillResult!['description']}', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.5)),
                  ],
                ),
              )
            else if (provider.counterfeitResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: provider.counterfeitResult!['is_authentic'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: provider.counterfeitResult!['is_authentic'] ? Colors.green : Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(provider.counterfeitResult!['is_authentic'] ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill, size: 40, color: provider.counterfeitResult!['is_authentic'] ? Colors.green : Colors.red),
                    const SizedBox(height: 16),
                    Text(provider.counterfeitResult!['is_authentic'] ? 'العلبة تبدو أصلية وموثوقة' : 'تحذير: اشتباه في غش تجاري', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: provider.counterfeitResult!['is_authentic'] ? Colors.green : Colors.red)),
                    const SizedBox(height: 16),
                    Text('${provider.counterfeitResult!['analysis']}', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color, height: 1.5)),
                  ],
                ),
              )
            else if (provider.foodInteractionResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.restaurant, size: 40, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text('تحليل التفاعلات الدوائية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 16),
                    Text('${provider.foodInteractionResult}', style: TextStyle(color: theme.textTheme.bodyMedium?.color, height: 1.6)),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            
            // --- Interactions Check UI ---
            if (provider.prescriptionResult != null && provider.prescriptionResult!.length > 1) ...[
              if (provider.interactionsResult != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: provider.interactionsResult!.contains('آمن') ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: provider.interactionsResult!.contains('آمن') ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.interactionsResult!.contains('آمن') ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_triangle_fill,
                            color: provider.interactionsResult!.contains('آمن') ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'نتيجة الفحص',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: provider.interactionsResult!.contains('آمن') ? Colors.green : Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.interactionsResult!,
                        style: TextStyle(height: 1.5, color: theme.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: provider.isCheckingInteractions ? null : () => provider.checkInteractions(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: provider.isCheckingInteractions
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.white),
                              SizedBox(width: 10),
                              Text('فحص التعارضات الدوائية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            ],
                          ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            // ---------------------------

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  provider.reset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  shadowColor: Colors.green.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('عرض التفاصيل والبدائل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: provider.reset,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('مسح عنصر آخر', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
