import 'package:flutter/material.dart';
import '../../provider/chat_bot_provider.dart';
import 'chat_bot_styles.dart';
import 'chat_bot_components.dart';

class ChatBotBottomPanel extends StatelessWidget {
  final ChatBotProvider vm;
  final TextEditingController controller;

  const ChatBotBottomPanel({
    super.key,
    required this.vm,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 1. تم استبدال الحسبة القديمة بـ 0 لأننا بنتحكم في الارتفاع من الـ Wrapper الخارجي لسرعة خرافية
    final isEmpty = vm.messages.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        // 🚀 تم إزالة BackdropFilter لرفع كفاءة المعالج أثناء حركة الكيبورد
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E).withAlpha(250) // تعويض الـ Blur بزيادة العتامة
                : ChatBotStyles.panelBg.withAlpha(250),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                  color: ChatBotStyles.g1.withAlpha(40), width: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEmpty && vm.suggestions.isNotEmpty)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: ChatBotStyles.g1.withAlpha(20),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                    itemCount: vm.suggestions.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: vm.isTyping ? null : () => vm.sendMessage(vm.suggestions[i]),
                      child: SugChipSolid(text: vm.suggestions[i]),
                    ),
                  ),
                ),
              Padding(
                // ✅ 2. تم تثبيت البادينج لضمان عدم وجود "مط" أو "تأخير" أثناء الطلوع والنزول
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildTextField(isDark)),
                    const SizedBox(width: 10),
                    _buildSendButton(vm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(value.text);
        final textDir = isArabic ? TextDirection.rtl : TextDirection.ltr;
        final containerAlign = isArabic ? Alignment.centerRight : Alignment.centerLeft;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white.withAlpha(200),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(color: ChatBotStyles.g1.withAlpha(50), width: 0.8),
          ),
          alignment: containerAlign,
          child: TextField(
            controller: controller,
            enabled: !vm.isTyping,
            textDirection: textDir,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: vm.isTyping ? Colors.grey : (isDark ? Colors.white : ChatBotStyles.dark),
            ),
            decoration: InputDecoration(
              hintText: vm.isTyping ? "Please wait..." : "Type your message...",
              hintTextDirection: textDir,
              border: InputBorder.none,
              isCollapsed: true,
              hintStyle: TextStyle(color: ChatBotStyles.soft, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ChatBotProvider vm) {
    return GestureDetector(
      onTap: vm.isTyping ? null : () {
        if (controller.text.trim().isNotEmpty) {
          vm.sendMessage(controller.text.trim());
          controller.clear();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          gradient: LinearGradient(
            colors: vm.isTyping 
              ? [ChatBotStyles.g1.withAlpha(150), ChatBotStyles.g3.withAlpha(150)]
              : [ChatBotStyles.g1, ChatBotStyles.g3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            if (!vm.isTyping)
              BoxShadow(
                color: ChatBotStyles.g2.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Send",
              style: TextStyle(
                color: vm.isTyping ? Colors.white.withAlpha(150) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.send_rounded, 
              color: vm.isTyping ? Colors.white.withAlpha(150) : Colors.white, 
              size: 18
            ),
          ],
        ),
      ),
    );
  }
}