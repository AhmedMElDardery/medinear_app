import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/visual_search_repository.dart';
import '../../domain/usecases/visual_search_usecases.dart';
import '../../data/models/search_history_model.dart';

enum VisualSearchState { initial, loading, success, error }

class VisualSearchProvider extends ChangeNotifier {
  final VisualSearchRepository repository;
  final ExtractTextUseCase extractTextUseCase;
  final SearchMedicationUseCase searchMedicationUseCase;
  final ParsePrescriptionUseCase parsePrescriptionUseCase;
  final CheckDrugInteractionsUseCase checkDrugInteractionsUseCase;
  final IdentifyPillUseCase identifyPillUseCase;
  final CheckCounterfeitUseCase checkCounterfeitUseCase;
  final CheckFoodInteractionUseCase checkFoodInteractionUseCase;

  VisualSearchProvider({
    required this.repository,
    required this.extractTextUseCase,
    required this.searchMedicationUseCase,
    required this.parsePrescriptionUseCase,
    required this.checkDrugInteractionsUseCase,
    required this.identifyPillUseCase,
    required this.checkCounterfeitUseCase,
    required this.checkFoodInteractionUseCase,
  }) {
    loadHistory();
  }

  VisualSearchState _state = VisualSearchState.initial;
  VisualSearchState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<SearchHistoryModel> _history = [];
  List<SearchHistoryModel> get history => _history;

  Map<String, dynamic>? _searchResult;
  Map<String, dynamic>? get searchResult => _searchResult;

  List<Map<String, dynamic>>? _prescriptionResult;
  List<Map<String, dynamic>>? get prescriptionResult => _prescriptionResult;

  Map<String, dynamic>? _pillResult;
  Map<String, dynamic>? get pillResult => _pillResult;

  Map<String, dynamic>? _counterfeitResult;
  Map<String, dynamic>? get counterfeitResult => _counterfeitResult;

  String? _foodInteractionResult;
  String? get foodInteractionResult => _foodInteractionResult;

  File? _currentImage;
  File? get currentImage => _currentImage;

  bool _isCheckingInteractions = false;
  bool get isCheckingInteractions => _isCheckingInteractions;

  String? _interactionsResult;
  String? get interactionsResult => _interactionsResult;

  void _setState(VisualSearchState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    try {
      final data = await repository.getSearchHistory();
      // Sort descending by timestamp
      data.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _history = data;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> deleteHistoryItem(SearchHistoryModel item) async {
    try {
      await repository.deleteSearchHistory(item.key);
      _history.remove(item);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting history item: $e");
    }
  }

  Future<void> startVisualSearch(ImageSource source) async {
    try {
      _setState(VisualSearchState.loading);
      _errorMessage = '';
      _searchResult = null;
      _prescriptionResult = null;

      // 1. Pick Image
      final image = await repository.pickImage(source);
      if (image == null) {
        _setState(VisualSearchState.initial);
        return;
      }

      // 2. Crop Image
      final cropped = await repository.cropImage(image);
      if (cropped == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      _currentImage = cropped;

      // 3. Extract Text (OCR)
      final text = await extractTextUseCase.execute(cropped);
      if (text.trim().isEmpty) {
        _errorMessage = 'لم نتمكن من التعرف على أي نص. يرجى التقاط صورة أوضح.';
        _setState(VisualSearchState.error);
        return;
      }

      // 4. Search Medication
      final result = await searchMedicationUseCase.execute(text);
      if (result != null) {
        _searchResult = result;
        
        // 5. Save to History
        final historyItem = SearchHistoryModel(
          text: text,
          imagePath: cropped.path,
          timestamp: DateTime.now(),
        );
        await repository.saveSearchHistory(historyItem);
        await loadHistory();

        _setState(VisualSearchState.success);
      } else {
        _errorMessage = 'لم يتم العثور على نتائج للنص: $text';
        _setState(VisualSearchState.error);
      }
    } catch (e) {
      _errorMessage = e.toString().contains("No medication") 
          ? 'لم يتم العثور على الدواء' 
          : 'حدث خطأ غير متوقع: $e';
      _setState(VisualSearchState.error);
    }
  }

  Future<void> startPrescriptionScan(ImageSource source) async {
    try {
      _setState(VisualSearchState.loading);
      _errorMessage = '';
      _searchResult = null;
      _prescriptionResult = null;

      // 1. Pick Image
      final image = await repository.pickImage(source);
      if (image == null) {
        _setState(VisualSearchState.initial);
        return;
      }

      // 2. Crop Image (Optional for prescription, but kept to let user crop the medication list)
      final cropped = await repository.cropImage(image);
      if (cropped == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      _currentImage = cropped;

      // 3. Extract Text
      final text = await extractTextUseCase.execute(cropped);
      if (text.trim().isEmpty) {
        _errorMessage = 'لم نتمكن من التعرف على أي نص في الروشتة.';
        _setState(VisualSearchState.error);
        return;
      }

      // 4. Parse with Gemini
      final medications = await parsePrescriptionUseCase.execute(text);
      
      if (medications.isNotEmpty) {
        _prescriptionResult = medications;
        
        // Save to history
        final historyItem = SearchHistoryModel(
          text: 'روشتة: ${medications.length} أدوية',
          imagePath: cropped.path,
          timestamp: DateTime.now(),
        );
        await repository.saveSearchHistory(historyItem);
        await loadHistory();

        _setState(VisualSearchState.success);
      } else {
        _errorMessage = 'لم يتعرف الذكاء الاصطناعي على أدوية واضحة في هذه الروشتة.';
        _setState(VisualSearchState.error);
      }
    } catch (e) {
      _errorMessage = e.toString().contains("No medication") 
          ? 'لم يتم العثور على أدوية' 
          : 'حدث خطأ غير متوقع أثناء تحليل الروشتة: $e';
      _setState(VisualSearchState.error);
    }
  }

  void _resetResults() {
    _searchResult = null;
    _prescriptionResult = null;
    _pillResult = null;
    _counterfeitResult = null;
    _foodInteractionResult = null;
    _interactionsResult = null;
    _isCheckingInteractions = false;
  }

  Future<void> startPillIdentification(ImageSource source) async {
    try {
      _setState(VisualSearchState.loading);
      _errorMessage = '';
      _resetResults();

      final image = await repository.pickImage(source);
      if (image == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      final cropped = await repository.cropImage(image);
      if (cropped == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      _currentImage = cropped;

      final result = await identifyPillUseCase.execute(cropped);
      _pillResult = result;
      _setState(VisualSearchState.success);

      // Save History
      await repository.saveSearchHistory(SearchHistoryModel(
        text: 'فحص حبة دواء: ${result['name']}',
        imagePath: cropped.path,
        timestamp: DateTime.now(),
      ));
      await loadHistory();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(VisualSearchState.error);
    }
  }

  Future<void> startCounterfeitCheck(ImageSource source) async {
    try {
      _setState(VisualSearchState.loading);
      _errorMessage = '';
      _resetResults();

      final image = await repository.pickImage(source);
      if (image == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      final cropped = await repository.cropImage(image);
      if (cropped == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      _currentImage = cropped;

      final result = await checkCounterfeitUseCase.execute(cropped);
      _counterfeitResult = result;
      _setState(VisualSearchState.success);

      await repository.saveSearchHistory(SearchHistoryModel(
        text: 'كشف غش: ${result['is_authentic'] ? 'أصلي' : 'مشتبه به'}',
        imagePath: cropped.path,
        timestamp: DateTime.now(),
      ));
      await loadHistory();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(VisualSearchState.error);
    }
  }

  Future<void> startFoodInteractionCheck(ImageSource source) async {
    try {
      _setState(VisualSearchState.loading);
      _errorMessage = '';
      _resetResults();

      final image = await repository.pickImage(source);
      if (image == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      final cropped = await repository.cropImage(image);
      if (cropped == null) {
        _setState(VisualSearchState.initial);
        return;
      }
      _currentImage = cropped;

      final result = await checkFoodInteractionUseCase.execute(cropped);
      _foodInteractionResult = result;
      _setState(VisualSearchState.success);

      await repository.saveSearchHistory(SearchHistoryModel(
        text: 'تحليل طعام / مكمل',
        imagePath: cropped.path,
        timestamp: DateTime.now(),
      ));
      await loadHistory();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(VisualSearchState.error);
    }
  }

  Future<void> checkInteractions() async {
    if (_prescriptionResult == null || _prescriptionResult!.isEmpty) return;
    
    try {
      _isCheckingInteractions = true;
      _interactionsResult = null;
      notifyListeners();

      final result = await checkDrugInteractionsUseCase.execute(_prescriptionResult!);
      _interactionsResult = result;
    } catch (e) {
      _interactionsResult = 'حدث خطأ أثناء فحص التعارضات. يرجى المحاولة لاحقاً.';
    } finally {
      _isCheckingInteractions = false;
      notifyListeners();
    }
  }

  void reset() {
    _state = VisualSearchState.initial;
    _errorMessage = '';
    _currentImage = null;
    _resetResults();
    notifyListeners();
  }
}
