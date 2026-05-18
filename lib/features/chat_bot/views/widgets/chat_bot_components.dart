import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'chat_bot_styles.dart';

class GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size, iconSize;
  const GlassBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(60), width: 0.8),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

class AvatarDot extends StatelessWidget {
  final bool isBot;
  final double r;
  const AvatarDot({super.key, required this.isBot, required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isBot
              ? [ChatBotStyles.g1, ChatBotStyles.g3]
              : const [Color(0xFF7ECDC4), Color(0xFF4DB8AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
        color: Colors.white,
        size: r * 1.05,
      ),
    );
  }
}

class SugChip extends StatelessWidget {
  final String text;
  final double maxWidth;
  const SugChip({super.key, required this.text, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ChatBotStyles.g1.withAlpha(30), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ChatBotStyles.sugText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SugChipSolid extends StatelessWidget {
  final String text;
  const SugChipSolid({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChatBotStyles.g1.withAlpha(80), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ChatBotStyles.sugText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PulsingDot extends ConsumerStatefulWidget {
  const PulsingDot({super.key});
  @override
  ConsumerState<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends ConsumerState<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _a = Tween(begin: 1.0, end: 1.6)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(
        scale: _a,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFFF9800),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0xAAFF9800), blurRadius: 5)],
          ),
        ),
      ),
    );
  }
}

class TypewriterText extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onComplete;
  const TypewriterText({super.key, required this.text, this.onComplete});
  @override
  ConsumerState<TypewriterText> createState() => TypewriterTextState();
}

class TypewriterTextState extends ConsumerState<TypewriterText>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _c;
  late Animation<int> _n;
  late String _cleanText;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // ✅ هنا بنمسح أي نجوم ** من النص قبل ما نعرضه عشان ميبوظش شكل الشات
    _cleanText = widget.text.replaceAll('**', '');

    _c = AnimationController(
      duration: Duration(
          milliseconds:
              _cleanText.length * 10), // ✅ خليناها * 10 عشان تبقي سريعة ومريحة
      vsync: this,
    );
    _n = StepTween(begin: 0, end: _cleanText.length)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
    _c.forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _n,
        builder: (_, __) => Text(
          _cleanText.substring(0, _n.value),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2D3132),
            fontSize: 15.5,
            height: 1.4,
            fontWeight: FontWeight.w500, // ✅ وزن ثابت ومريح للعين لكل الكلام
          ),
        ),
      ),
    );
  }
}
