import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/chat_bot_model.dart';
import 'package:medinear_app/core/services/gemini_service.dart';
import 'package:medinear_app/core/services/groq_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/chat_bot_remote_data_source.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatBotProvider extends ChangeNotifier {
  // الخدمات القديمة بتاعت الذكاء الاصطناعي زي ما هي
  final GeminiService _geminiService = GeminiService();
  final GroqService _groqService = GroqService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // ✅ الإضافات الجديدة الخاصة بالاتصال بالسيرفر (الباك إند)
  final ChatBotRemoteDataSource _api = ChatBotRemoteDataSource();
  String? _userToken;

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;

  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  List<ChatMessage> get messages => _messages;
  
  // ==========================================
  // ✅ الدالة اللي كانت ناقصة عشان تجيب الشات أول ما تفتح
  // ==========================================
  Future<void> initChat(String token) async {
    _userToken = token;
    _isTyping = true;
    notifyListeners();

    _messages = await _api.getChatHistory(_userToken!);
    
    _isTyping = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // (هنا هتبدأ تحط الدوال الجديدة اللي اتفقنا عليها زي initChat وتعدل sendMessage)
  // ----------------------------------------------------

  final List<String> suggestions = [
    'Medicine Order Guide',
    'Track Shipment',
    'Instant Consultation',
    'Find a Pharmacy',
    'Medication Schedule',
    'Account & Wallet',
  ];

  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }



  void setTyping(bool value) {
    if (_isTyping != value) {
      _isTyping = value;
      notifyListeners();
    }
  }

  Future<void> toggleListening(TextEditingController controller) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (val) {
          _isListening = false;
          notifyListeners();
        },
      );
      if (available) {
        _isListening = true;
        notifyListeners();
        _speech.listen(
          onResult: (val) {
            controller.text = val.recognizedWords;
          },
          localeId: 'ar_EG', // Or could be empty for default
        );
      } else {
        _isListening = false;
        notifyListeners();
      }
    } else {
      _isListening = false;
      _speech.stop();
      notifyListeners();
    }
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    // فصلنا الرسالة في متغير عشان نضيفها للواجهة ونبعتها للسيرفر في نفس الوقت
    final userMsg = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isBot: false,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);

    // ✅ الإضافة الأولى: رفع رسالة المستخدم للسيرفر في الخلفية
    if (_userToken != null) {
      _api.saveMessage(userMsg, _userToken!);
    }

    _isTyping = true;
    notifyListeners();

    String response = _analyzeMedicalInput(text);

    if (response.startsWith("Sorry, I didn't quite understand")) {
      try {
        response = await _geminiService.getResponse(text);
        if (response.contains("خطأ") ||
            response.contains("رفض") ||
            response.contains("Unavailable") ||
            response.contains("Error")) {
          debugPrint("⚠️ جيميناي مشغول.. جاري التحويل لـ جروك...");
          response = await _groqService.getResponse(text);
        }
      } catch (e) {
        debugPrint("⚠️ كراش في جيميناي.. جاري التحويل لـ جروك...");
        try {
          response = await _groqService.getResponse(text);
        } catch (e2) {
          response = _analyzeMedicalInput(text);
        }
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // فصلنا رسالة البوت في متغير بردو
    final botMsg = ChatMessage(
      id: DateTime.now().toString(),
      text: response,
      isBot: true,
      timestamp: DateTime.now(),
    );

    _messages.add(botMsg);

    // ✅ الإضافة الثانية: رفع رسالة البوت للسيرفر في الخلفية
    if (_userToken != null) {
      _api.saveMessage(botMsg, _userToken!);
    }

    int extraWait = response.length * 12;
    Future.delayed(Duration(milliseconds: extraWait), () {
      _isTyping = false;
      notifyListeners();
    });

    notifyListeners();
  }

  String _analyzeMedicalInput(String input) {
    input = input.toLowerCase().trim();
    if (input == 'hi' || input == 'hey' || input.startsWith('hi ') || input.contains('hello') || input.contains('welcome')) {
      return 'Welcome! I am your MidiNear assistant 💙\nHow can I guide you today?';
    }
    if (input.contains('medicine') || input.contains('order') || input.contains('guide') || input.contains('buy')) {
      return 'To complete your order easily, follow these steps:\n1. Use the Smart Search bar on the home screen.\n2. Select the required medicine and add it to your cart.\n3. Click "Checkout" to confirm the process.';
    }
    if (input.contains('track') || input.contains('shipment') || input.contains('status')) {
      return 'To follow up on your order:\n1. Open "My Orders" history.\n2. You will find shipment details and real-time status.';
    }
    if (input.contains('instant') || input.contains('consultation') || input.contains('doctor') || input.contains('physician')) {
      return 'To get a medical consultation:\n1. Go to the "Messages" tab.\n2. Choose the specialized doctor and start the conversation immediately.';
    }
    if (input.contains('find') || input.contains('pharmacy') || input.contains('search') || input.contains('map')) {
      return 'To find a pharmacy:\n1. Open the "Map" section.\n2. The nearest available pharmacies around you will appear.';
    }
    if (input.contains('medication') || input.contains('schedule') || input.contains('reminder') || input.contains('time')) {
      return 'To set your medication times:\n1. Access the "Medicine Reminder" feature.\n2. Add the doses, and I will alert you at the scheduled time.';
    }
    if (input.contains('account') || input.contains('wallet') || input.contains('pay')) {
      return 'To manage your account and payment:\n1. Open "Profile" to edit your data.\n2. You can pay via E-wallet or cards.';
    }
    return "Sorry, I didn't quite understand your inquiry.\nI am the MidiNear guide, does your question concern:\n- Medicine Order Guide\n- Track Shipment\n- Instant Consultation\n- Find a Pharmacy\n- Medication Schedule\n- Account & Wallet? 💙";
  }

void clearChat() {
    _messages = [];
    _isTyping = false;
    notifyListeners();

    // ✅ مسح الشات من قاعدة بيانات السيرفر (لو المستخدم مسجل دخول)
    if (_userToken != null) {
      _api.clearChat(_userToken!);
    }
  }
}

final chatBotProvider = ChangeNotifierProvider((ref) => ChatBotProvider());