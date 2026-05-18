import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'data/datasources/visual_search_local_data_source.dart';
import 'data/datasources/visual_search_remote_data_source.dart';
import 'data/repositories/visual_search_repository_impl.dart';
import 'domain/repositories/visual_search_repository.dart';
import 'domain/usecases/visual_search_usecases.dart';
import 'presentation/providers/visual_search_provider.dart';
import '../../core/services/gemini_service.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());

final imagePickerProvider = Provider((ref) => ImagePicker());

final visualSearchLocalDataSourceProvider = Provider<VisualSearchLocalDataSource>((ref) {
  return VisualSearchLocalDataSourceImpl(imagePicker: ref.read(imagePickerProvider));
});

final visualSearchRemoteDataSourceProvider = Provider<VisualSearchRemoteDataSource>((ref) {
  return VisualSearchRemoteDataSourceImpl();
});

final visualSearchRepositoryProvider = Provider<VisualSearchRepository>((ref) {
  return VisualSearchRepositoryImpl(
    localDataSource: ref.read(visualSearchLocalDataSourceProvider),
    remoteDataSource: ref.read(visualSearchRemoteDataSourceProvider),
  );
});

final extractTextUseCaseProvider = Provider((ref) {
  return ExtractTextUseCase(ref.read(visualSearchRepositoryProvider));
});

final searchMedicationUseCaseProvider = Provider((ref) {
  return SearchMedicationUseCase(ref.read(visualSearchRepositoryProvider));
});

final parsePrescriptionUseCaseProvider = Provider((ref) {
  return ParsePrescriptionUseCase(ref.read(geminiServiceProvider));
});

final checkDrugInteractionsUseCaseProvider = Provider((ref) {
  return CheckDrugInteractionsUseCase(ref.read(geminiServiceProvider));
});

final identifyPillUseCaseProvider = Provider((ref) {
  return IdentifyPillUseCase(ref.read(geminiServiceProvider));
});

final checkCounterfeitUseCaseProvider = Provider((ref) {
  return CheckCounterfeitUseCase(ref.read(geminiServiceProvider));
});

final checkFoodInteractionUseCaseProvider = Provider((ref) {
  return CheckFoodInteractionUseCase(ref.read(geminiServiceProvider));
});

final visualSearchChangeNotifierProvider = ChangeNotifierProvider<VisualSearchProvider>((ref) {
  return VisualSearchProvider(
    repository: ref.read(visualSearchRepositoryProvider),
    extractTextUseCase: ref.read(extractTextUseCaseProvider),
    searchMedicationUseCase: ref.read(searchMedicationUseCaseProvider),
    parsePrescriptionUseCase: ref.read(parsePrescriptionUseCaseProvider),
    checkDrugInteractionsUseCase: ref.read(checkDrugInteractionsUseCaseProvider),
    identifyPillUseCase: ref.read(identifyPillUseCaseProvider),
    checkCounterfeitUseCase: ref.read(checkCounterfeitUseCaseProvider),
    checkFoodInteractionUseCase: ref.read(checkFoodInteractionUseCaseProvider),
  );
});
