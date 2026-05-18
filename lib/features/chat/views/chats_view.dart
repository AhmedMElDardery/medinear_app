import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
// Core & Theme - المسارات العالمية بتبدأ بـ package

// Models - المسار الجديد داخل الميزة
import '../data/models/chat_model.dart';
// تعريف واجهات التحكم في الحالة (ViewModels) - المسار الجديد داخل الميزة
import '../view_models/chats_view_model.dart';
// Screens - لو الملف في نفس المجلد بنستخدم المسار المباشر
import 'archived_chats_view.dart';
import 'widgets/chat_list_item.dart';
import 'package:medinear_app/core/widgets/custom_app_bar.dart';

class ChatsView extends ConsumerStatefulWidget {
  const ChatsView({super.key});

  @override
  ConsumerState<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends ConsumerState<ChatsView> {
  final ChatsViewModel _viewModel = ChatsViewModel();

  void _deleteWithUndo(int index, ChatModel chat) {
    setState(() {
      _viewModel.chats.remove(chat);
      _viewModel.search(_viewModel.lastSearchQuery);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Deleted ${chat.doctorName}"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _viewModel.chats.insert(index, chat);
              _viewModel.search(_viewModel.lastSearchQuery);
            });
          },
        ),
      ),
    );
  }

  void _archiveChat(ChatModel chat) {
    setState(() {
      chat.isArchived = true;
      _viewModel.search(_viewModel.lastSearchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ الآن الخلفية ستتغير تلقائياً حسب الثيم (أبيض في الفاتح / أسود صريح في الدارك)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: Colors.transparent,
        title: 'Chats',
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          final archivedCount =
              _viewModel.chats.where((c) => c.isArchived).length;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildSearchBar(context),
                const SizedBox(height: 16),
                if (archivedCount > 0)
                  _buildArchiveHeader(archivedCount, context),
                Expanded(
                  child: ListView.builder(
                    itemCount: _viewModel.filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = _viewModel.filteredChats[index];
                      if (chat.isArchived) return const SizedBox.shrink();

                      return ChatListItem(
                        chat: chat,
                        onDelete: () => _deleteWithUndo(index, chat),
                        onArchive: () => _archiveChat(chat),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        // ✅ استخدام لون الكارت المخصص للدارك من ملف الألوان
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border:
            Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: _viewModel.search,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          hintText: 'Search your doctor...',
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildArchiveHeader(int count, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArchivedChatsView(viewModel: _viewModel),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ✅ ألوان متفاعلة مع الدارك مود لمنع البهتان أو البياض الزائد
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.archive_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text("Archived Chats",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("$count",
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}