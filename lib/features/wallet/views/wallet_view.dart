import 'package:flutter/material.dart';
import 'package:medinear_app/core/localization/translate_helper.dart';
import 'package:medinear_app/features/medication/data/models/medication_model.dart';
import 'package:medinear_app/features/medication/views/widgets/medication_card.dart';
import 'package:medinear_app/features/wallet/views/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

// 🚨 السطر اللي كان ناقص ومسبب كل المشاكل:
class WalletView extends ConsumerWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // جلب الـ ViewModel
    final viewModel = ref.watch(walletViewModelProvider);

    return Scaffold(
      // ✅ جعل الخلفية ديناميكية تتبع الثيم (Light/Dark)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: CustomAppBar(
        title: context.tr("wallet_title"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // زر الإضافة
            CustomButton(
              label: context.tr("add_new"),
              icon: Icons.add,
              onPressed: () {
                viewModel.addMedication(
                  MedicationModel(
                    id: DateTime.now().toString(),
                    name: context.tr("new_medication"),
                    description: context.tr("default_med_description"),
                    imagePath: 'assets/med1.png',
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // الفلاتر المتفاعلة (ChoiceChips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: viewModel.filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: viewModel.selectedFilter == filter,
                      selectedColor: Theme.of(context).primaryColor,
                      onSelected: (val) => viewModel.updateFilter(filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // القائمة الديناميكية
            Expanded(
              child: viewModel.medications.isEmpty
                  ?  Center(child: Text(context.tr("no_medications")))
                  : ListView.builder(
                      itemCount: viewModel.medications.length,
                      itemBuilder: (context, index) {
                        final med = viewModel.medications[index];
                        return MedicationCard(
                          medication: med,
                          onDelete: () => viewModel.deleteMedication(med.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} // ✅ إغلاق الكلاس
