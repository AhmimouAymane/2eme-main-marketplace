import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/moderation/data/moderation_service.dart';
import '../../../../core/constants/app_constants.dart';

final blockedUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(moderationServiceProvider).getBlockedUsers();
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        title: const Text('Utilisateurs bloqués', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.cloviGreen,
        elevation: 0,
      ),
      body: blockedAsync.when(
        data: (blocked) {
          if (blocked.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.cloviGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, size: 50, color: AppColors.cloviGreen),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucun utilisateur bloqué',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les utilisateurs que vous bloquez\napparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: blocked.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = blocked[index]['blockedUser'] ?? blocked[index];
              final String firstName = user['firstName'] ?? '';
              final String lastName = user['lastName'] ?? '';
              final String? avatarUrl = user['avatarUrl'];
              final String userId = blocked[index]['blockedUserId'] ?? user['id'] ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(
                            avatarUrl.startsWith('http')
                                ? avatarUrl
                                : '${AppConstants.mediaBaseUrl}$avatarUrl',
                          )
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[400])
                        : null,
                  ),
                  title: Text(
                    '$firstName $lastName'.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Text(
                    'Utilisateur bloqué',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => _confirmUnblock(context, ref, userId, '$firstName $lastName'),
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('Débloquer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.cloviGreen,
                      backgroundColor: AppColors.cloviGreen.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erreur: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(blockedUsersProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmUnblock(BuildContext context, WidgetRef ref, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: AppColors.cloviGreen),
            SizedBox(width: 10),
            Text('Débloquer ?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Voulez-vous débloquer $name ?\nIls pourront à nouveau vous envoyer des messages.',
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
                await ref.read(moderationServiceProvider).unblockUser(userId);
                ref.invalidate(blockedUsersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name a été débloqué.'),
                      backgroundColor: AppColors.cloviGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cloviGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );
  }
}
