import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import '../models/search_history_model.dart';

abstract class VisualSearchLocalDataSource {
  Future<File?> pickImage(ImageSource source);
  Future<File?> cropImage(File imageFile);
  Future<String> extractText(File imageFile);
  Future<void> saveSearchHistory(SearchHistoryModel history);
  Future<List<SearchHistoryModel>> getSearchHistory();
  Future<void> deleteSearchHistory(dynamic key);
}

class VisualSearchLocalDataSourceImpl implements VisualSearchLocalDataSource {
  final ImagePicker imagePicker;
  final TextRecognizer textRecognizer;
  final String boxName = 'visual_search_history_box';

  VisualSearchLocalDataSourceImpl({required this.imagePicker})
      : textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<File?> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) throw Exception("Camera permission denied");
    }

    final pickedFile = await imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  @override
  Future<File?> cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Medication Name',
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Medication Name',
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  @override
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  @override
  Future<void> saveSearchHistory(SearchHistoryModel history) async {
    final box = await _getBox();
    await box.add(history);
  }

  @override
  Future<List<SearchHistoryModel>> getSearchHistory() async {
    final box = await _getBox();
    return box.values.toList().cast<SearchHistoryModel>();
  }

  @override
  Future<void> deleteSearchHistory(dynamic key) async {
    final box = await _getBox();
    await box.delete(key);
  }

  Future<Box<SearchHistoryModel>> _getBox() async {
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SearchHistoryModelAdapter());
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<SearchHistoryModel>(boxName);
    }
    return await Hive.openBox<SearchHistoryModel>(boxName);
  }
}
