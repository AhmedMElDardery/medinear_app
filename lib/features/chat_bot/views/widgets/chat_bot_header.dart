import 'package:flutter/material.dart';
import '../../provider/chat_bot_provider.dart';
import 'chat_bot_styles.dart';
import 'chat_bot_components.dart';

class ChatBotHeader extends StatelessWidget {
  final ChatBotProvider vm;
  const ChatBotHeader({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    // ✅ تحسين: استخدام sizeOf لتقليل الـ Rebuilds
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(10, top + 10, 10, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ChatBotStyles.hTop, ChatBotStyles.hMid, ChatBotStyles.hBot],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: ChatBotStyles.g2.withAlpha(55),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GlassBtn(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
                size: 38,
                iconSize: 20,
              ),
              const Expanded(
                child: Text(
                  "Smart MidiNear",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GlassBtn(
                icon: Icons.refresh_rounded,
                onTap: () => vm.clearChat(),
                size: 34,
                iconSize: 17,
              ),
            ],
          ),
          const SizedBox(height: 9),
          _buildStatusPill(vm),
        ],
      ),
    );
  }

  Widget _buildStatusPill(ChatBotProvider vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        // ✅ شلنا الـ BackdropFilter وحطينا لون شفاف ثابت (أسرع بـ 100 مرة في الرندر)
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(50), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ الـ PulsingDot لوحدها هي اللي بتتحرك، مفيش Blur وراها يتقل السكرول
          vm.isTyping ? const PulsingDot() : const _StaticOnlineDot(),
          const SizedBox(width: 8),
          Text(
            vm.isTyping ? "Typing..." : "Online",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ فصلنا النقطة الثابتة في Widget مستقلة عشان الكود يبقى أنضف
class _StaticOnlineDot extends StatelessWidget {
  const _StaticOnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF6EFFD8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x886EFFD8), blurRadius: 5),
        ],
      ),
    );
  }
}
