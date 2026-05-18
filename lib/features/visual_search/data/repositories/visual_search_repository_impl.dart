import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/visual_search_repository.dart';
import '../datasources/visual_search_local_data_source.dart';
import '../datasources/visual_search_remote_data_source.dart';
import '../models/search_history_model.dart';

class VisualSearchRepositoryImpl implements VisualSearchRepository {
  final VisualSearchLocalDataSource localDataSource;
  final VisualSearchRemoteDataSource remoteDataSource;

  VisualSearchRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<File?> pickImage(ImageSource source) {
    return localDataSource.pickImage(source);
  }

  @override
  Future<File?> cropImage(File imageFile) {
    return localDataSource.cropImage(imageFile);
  }

  @override
  Future<String> extractText(File imageFile) {
    return localDataSource.extractText(imageFile);
  }

  @override
  Future<Map<String, dynamic>?> searchMedication(String query) {
    return remoteDataSource.searchMedication(query);
  }

  @override
  Future<void> saveSearchHistory(SearchHistoryModel history) {
    return localDataSource.saveSearchHistory(history);
  }

  @override
  Future<List<SearchHistoryModel>> getSearchHistory() {
    return localDataSource.getSearchHistory();
  }

  @override
  Future<void> deleteSearchHistory(dynamic key) {
    return localDataSource.deleteSearchHistory(key);
  }
}
