import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/user_model.dart';
import '../data/datasources/profile_remote_data_source.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRemoteDataSource _dataSource = ProfileRemoteDataSource();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // جلب البيانات أول ما التطبيق يفتح
  Future<void> fetchProfile() async {
    if (_user != null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _dataSource.getUserProfile();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Profile Error: $_errorMessage");
    }
    _isLoading = false;
    notifyListeners();
  }

  // 🚀 دالة اختيار ورفع الصورة (بالتعديل الأخير)
  // 🚀 دالة اختيار ورفع الصورة (الاعتماد الكلي على رسالة الباك إند)
// 🚀 دالة اختيار ورفع الصورة (مع ضغط الصورة محلياً والاعتماد الكلي على رسالة الباك إند)
  Future<void> pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // 🚀 السحر هنا: بنطلب من الفلاتر يضغط الصورة ويصغر أبعادها قبل ما يرجعها عشان تترفع طلقة
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // ضغط الجودة لـ 50% (مش هتبان في البروفايل إنها قلت)
      maxWidth: 800, // أقصى عرض 800 بيكسل
      maxHeight: 800, // أقصى طول 800 بيكسل
    );

    if (image != null && _user != null) {
      File newImage = File(image.path);

      // 1. نعرض الصورة فوراً لليوزر على الشاشة (للسرعة)
      File? oldImage = _user!.profileImage;
      _user!.profileImage = newImage;
      notifyListeners();

      // 2. نرفع الصورة للسيرفر في الخلفية
      try {
        bool success = await _dataSource.updateProfileImage(newImage);
        if (success && context.mounted) {
          // 🚀 1. نقفل أي رسالة قديمة
          ScaffoldMessenger.of(context).clearSnackBars();

          // 🚀 2. رسالة النجاح الاحترافية (Premium Success Banner)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 10, // Shadow خفيف يرفعها عن الشاشة
              backgroundColor: const Color(
                  0xFF34C759), // لون أخضر مريح وشيك جداً (Apple Success Green)
              behavior: SnackBarBehavior.floating,
              // تطفو فوق شريط التنقل السفلي بشكل واضح
              margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Row(
                children: const [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 28), // أيقونة صح شيك
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Profile photo updated successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800, // خط عريض وواضح
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        // 3. لو السيرفر رفض (عشان الحجم أو أي سبب)، نرجع الصورة القديمة
        _user!.profileImage = oldImage;
        notifyListeners();

        // 🚀 السحر التاني: بنطبع رسالة السيرفر زي ما هي بالظبط (e.toString)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
          ));
        }
      }
    }
  }

  //  دالة التحديث في الخلفية (اللي بتمنع التهنيج)
  //  دالة التحديث في الخلفية (مع إظهار رسائل الخطأ من الباك إند)
  //  دالة التحديث في الخلفية (مع إظهار رسائل الخطأ من الباك إند)
  Future<void> updateData(
      BuildContext context, String key, String value) async {
    if (_user == null) return;

    String cleanValue = value.trim();
    if (cleanValue.isEmpty) return;

    String oldName = _user!.name;
    String oldPhone = _user!.phone;

    Map<String, dynamic> dataToSend = {};

    if (key == 'Name') {
      _user!.name = cleanValue;
      dataToSend['name'] = cleanValue;
    } else if (key == 'Phone') {
      _user!.phone = cleanValue;
      dataToSend['phone'] = cleanValue;
    }

    notifyListeners();

    try {
      // 🚀 بنبعت الحقل اللي اتغير بس عشان الباك إند ميضربش Validation على الحقول الفاضية
      await _dataSource.updateProfile(dataToSend);
      // لو نجح مش هنعمل حاجة عشان إنت قولت مش عايز رسالة خضرا والنافذة بتقفل طلقة
    } catch (e) {
      // 🚀 لو السيرفر رفض (زي إن الاسم أقل من حرفين)، نرجع الداتا القديمة
      _user!.name = oldName;
      _user!.phone = oldPhone;
      notifyListeners();

      // 🚀 ونطبع رسالة السيرفر زي ما هي بالظبط لليوزر
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ));
      }
    }
  }

  // مسح البيانات عند تسجيل الخروج
  void clearProfile() {
    _user = null;
    notifyListeners();
  }
}
