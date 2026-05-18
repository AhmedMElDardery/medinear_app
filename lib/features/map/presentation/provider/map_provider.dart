import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/pharmacy_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../../domain/entities/recent_search_entity.dart';
import '../../domain/repositories/map_repository.dart';

class MapProvider extends ChangeNotifier {
  final MapRepository repository;
  MapProvider(this.repository);

  // --- الحالة (State) ---
  LatLng? userLocation;
  bool isLoading = false;
  List<PharmacyEntity> pharmacies = [];
  String? selectedPharmacyId;

  // 🚀 Cached markers and circles to prevent heavy rebuilds
  Set<Marker> cachedMarkers = {};
  Set<Circle> cachedCircles = {};

  bool isMedicineSearch =
      true; // true = بحث عن دواء | false = بحث عن اسم صيدلية
  bool showSuggestions = false;
  List<RecentSearchEntity> recentSearches = [];
  List<MedicineEntity> medicineSuggestions = [];
  List<PharmacyEntity> pharmacySuggestions = []; // 🆕 اقتراحات الصيدليات

  // 🚀 بنحفظ آخر كلمة بحث عشان لو اليوزر بدل النوع (دواء/صيدلية) نبحث بيها فوراً
  String lastQuery = "";
  int? lastMedicineId; // 🆕 الـ ID الحقيقي للدواء المبحوث عنه

  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  // 1. تهيئة الموقع (GPS + التصاريح)
  Future<void> initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      LocationPermission permission;

      if (!serviceEnabled) {
        debugPrint('⚠️ GPS service disabled - using Cairo fallback');
        userLocation = const LatLng(30.0444, 31.2357);
      } else {
        permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 3));
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 10));
        }

        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied - using Cairo fallback');
          userLocation = const LatLng(30.0444, 31.2357);
        } else {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 5)),
          ).timeout(const Duration(seconds: 6));
          userLocation = LatLng(position.latitude, position.longitude);
          debugPrint(
              '✅ GPS obtained: ${position.latitude}, ${position.longitude}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ GPS error ($e) - using Cairo fallback');
      userLocation = const LatLng(30.0444, 31.2357);
    }

    notifyListeners(); // نعلم الـ UI بالموقع عشان الخريطة تظهر
    await _sendLocationToServer(); // نبعت الموقع للسيرفر في كل الحالات
    await loadInitialPharmacies();
  }

  // 🆕 إرسال موقع اليوزر للسيرفر عشان يتذكره ويقدر يبحث بيه
  Future<void> _sendLocationToServer() async {
    if (userLocation == null) return;
    debugPrint(
        '📤 Sending location to server: lat=${userLocation!.latitude}, lng=${userLocation!.longitude}');
    try {
      await repository.updateUserLocation(
        lat: userLocation!.latitude,
        lng: userLocation!.longitude,
      );
      debugPrint('✅ Location sent to server successfully!');
    } catch (e) {
      debugPrint('⚠️ Failed to send location to server: $e');
    }
  }

  // 2. جلب كل الصيدليات (الحالة الافتراضية عند فتح الشاشة)
  Future<void> loadInitialPharmacies() async {
    isLoading = true;
    notifyListeners();
    try {
      pharmacies = await repository.getAllPharmacies(
        lat: userLocation?.latitude,
        lng: userLocation?.longitude,
      );
      if (pharmacies.isNotEmpty) {
        selectedPharmacyId = pharmacies.first.id;
        // تحريك الكاميرا لأول صيدلية لو الخريطة لسه فاتحة
        _moveCameraTo(LatLng(pharmacies.first.lat, pharmacies.first.lng));
      }
    } catch (e) {
      debugPrint("Load Initial Pharmacies Error: $e");
    } finally {
      isLoading = false;
      _updateMapOverlays();
      notifyListeners();
    }
  }

  // 3. تبديل نوع البحث (دواء / صيدلية)
  void toggleSearchType(bool isMedicine) {
    if (isMedicineSearch == isMedicine) return;

    isMedicineSearch = isMedicine;
    lastQuery = ''; // 🔧 إعادة تعيين البحث السابق عند تبديل النوع
    notifyListeners();

    // 🆕 لو بدّل لصيدلية، نحمل اقتراحات الصيدليات
    if (!isMedicine && pharmacySuggestions.isEmpty) {
      _loadPharmacySuggestions();
    }

    loadInitialPharmacies();
  }

  void setShowSuggestions(bool show) {
    showSuggestions = show;
    if (show) {
      // لو بحث أدوية وما في اقتراحات، نحملها
      if (isMedicineSearch &&
          (recentSearches.isEmpty || medicineSuggestions.isEmpty)) {
        loadSearchData();
      }
      // لو بحث صيدليات وما في اقتراحات، نحملها من الصيدليات الموجودة
      if (!isMedicineSearch && pharmacySuggestions.isEmpty) {
        _loadPharmacySuggestions();
      }
    }
    notifyListeners();
  }

  Future<void> loadSearchData() async {
    try {
      recentSearches = await repository.getRecentSearches();
      medicineSuggestions = await repository.getMedicines();
      notifyListeners();
    } catch (e) {
      debugPrint("Load Search Data Error: $e");
    }
  }

  // 🆕 تحميل اقتراحات الصيدليات من الـ API
  Future<void> _loadPharmacySuggestions() async {
    try {
      if (pharmacies.isNotEmpty) {
        // استخدام الصيدليات المحملة أصلاً
        pharmacySuggestions = List.from(pharmacies);
      } else {
        pharmacySuggestions = await repository.getAllPharmacies(
          lat: userLocation?.latitude,
          lng: userLocation?.longitude,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Load Pharmacy Suggestions Error: $e");
    }
  }

  // 🚀 4. البحث المطور (دواء أو اسم صيدلية)
  Future<void> search(String query) async {
    lastQuery = query.trim();
    // 🆕 لو الـ query رقم، يبقى هو medicine_id
    lastMedicineId = int.tryParse(lastQuery);
    if (lastQuery.isEmpty) {
      lastMedicineId = null;
      await loadInitialPharmacies();
      return;
    }

    showSuggestions = false;
    isLoading = true;
    notifyListeners();

    try {
      // بنبعت الـ isMedicineSearch عشان الـ API يقرر يدور في الأدوية ولا الصيدليات
      pharmacies = await repository.searchMedicine(
        lat: userLocation?.latitude,
        lng: userLocation?.longitude,
        medicine: lastQuery,
        isMedicineSearch: isMedicineSearch,
      );

      // ترتيب حسب الأقرب
      if (userLocation != null && pharmacies.isNotEmpty) {
        pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
      }

      if (pharmacies.isNotEmpty) {
        selectPharmacy(pharmacies.first.id);
      } else {
        selectedPharmacyId = null;
        debugPrint("No results found for: $lastQuery");
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      pharmacies = [];
    } finally {
      isLoading = false;
      _updateMapOverlays();
      notifyListeners();
    }
  }

  Future<void> notifyApi(String pharmacyId) async {
    try {
      await repository.notifyMe(pharmacyId);
    } catch (e) {
      debugPrint("Notify API Error: $e");
    }
  }

  // اختيار صيدلية والتحرك إليها
  void selectPharmacy(String id) async {
    selectedPharmacyId = id;
    _updateMapOverlays();
    notifyListeners();
    try {
      final p = pharmacies.firstWhere((element) => element.id == id);
      _moveCameraTo(LatLng(p.lat, p.lng));
    } catch (e) {
      debugPrint("Select Pharmacy Error: $e");
    }
  }

  // دالة مساعدة لتحريك الكاميرا بسلاسة
  Future<void> _moveCameraTo(LatLng position) async {
    try {
      final controller = await mapController.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15.5, tilt: 45),
      ));
    } catch (e) {
      debugPrint("Camera Animation Error: $e");
    }
  }

  // تحديث الـ Markers و Circles المخزنة
  void _updateMapOverlays() {
    // استخدم لون ثابت لتجنب الاعتماد على الـ Theme هنا
    const primaryColor = Color(0xFF00965E); 

    cachedMarkers = pharmacies
        .map((p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.lat, p.lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  p.id == selectedPharmacyId
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: p.name, snippet: p.address),
              onTap: () => selectPharmacy(p.id),
            ))
        .toSet();

    if (selectedPharmacyId == null || pharmacies.isEmpty) {
      cachedCircles = {};
    } else {
      try {
        final p = pharmacies
            .firstWhere((element) => element.id == selectedPharmacyId);
        cachedCircles = {
          Circle(
            circleId: CircleId(p.id),
            center: LatLng(p.lat, p.lng),
            radius: 400,
            strokeWidth: 2,
            strokeColor: primaryColor,
            fillColor: primaryColor.withValues(alpha: 0.15),
          )
        };
      } catch (e) {
        cachedCircles = {};
      }
    }
  }

  // مخرجات الخريطة (Markers & Circles)
  Set<Marker> getMarkers() => cachedMarkers;
  Set<Circle> getCircles() => cachedCircles;
}
