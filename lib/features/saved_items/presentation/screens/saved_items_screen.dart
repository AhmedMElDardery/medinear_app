import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/core/localization/translate_helper.dart';
import '../manager/saved_items_provider.dart';
import '../widgets/saved_item_cards.dart';
import 'package:medinear_app/features/pharmacy/presentation/screens/pharmacy_screen.dart';
import 'package:medinear_app/features/pharmacy/presentation/screens/medicine_details_screen.dart';
import 'package:medinear_app/features/home/domain/entities/medicine_entity.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class SavedItemsScreen extends ConsumerStatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  ConsumerState<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends ConsumerState<SavedItemsScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(savedItemsProvider);
      // 🚀 تصفير البحث القديم عشان ميظهرش داتا غلط لو اليوزر خرج ورجع
      provider.search('');
      provider.fetchSavedItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        showBackButton: false,
        title: context.tr("saved_items_title"),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(savedItemsProvider);
          if (provider.isLoading) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }

          return Column(
            children: [
              // ----------- Search Bar & Sort Button -----------
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: theme.scaffoldBackgroundColor,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => provider.search(val),
                        style:
                            TextStyle(color: theme.textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          hintText: _selectedTab == 0
                              ? context.tr("search_pharmacies")
                              : context.tr("search_medications"),
                          hintStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                          prefixIcon: Icon(Icons.search,
                              color: theme.textTheme.bodyMedium?.color),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.search("");
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          provider.isAscending
                              ? Icons.sort_by_alpha
                              : Icons.sort,
                          color: theme.primaryColor,
                        ),
                        onPressed: () => provider.toggleSort(),
                        tooltip: context.tr("sort"),
                      ),
                    ),
                  ],
                ),
              ),

              // ----------- Tab Buttons -----------
              Container(
                color: theme.scaffoldBackgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildTabButton(
                            '${context.tr("pharmacies_tab")} (${provider.savedPharmaciesCount})',
                            0,
                            theme,
                            provider)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTabButton(
                            '${context.tr("medications_tab")} (${provider.savedMedicationsCount})',
                            1,
                            theme,
                            provider)),
                  ],
                ),
              ),

              // ----------- Body List -----------
              Expanded(
                child: _selectedTab == 0
                    ? _buildPharmaciesList(provider, theme)
                    : _buildMedicationsList(provider, theme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(
      String title, int index, ThemeData theme, SavedItemsProvider provider) {
    final isSelected = _selectedTab == index;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _searchController.clear();
          provider.search("");
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPharmaciesList(SavedItemsProvider provider, ThemeData theme) {
    final pharmacies = provider.pharmacies;
    if (pharmacies.isEmpty) {
      return _emptyState(context.tr("no_saved_pharmacies"), theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pharmacies.length,
      itemBuilder: (itemContext, index) {
        final pharmacy = pharmacies[index];
        return _buildDismissibleItem(
          key: pharmacy.id,
          theme: theme,
          onDismissed: () {
            provider.removePharmacy(pharmacy);
            _showUndoSnackBar('${pharmacy.name} ${context.tr("removed_from_saved")}', theme, () => provider.undoRemovePharmacy(pharmacy));
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PharmacyScreen(
                    pharmacyId: pharmacy.id,
                    pharmacyName: pharmacy.name,
                  ),
                ),
              );
            },
            child: SavedPharmacyCard(
              pharmacy: pharmacy,
              theme: theme,
              onRemove: () {
                provider.removePharmacy(pharmacy);
                _showUndoSnackBar('${pharmacy.name} ${context.tr("removed_from_saved")}', theme, () => provider.undoRemovePharmacy(pharmacy));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicationsList(SavedItemsProvider provider, ThemeData theme) {
    final medications = provider.medications;
    if (medications.isEmpty) {
      return _emptyState(context.tr("no_saved_medications",), theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (itemContext, index) {
        final medication = medications[index];
        return _buildDismissibleItem(
          key: medication.id,
          theme: theme,
          onDismissed: () async {
            final error = await provider.removeMedication(medication);
            if (!mounted) return;
            if (error != null) {
              _showErrorSnackBar(error, theme);
            } else {
              _showUndoSnackBar('${medication.name} ${context.tr("removed_from_saved")}', theme, () async {
                final undoError = await provider.undoRemoveMedication(medication);
                if (!mounted) return;
                if (undoError != null) _showErrorSnackBar(undoError, theme);
              });
            }
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineDetailsScreen(
                    medicine: MedicineEntity(
                      id: medication.id,
                      name: medication.name,
                      imageUrl: medication.image,
                      price: double.tryParse(medication.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                      pharmacyId: medication.pharmacyId,
                      pharmacyName: medication.pharmacyName,
                    ),
                  ),
                ),
              );
            },
            child: SavedMedicationCard(
              medication: medication,
              theme: theme,
              onRemove: () async {
                final error = await provider.removeMedication(medication);
                if (!mounted) return;
                if (error != null) {
                  _showErrorSnackBar(error, theme);
                } else {
                  _showUndoSnackBar('${medication.name} ${context.tr("removed_from_saved")}', theme, () async {
                    final undoError = await provider.undoRemoveMedication(medication);
                    if (!mounted) return;
                    if (undoError != null) _showErrorSnackBar(undoError, theme);
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDismissibleItem(
      {required String key,
      required ThemeData theme,
      required VoidCallback onDismissed,
      required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(key),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              const Icon(Icons.delete_outline, color: Colors.white, size: 30),
        ),
        onDismissed: (_) => onDismissed(),
        child: child,
      ),
    );
  }

  Widget _emptyState(String msg, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border,
              size: 80,
              color: theme.dividerColor),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showUndoSnackBar(String message, ThemeData theme, VoidCallback onUndo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
            label: context.tr("undo"), textColor: theme.primaryColor, onPressed: onUndo),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  void _showErrorSnackBar(String error, ThemeData theme) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
