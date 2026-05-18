import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
// Core & Theme - المسارات الكاملة (Package) للثيم والألوان

// Models - مسار نسبي للوصول للموديل
import '../data/models/chat_model.dart';
// تعريف واجهات التحكم في الحالة (ViewModels) - مسار نسبي للوصول للـ ViewModel داخل نفس الميزة
import '../view_models/chats_view_model.dart';
// ✅ Widgets - التعديل الأهم: الملف الآن موجود داخل مجلد الـ widgets الخاص بالـ chat
import 'widgets/chat_list_item.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class ArchivedChatsView extends ConsumerStatefulWidget {
  final ChatsViewModel viewModel;

  const ArchivedChatsView({super.key, required this.viewModel});

  @override
  ConsumerState<ArchivedChatsView> createState() => _ArchivedChatsViewState();
}

class _ArchivedChatsViewState extends ConsumerState<ArchivedChatsView> {
  void _unarchiveChat(ChatModel chat) {
    setState(() {
      chat.isArchived = false;
      widget.viewModel.search(widget.viewModel.lastSearchQuery);
    });

    if (widget.viewModel.chats.where((c) => c.isArchived).isEmpty) {
      Navigator.pop(context);
    }
  }

  void _deleteChat(ChatModel chat) {
    setState(() {
      widget.viewModel.chats.remove(chat);
      widget.viewModel.search(widget.viewModel.lastSearchQuery);
    });

    if (widget.viewModel.chats.where((c) => c.isArchived).isEmpty) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // جلب حالة الدارك مود الحالية
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ✅ حل مشكلة البياض المستفز: الخلفية الآن مربوطة بـ AppColors.darkBackground تلقائياً
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: 'Archived Chats',
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          final archivedChats =
              widget.viewModel.chats.where((c) => c.isArchived).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: archivedChats.isEmpty
                ? Center(
                    child: Text("No archived chats",
                        style: TextStyle(
                            // لون النص في حالة الفراغ يكون رمادي متناسق
                            color:
                                isDarkMode ? Colors.white54 : Colors.black45)))
                : ListView.builder(
                    itemCount: archivedChats.length,
                    itemBuilder: (context, index) {
                      final chat = archivedChats[index];
                      // ✅ التأكد من أن الـ Item نفسه يدعم الثيم داخل الـ Widget الخاص به
                      return ChatListItem(
                        chat: chat,
                        onDelete: () => _deleteChat(chat),
                        onArchive: () => _unarchiveChat(chat),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
