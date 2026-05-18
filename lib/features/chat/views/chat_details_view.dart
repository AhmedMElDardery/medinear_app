import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../view_models/chat_details_view_model.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_field.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class ChatDetailsView extends ConsumerStatefulWidget {
  const ChatDetailsView({super.key});

  @override
  ConsumerState<ChatDetailsView> createState() => _ChatDetailsViewState();
}

class _ChatDetailsViewState extends ConsumerState<ChatDetailsView> {
  final ChatDetailsViewModel _viewModel = ChatDetailsViewModel();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // معرفة حالة الثيم (دارك أم فاتح)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ✅ خلفية متجاوبة تتبع الثيم (أسود في الدارك، وفاتح في اللايت)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        // 🚀 لون الهيدر: أسود شيك في الدارك، وأبيض ناصع في اللايت عشان يبرز خط الليزر
        backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
        elevation: 0, // بنلغي الظل العادي عشان هنعمل ظل "ليزر"
        leading: CustomBackButton(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF198B61), width: 1.5),
                  // 🚀 لمسة احترافية: توهج خفيف حول صورة الدكتور
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF198B61).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                child: Icon(Icons.person,
                    color: isDarkMode ? Colors.white70 : Colors.grey, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _viewModel.doctorName,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Text("Online",
                    style: TextStyle(color: Color(0xFF198B61), fontSize: 11)),
              ],
            ),
          ],
        ),
        // 🚀 السحر هنا: خط "الليزر" المضيء
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            height: 2.0,
            decoration: BoxDecoration(
              color: const Color(0xFF198B61), // اللون الأخضر
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF198B61)
                      .withValues(alpha: 0.8), // التوهج (الليزر)
                  blurRadius: 6, // قوة التوهج
                  spreadRadius: 1, // انتشار الضوء
                  offset: const Offset(0, 2), // اتجاه الضوء لتحت
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🚀 خلفية النقوش الطبية الفخمة (زي واتساب)
          Positioned.fill(
            child: _buildChatPatternBackground(isDarkMode),
          ),

          Column(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, child) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _viewModel.messages.length,
                      itemBuilder: (context, index) =>
                          MessageBubble(message: _viewModel.messages[index]),
                    );
                  },
                ),
              ),
              ChatInputField(
                controller: _viewModel.messageController,
                onSend: _viewModel.sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🚀 دالة بناء نقشة الخلفية باستخدام رموز طبية دقيقة وعشوائية (Doodles)
  Widget _buildChatPatternBackground(bool isDark) {
    // 🎨 اللون أبيض أو أسود عشان تناسب الـ Opacity وتدي شكل شيك بدون إزعاج للعين
    final Color iconColor = isDark ? Colors.white : Colors.black;

    // 🌟 رموز طبية دقيقة (Size أكبر شوية عشان تبقى واضحة)
    final List<Widget> iconWidgets = [
      Icon(Icons.medical_services_outlined, color: iconColor, size: 24),
      Icon(Icons.local_pharmacy_outlined, color: iconColor, size: 24),
      Icon(Icons.healing_outlined, color: iconColor, size: 24),
      Icon(Icons.biotech_outlined, color: iconColor, size: 24),
      Icon(Icons.science_outlined, color: iconColor, size: 24),
      Icon(Icons.sanitizer_outlined, color: iconColor, size: 24),
      Icon(Icons.health_and_safety_outlined, color: iconColor, size: 24),
      Icon(Icons.vaccines_outlined, color: iconColor, size: 24),
      Icon(Icons.medication_outlined, color: iconColor, size: 24),
      Icon(Icons.masks_outlined, color: iconColor, size: 24),
      Icon(Icons.monitor_heart_outlined, color: iconColor, size: 24),
      Icon(Icons.bloodtype_outlined, color: iconColor, size: 24),
      Icon(Icons.favorite_border, color: iconColor, size: 24),
      Icon(Icons.thermostat_outlined, color: iconColor, size: 24),
      Icon(Icons.medical_information_outlined, color: iconColor, size: 24),
      Icon(Icons.spa_outlined, color: iconColor, size: 24),
      Icon(Icons.psychology_outlined, color: iconColor, size: 24),
      Icon(Icons.clean_hands_outlined, color: iconColor, size: 24),
    ];

    return Opacity(
      // 🚀 عتامة خفيفة تناسب الـ Light/Dark بدون ما تأثر على الرسايل
      opacity: isDark ? 0.08 : 0.06,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          // 🚀 قللنا الأعمدة عشان مساحة الأيقونة تكبر وتتنفس
          crossAxisCount: 7,
          mainAxisSpacing: 35,
          crossAxisSpacing: 35,
        ),
        itemCount: 150, // متناسقة مع عدد الأعمدة
        itemBuilder: (context, index) {
          final int pseudoRandomIndex = (index * 23 + 13) % iconWidgets.length;
          final widget = iconWidgets[pseudoRandomIndex];

          // 🚀 الإزاحة يمين وشمال وفوق وتحت بشكل عشوائي عشان نكسر شكل الـ Grid المترتب
          double offsetX = ((index * 13) % 40) - 20.0;
          double offsetY = ((index * 17) % 40) - 20.0;

          // دوران عشوائي
          double rotation = ((index * 11) % 7) * 0.3 - 0.9;

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: rotation,
              child: widget,
            ),
          );
        },
      ),
    );
  }
}
