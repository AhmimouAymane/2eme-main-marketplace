import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/router_config.dart';
import 'shared/providers/shop_providers.dart';
import 'shared/providers/settings_providers.dart';
import 'shared/models/conversation_model.dart';

// Clé globale pour pouvoir afficher des SnackBar depuis la racine
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Nouveau message: ${next.content}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    return MaterialApp.router(
      title: 'Marketplace',
      debugShowCheckedModeBanner: false,

      // Thème personnalisé
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),

      // Utilise une clé globale pour le ScaffoldMessenger
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      // Configuration du routeur
      routerConfig: AppRouter.router,
    );
  }
}
