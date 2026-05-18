import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../data/models/search_history_model.dart';

abstract class VisualSearchRepository {
  Future<File?> pickImage(ImageSource source);
  Future<File?> cropImage(File imageFile);
  Future<String> extractText(File imageFile);
  Future<Map<String, dynamic>?> searchMedication(String query);
  Future<void> saveSearchHistory(SearchHistoryModel history);
  Future<List<SearchHistoryModel>> getSearchHistory();
  Future<void> deleteSearchHistory(dynamic key);
}
