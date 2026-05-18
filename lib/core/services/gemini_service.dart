import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:convert';

class GeminiService {
  // ✅ حط المفتاح بتاعك هنا
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

  final Dio _dio = Dio();

  // ✅ الرولز الشاملة بتاعتنا
  static const String _systemRules = '''
You are a professional medical assistant for the (MidiNear) app.

CRITICAL RULE:
Always respond in the SAME LANGUAGE the user uses. 
- If the user speaks English, you MUST respond in English.
- If the user speaks Arabic, you MUST respond in Arabic.

General Rules:
1. Personality: Professional, smart, friendly, and medical expert.
2. Formatting: Do NOT use asterisks (**). 
3. Arabic Formatting: In Arabic responses, put English medical terms in parentheses like: (Aspirin).
4. Medical Accuracy: Do not suggest painkillers for bacterial infections; advise seeing a doctor.
5. Style: Keep answers very brief, accurate, and in short paragraphs.
''';

  Future<String> getResponse(String prompt) async {
    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
        ),
        data: {
          // ✅ حقن الرولز في عقل Gemini
          "systemInstruction": {
            "parts": [
              {"text": _systemRules}
            ]
          },
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        },
      );

      if (response.statusCode == 200) {
        return response.data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "كود الخطأ: ${response.statusCode}";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("❌ Gemini Server Error: ${e.response?.data}");
        String errorMessage =
            e.response?.data['error']['message'] ?? 'خطأ غير معروف';
        return "رفض من السيرفر: $errorMessage";
      } else {
        return "تأكد من اتصال الإنترنت: ${e.message}";
      }
    } catch (e) {
      return "خطأ غير متوقع: $e";
    }
  }

  Future<String> getResponseWithImage(String prompt, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Determine mime type based on file extension (default to jpeg)
      String mimeType = 'image/jpeg';
      final path = imageFile.path.toLowerCase();
      if (path.endsWith('.png')) mimeType = 'image/png';
      else if (path.endsWith('.webp')) mimeType = 'image/webp';

      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
        ),
        data: {
          "systemInstruction": {
            "parts": [
              {"text": _systemRules}
            ]
          },
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inlineData": {
                    "mimeType": mimeType,
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        },
      );

      if (response.statusCode == 200) {
        return response.data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "كود الخطأ: ${response.statusCode}";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("❌ Gemini Vision Server Error: \${e.response?.data}");
        String errorMessage =
            e.response?.data['error']['message'] ?? 'خطأ غير معروف';
        return "رفض من السيرفر: \$errorMessage";
      } else {
        return "تأكد من اتصال الإنترنت: \${e.message}";
      }
    } catch (e) {
      return "خطأ غير متوقع: \$e";
    }
  }
}
