import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/core/utils/formatters.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/models/conversation_model.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:marketplace_app/features/moderation/data/moderation_service.dart';
import 'package:marketplace_app/shared/widgets/report_dialog.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      // Mettre à jour l'ID actif si l'on change de conversation (ex: via notification)
      Future.microtask(() {
        ref.read(currentChatConversationIdProvider.notifier).state =
            widget.conversationId;
      });
      
      // Rejoindre le nouveau salon
      ref.read(chatSocketProvider)?.emit('join_conversation', {
        'conversationId': widget.conversationId,
      });
      
      _markAsRead();
    }
  }

  @override
  void initState() {
    super.initState();
    // On définit l'ID de la conversation actuelle via microtask pour éviter l'erreur de build
    Future.microtask(() {
      ref.read(currentChatConversationIdProvider.notifier).state = widget.conversationId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Nettoyer les notifications résiduelles en entrant dans le chat
      ScaffoldMessenger.of(context).clearSnackBars();
      
      _markAsRead();
      ref.read(chatSocketProvider)?.emit('join_conversation', {
        'conversationId': widget.conversationId,
      });
    });
  }

  @override
  void dispose() {
    // Le provider auto-dispose se chargera de la remise à null automatiquement
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _markAsRead() async {
    try {
      final service = ref.read(chatServiceProvider);
      await service.markAsRead(widget.conversationId);
      ref.invalidate(conversationsProvider);
      ref.invalidate(conversationMessagesProvider(widget.conversationId));
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUserId = ref.read(userIdProvider).value;
    if (currentUserId == null) return;

    // --- OPTIMISTIC UI ---
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      conversationId: widget.conversationId,
      senderId: currentUserId,
      content: text,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 1. Ajouter immédiatement à la liste (UI)
    ref.read(conversationMessagesProvider(widget.conversationId).notifier).addMessage(optimisticMessage);
    
    // 2. Nettoyer le champ et scroller
    _controller.clear();
    _scrollToBottom();
    // -----------------------

    // setState(() => _isSending = true); // On ne bloque plus l'UI avec un spinner global

    try {
      final service = ref.read(chatServiceProvider);
      await service.sendMessage(widget.conversationId, text);
      
      // On rafraîchit la liste des conversations en arrière-plan pour le dernier message
      ref.invalidate(conversationsProvider);
      
      // Note: Le "vrai" message reviendra via Socket.IO et remplacera l'optimiste
      // grâce à la logique de dédoublonnement dans le Notifier.
      
    } catch (e) {
      // En cas d'erreur, on retire le message optimiste
      ref.read(conversationMessagesProvider(widget.conversationId).notifier).removeMessage(tempId);
      
      // On remet le texte dans le contrôleur pour que l'utilisateur puisse réessayer
      _controller.text = text;

      if (!mounted) return;
      
      String errorMessage = 'Erreur lors de l\'envoi: $e';
      if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMessage = 'Vous ne pouvez pas envoyer de message à cet utilisateur.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Envoyer une pièce jointe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Galerie',
                  color: AppColors.cloviGreen,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Caméra',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Pour l'instant, on envoie un message texte indiquant qu'une photo a été envoyée
        // TODO: Implémenter l'envoi d'image via le backend
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 L\'envoi de photos sera bientôt disponible !'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBlockConfirmation(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.error),
            SizedBox(width: 10),
            Text('Bloquer ?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Voulez-vous bloquer $name ?\n\nVous ne recevrez plus ses messages et vous ne pourrez plus interagir avec cette personne.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
                try {
                await ref.read(moderationServiceProvider).blockUser(userId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$name a été bloqué.'),
                      backgroundColor: AppColors.error,
                  ),
                );
                if (context.canPop()) {
                  context.pop(); // Quitter le chat
                } else {
                  context.go(AppRoutes.conversations);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog({String? userId}) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
    final currentUserIdAsync = ref.watch(userIdProvider);
    
    // Observer le provider pour le garder en vie via autoDispose tant que l'écran est affiché
    ref.watch(currentChatConversationIdProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          // Si on ne peut pas pop (ex: ouvert via notification), on force le retour vers la liste
          context.go(AppRoutes.conversations);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cloviBeige,
        appBar: AppBar(
          elevation: 1,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cloviGreen),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.conversations);
              }
            },
          ),
          title: conversationAsync.when(
          data: (conversation) {
            final currentUserId = currentUserIdAsync.maybeWhen(
              data: (id) => id,
              orElse: () => null,
            );
            final otherUser = currentUserId != null &&
                    conversation.buyerId == currentUserId
                ? conversation.seller
                : conversation.buyer;
            return GestureDetector(
              onTap: () {
                // Naviguer vers le profil du vendeur
                if (otherUser?.id != null) {
                  context.push('/seller/${otherUser!.id}');
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    backgroundImage: otherUser?.avatarUrl != null && otherUser!.avatarUrl!.isNotEmpty
                        ? NetworkImage(
                            otherUser.avatarUrl!.startsWith('http')
                                ? otherUser.avatarUrl!
                                : '${AppConstants.mediaBaseUrl}${otherUser.avatarUrl}',
                          )
                        : null,
                    child: otherUser?.avatarUrl == null || otherUser!.avatarUrl!.isEmpty
                        ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser?.fullName ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (conversation.product?.title != null)
                          Text(
                            conversation.product!.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Conversation'),
        ),
        actions: [
          conversationAsync.maybeWhen(
            data: (conversation) {
              final currentUserId = currentUserIdAsync.maybeWhen(
                data: (id) => id,
                orElse: () => null,
              );
              final otherUser = currentUserId != null &&
                      conversation.buyerId == currentUserId
                  ? conversation.seller
                  : conversation.buyer;

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      if (otherUser?.id != null) {
                        context.push('/seller/${otherUser!.id}');
                      }
                      break;
                    case 'article':
                      if (conversation.product?.id != null) {
                        context.push('/product/${conversation.product!.id}');
                      }
                      break;
                    case 'delete':
                      _showDeleteConfirmation(context, ref, conversation.id);
                      break;
                    case 'block':
                      if (otherUser?.id != null) {
                        _showBlockConfirmation(context, otherUser!.id, otherUser.fullName ?? 'cet utilisateur');
                      }
                      break;
                    case 'report':
                      if (otherUser?.id != null) {
                        _showReportDialog(userId: otherUser!.id);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Voir le profil'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'article',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Voir l\'article'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report_gmailerrorred_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Signaler l\'utilisateur'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_outlined, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Bloquer l\'utilisateur', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Carte produit en haut du chat
          conversationAsync.when(
            data: (conversation) => _buildProductCard(conversation.product),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message pour le moment',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envoyez un message pour démarrer la conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                final currentUserId = currentUserIdAsync.maybeWhen(
                  data: (id) => id,
                  orElse: () => null,
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = currentUserId != null && msg.senderId == currentUserId;
                    final showDate = index == 0 ||
                        !_isSameDay(messages[index - 1].createdAt, msg.createdAt);

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDate(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        _MessageBubble(
                          message: msg,
                          isMine: isMine,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Barre de saisie
          _buildInputBar(),
        ],
      ),
    ),);
  }

  /// Carte du produit affiché en haut du chat
  Widget _buildProductCard(ProductModel? product) {
    if (product == null) return const SizedBox.shrink();

    final imageUrl = product.fullMainImageUrl;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Image produit
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            // Infos produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.toStringAsFixed(0)} ${AppConstants.currencySymbol}',
                    style: const TextStyle(
                      color: AppColors.cloviGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton voir
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cloviGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Voir',
                style: TextStyle(
                  color: AppColors.cloviGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barre de saisie avec bouton pièce jointe
  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bouton pièce jointe
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: Icon(Icons.attach_file_rounded, color: Colors.grey.shade600),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              // Champ texte
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton envoyer
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.cloviGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == DateTime(now.year, now.month, now.day)) {
      return "Aujourd'hui";
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else {
      return Formatters.date(date);
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String conversationId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la conversation ?'),
        content: const Text(
          'La conversation sera masquée de votre liste. Elle réapparaîtra si vous recevez un nouveau message.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(chatServiceProvider).deleteConversation(conversationId);
                ref.invalidate(conversationsProvider);
                if (context.mounted) {
                  Navigator.pop(context); // Quitter le chat
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Bulle de message avec statut de lecture
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.cloviGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  // Statut de lecture pour les messages envoyés
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: message.isRead
                          ? AppColors.cloviGreen
                          : Colors.grey.shade400,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}