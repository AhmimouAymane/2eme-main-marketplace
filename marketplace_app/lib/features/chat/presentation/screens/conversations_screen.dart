import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/utils/formatters.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/widgets/clovi_bottom_nav.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.search);
        break;
      case 2:
        context.push(AppRoutes.createProduct);
        break;
      case 3:
        // Déjà sur messages
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSearching)
                            _buildSearchInput(),
                          
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
                                    'See all',
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorState(e),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CloviBottomNav(
        selectedIndex: 3,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.search, size: 32, color: AppColors.cloviGreen),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Rechercher une conversation...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: AppColors.cloviGreen),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
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
          final conv = filteredConversations[index];
          final currentUserIdAsync = ref.watch(userIdProvider);
          final currentUserId = currentUserIdAsync.maybeWhen(
            data: (id) => id,
            orElse: () => null,
          );
          final otherUser = currentUserId != null && conv.buyerId == currentUserId
              ? conv.seller
              : conv.buyer;
          final lastMessage = conv.messages.isNotEmpty ? conv.messages.last : null;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE0E0E0),
              child: Icon(Icons.person, size: 35, color: Colors.white),
            ),
            title: Text(
              otherUser?.fullName ?? 'Utilisateur',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              lastMessage?.content ?? 'Message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.blueGrey.withAlpha(178),
                fontSize: 14,
              ),
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
      // Aujourd'hui
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      // Hier
      return 'Hier';
    } else if (difference.inDays < 7) {
      // Cette semaine
      final weekday = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
      return weekday[date.weekday % 7];
    } else {
      // Plus ancien
      return Formatters.date(date);
    }
  }
}