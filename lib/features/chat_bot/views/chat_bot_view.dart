import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/chat_bot_provider.dart';
import 'widgets/chat_bot_styles.dart';
import 'widgets/chat_bot_header.dart';
import 'widgets/chat_bot_empty_state.dart';
import 'widgets/chat_bot_message_bubble.dart';
import 'widgets/chat_bot_bottom_panel.dart';

// ============================================================
// Main Chat View - Clean Version (No Background Animation)
// ============================================================
class ChatBotView extends ConsumerStatefulWidget {
  const ChatBotView({super.key});

  @override
  ConsumerState<ChatBotView> createState() => _ChatBotViewState();
}

class _ChatBotViewState extends ConsumerState<ChatBotView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✅ دي دالة initState اللي ضفناها عشان تجيب الرسايل أول ما الشاشة تفتح
@override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userToken = "YOUR_REAL_USER_TOKEN_HERE"; 
      ref.read(chatBotProvider).initChat(userToken);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: isDark 
          ? Theme.of(context).scaffoldBackgroundColor 
          : ChatBotStyles.bgBase,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            // Layout Layer
            Consumer(
              builder: (context, ref, child) {
                final vm = ref.watch(chatBotProvider);
                final isEmpty = vm.messages.isEmpty;

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return Column(
                  children: [
                    ChatBotHeader(vm: vm),
                    Expanded(
                      child: isEmpty
                          ? ChatBotEmptyState(vm: vm)
                          : RepaintBoundary(
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  MediaQuery.of(context).size.height * 0.23,
                                ),
                                itemCount: vm.messages.length,
                                itemBuilder: (_, i) => ChatBotMessageBubble(
                                  msg: vm.messages[i], 
                                  vm: vm,
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),

            // Floating Input Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  final vm = ref.watch(chatBotProvider);
                  return ChatBotBottomPanel(vm: vm, controller: _controller);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
