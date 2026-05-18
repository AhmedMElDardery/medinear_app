// API calls for AI
import 'package:dio/dio.dart';
import '../models/chat_bot_model.dart';

class ChatBotRemoteDataSource {
  // 🔴 اللينك ده تيم الباك إند هيديهولك
  final String baseUrl = 'https://midnear-api.com/api/chat';
  
  final Dio _dio = Dio();

  // 1. استرجاع الشات القديم
  Future<List<ChatMessage>> getChatHistory(String token) async {
    try {
      final response = await _dio.get(
        '$baseUrl/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Dio بيحول الـ JSON تلقائياً
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. حفظ رسالة
  Future<void> saveMessage(ChatMessage message, String token) async {
    try {
      await _dio.post(
        '$baseUrl/save',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: message.toJson(), // Dio بياخد الـ Map مباشرة
      );
    } catch (e) {
      // صامت عشان ما يوقفش الشات لو النت فصل
    }
  }

  // 3. مسح الشات
  Future<void> clearChat(String token) async {
    try {
      await _dio.delete(
        '$baseUrl/clear',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      // صامت
    }
  }
}