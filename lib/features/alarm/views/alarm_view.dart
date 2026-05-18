import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:medinear_app/core/theme/app_colors.dart';

// Medication Widgets - تم تغيير المسار لتشير لمكانها الجديد داخل ميزة الأدوية
import '../../medication/views/widgets/dosage_card.dart';
import '../../medication/views/widgets/medication_header_card.dart';
import '../../medication/views/widgets/repeat_card.dart';
import '../../medication/views/widgets/time_details_card.dart';

// تعريف واجهات التحكم في الحالة (ViewModels) - استيراد الـ ViewModel الخاص بالمنبه من مكانه الجديد
import '../view_models/alarm_view_model.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class AlarmView extends ConsumerStatefulWidget {
  const AlarmView({super.key});

  @override
  ConsumerState<AlarmView> createState() => _AlarmViewState();
}

class _AlarmViewState extends ConsumerState<AlarmView> {
  final AlarmViewModel _viewModel = AlarmViewModel();

  @override
  Widget build(BuildContext context) {
    // تحديد لون الخلفية بناءً على وضع الثيم (فاتح/غامق)
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: CustomAppBar(
        backgroundColor: bgColor,
        title: 'Alarm',
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // كارت معلومات الدواء
                MedicationHeaderCard(model: _viewModel.medication),
                const SizedBox(height: 16),

                // كارت تفاصيل الوقت
                TimeDetailsCard(viewModel: _viewModel),
                const SizedBox(height: 16),

                // كارت التكرار
                RepeatCard(viewModel: _viewModel),
                const SizedBox(height: 16),

                // كارت الجرعة
                DosageCard(viewModel: _viewModel),
                const SizedBox(height: 24),

                // أزرار الحفظ والإلغاء (بألوان صريحة وزاهية)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary, // أخضر ميدنير
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          /* تنفيذ الحفظ */
                        },
                        child: const Text(
                          'Save Reminder',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.error, // أحمر صريح للإلغاء
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
