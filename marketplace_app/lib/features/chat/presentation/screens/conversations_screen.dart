import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/utils/formatters.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/models/conversation_model.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/features/notifications/presentation/providers/notifications_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  final filteredConversations = conversations.where((conv) {
                    final currentUserIdAsync = ref.watch(userIdProvider);
                    final currentUserId = currentUserIdAsync.maybeWhen(
                      data: (id) => id,
                      orElse: () => null,
                    );
                    final otherUser = currentUserId != null && conv.buyerId == currentUserId
                        ? conv.seller
                        : conv.buyer;
                    final nameMatch = otherUser?.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                    final messageMatch = conv.messages.isNotEmpty && conv.messages.last.content.toLowerCase().contains(_searchQuery.toLowerCase());
                    return nameMatch || messageMatch;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(conversationsProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSearching) _buildSearchInput(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Messages',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.cloviGreen,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Voir tout',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.cloviGreen.withOpacity(0.8),
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: AppColors.cloviGreen.withOpacity(0.8)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildConversationsList(filteredConversations),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorState(e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              size: 28,
              color: AppColors.cloviGreen,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const Text(
            'Conversations',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
          IconButton(
            icon: Badge(
              label: unreadCountAsync.maybeWhen(
                data: (count) => count > 0 ? Text('$count') : null,
                orElse: () => null,
              ),
              isLabelVisible: unreadCountAsync.maybeWhen(
                data: (count) => count > 0,
                orElse: () => false,
              ),
              backgroundColor: Colors.red,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.cloviGreen,
                size: 28,
              ),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColors.cloviGreen, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  /// Compte les messages non lus pour l'utilisateur courant
  int _countUnread(ConversationModel conv, String? currentUserId) {
    if (currentUserId == null) return 0;
    return conv.messages
        .where((m) => m.senderId != currentUserId && !m.isRead)
        .length;
  }

  Widget _buildConversationsList(List filteredConversations) {
    if (filteredConversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            _searchQuery.isEmpty ? 'Aucune conversation' : 'Aucun résultat pour "$_searchQuery"',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredConversations.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.2),
          indent: 80,
        ),
        itemBuilder: (context, index) {
          final conv = filteredConversations[index] as ConversationModel;
          final currentUserIdAsync = ref.watch(userIdProvider);
          final currentUserId = currentUserIdAsync.maybeWhen(
            data: (id) => id,
            orElse: () => null,
          );
          final otherUser = currentUserId != null && conv.buyerId == currentUserId
              ? conv.seller
              : conv.buyer;
          final lastMessage = conv.messages.isNotEmpty ? conv.messages.last : null;
          final unreadCount = _countUnread(conv, currentUserId);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  backgroundImage: otherUser?.avatarUrl != null && otherUser!.avatarUrl!.isNotEmpty
                      ? NetworkImage(
                          otherUser.avatarUrl!.startsWith('http')
                              ? otherUser.avatarUrl!
                              : '${AppConstants.mediaBaseUrl}${otherUser.avatarUrl}',
                        )
                      : null,
                  child: otherUser?.avatarUrl == null || otherUser!.avatarUrl!.isEmpty
                      ? Icon(Icons.person, size: 28, color: Colors.grey[400])
                      : null,
                ),
                // Badge non lu
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      decoration: BoxDecoration(
                        color: AppColors.cloviGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              otherUser?.fullName ?? 'Utilisateur',
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Row(
              children: [
                // Icône ✓✓ si le dernier message est de l'utilisateur courant
                if (lastMessage != null && lastMessage.senderId == currentUserId) ...[
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: lastMessage.isRead
                        ? AppColors.cloviGreen
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    lastMessage?.content ?? 'Nouvelle conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.black87 : Colors.blueGrey.withAlpha(178),
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMessage != null ? _formatTime(lastMessage.createdAt) : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadCount > 0 ? AppColors.cloviGreen : Colors.grey.shade500,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            onTap: () => context.push('/chat/${conv.id}'),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(e.toString()),
          ElevatedButton(
            onPressed: () => ref.invalidate(conversationsProvider),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      final weekday = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
      return weekday[date.weekday % 7];
    } else {
      return Formatters.date(date);
    }
  }
}