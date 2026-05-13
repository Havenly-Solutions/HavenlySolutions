import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/keys.dart';

class ChatsTab extends ConsumerWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            key: AppKeys.chatSearchKey,
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: chatState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: chatState.threads.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final thread = chatState.threads[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.backgroundLight,
                        backgroundImage: thread.avatar != null ? NetworkImage(thread.avatar!) : null,
                        child: thread.avatar == null ? const Icon(Icons.group) : null,
                      ),
                      title: Text(thread.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        thread.lastMessage.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeago.format(thread.lastMessage.createdAt), style: AppTypography.label.copyWith(color: AppColors.textMuted)),
                          if (thread.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.emergency, shape: BoxShape.circle),
                              child: Text(thread.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                        ],
                      ),
                      onTap: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }
}
