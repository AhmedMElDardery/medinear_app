import 'package:flutter/material.dart';
import '../../provider/chat_bot_provider.dart';
import 'chat_bot_styles.dart';

class ChatBotEmptyState extends StatelessWidget {
  final ChatBotProvider vm;
  const ChatBotEmptyState({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: h),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. اللوجو الرئيسي مع تأثير توهج ثلاثي الأبعاد (Glowing 3D Effect)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ChatBotStyles.g1.withAlpha(35),
                        blurRadius: 40,
                        spreadRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ChatBotStyles.g1, ChatBotStyles.g3],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded, // أيقونة طبية احترافية
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),

                SizedBox(height: h * 0.04),

                // 2. عنوان فخم باستخدام Gradient Text
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [ChatBotStyles.g3, ChatBotStyles.g1],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Smart MidiNear",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. نص فرعي مريح للعين
                Text(
                  "Your Smart Healthcare Navigator\nHow can I help you today?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : ChatBotStyles.soft,
                  ),
                ),

                SizedBox(height: h * 0.05),

                // 4. كروت الاقتراحات الفخمة (Premium Cards)
                Column(
                  children: vm.suggestions.map((text) {
                    return _buildPremiumCard(text, isDark, () => vm.sendMessage(text));
                  }).toList(),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // تصميم الكارت الاحترافي
  Widget _buildPremiumCard(String text, bool isDark, VoidCallback onTap) {
    // دالة ذكية لاختيار الأيقونة المناسبة بناءً على النص
    IconData getIcon() {
      final t = text.toLowerCase();
      if (t.contains('medicine') || t.contains('order')) return Icons.medication_rounded;
      if (t.contains('track') || t.contains('shipment')) return Icons.local_shipping_rounded;
      if (t.contains('consultation') || t.contains('doctor')) return Icons.health_and_safety_rounded;
      if (t.contains('pharmacy') || t.contains('find')) return Icons.local_pharmacy_rounded;
      if (t.contains('schedule') || t.contains('reminder')) return Icons.calendar_month_rounded;
      if (t.contains('account') || t.contains('wallet')) return Icons.account_balance_wallet_rounded;
      return Icons.auto_awesome_rounded; // أيقونة افتراضية
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: ChatBotStyles.g1.withAlpha(30), // تأثير ضغط ناعم (Ripple Effect)
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white10 : ChatBotStyles.g1.withAlpha(25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ChatBotStyles.dark.withAlpha(isDark ? 50 : 6),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // مربع الأيقونة الملون
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChatBotStyles.g1.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(getIcon(), color: ChatBotStyles.g2, size: 24),
              ),
              const SizedBox(width: 16),
              // نص الاقتراح
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : ChatBotStyles.dark,
                  ),
                ),
              ),
              // سهم أنيق في النهاية
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ChatBotStyles.soft.withAlpha(150)),
            ],
          ),
        ),
      ),
    );
  }
}