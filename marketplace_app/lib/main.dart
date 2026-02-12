import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/router_config.dart';
import 'shared/providers/shop_providers.dart';
import 'shared/models/conversation_model.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MarketplaceApp(),
    ),
  );
}

class MarketplaceApp extends ConsumerWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialise le socket global
    ref.watch(chatSocketProvider);

    // Écoute les nouveaux messages entrants pour afficher un SnackBar global
    ref.listen<MessageModel?>(
      lastIncomingMessageProvider,
      (previous, next) {
        if (next == null) return;

        final router = GoRouter.of(context);
        final uri = router.routeInformationProvider.value.uri.toString();

        // Si on n'est pas déjà sur la conversation concernée, affiche un SnackBar
        if (!uri.startsWith('/chat/${next.conversationId}')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nouveau message: ${next.content}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    return MaterialApp.router(
      title: 'Marketplace',
      debugShowCheckedModeBanner: false,
      
      // Thème personnalisé
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // TODO: Gérer le mode thème dynamiquement
      
      // Configuration du routeur
      routerConfig: AppRouter.router,
    );
  }
}
