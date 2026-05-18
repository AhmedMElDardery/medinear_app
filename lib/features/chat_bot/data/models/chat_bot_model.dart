class ChatMessage {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
  });

  // ✅ تحويل الرسالة لـ Map عشان تتبعت للسيرفر عبر Dio
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isBot': isBot,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // ✅ تحويل الـ JSON اللي راجع من السيرفر لـ Object عشان يتعرض في الواجهة
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(), // استخدمنا toString عشان لو السيرفر بعت الـ id كـ int
      text: json['text'],
      isBot: json['isBot'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}