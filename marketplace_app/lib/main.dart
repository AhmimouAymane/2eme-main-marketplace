import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/router_config.dart';
import 'core/routes/app_routes.dart';
import 'shared/providers/shop_providers.dart';
import 'shared/providers/cache_providers.dart';
import 'shared/models/conversation_model.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'dart:async';
import 'core/theme/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'shared/providers/connectivity_provider.dart';
import 'shared/widgets/no_internet_screen.dart';


// Plugin pour gérer les canaux de notification Android
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Canal de notification haute importance
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'Ce canal est utilisé pour les notifications importantes.', // description
  importance: Importance.max,
);

// Gestionnaire de messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

// Clé globale pour pouvoir afficher des SnackBar depuis la racine
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuration FCM
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Demander les permissions (pour iOS et Android 13+)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Configurer le gestionnaire d'arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialiser les notifications locales pour les canaux Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialisation des réglages pour flutter_local_notifications
  const initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification');
  const initializationSettingsDarwin = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Optionnel: Gérer ici les clics sur notifications locales si besoin
    },
  );

  // Charger les préférences partagées AVANT de démarrer l'UI
  // Cela empêche le flash de la page de login au démarrage
  final prefs = await SharedPreferences.getInstance();
  final initialToken = prefs.getString(AppConstants.keyAuthToken);

  runApp(
    UncontrolledProviderScope(
      container: ProviderContainer(
        overrides: [
          // On injecte l'instance SharedPreferences pour le CacheService
          sharedPreferencesProvider.overrideWith((ref) => prefs),
          // On injecte le token immédiatement pour que isAuthenticated le voit dès la première frame
          if (initialToken != null)
            authTokenProvider.overrideWith((ref) => initialToken),
        ],
      ),
      child: const MarketplaceApp(),
    ),
  );
}



class MarketplaceApp extends ConsumerStatefulWidget {
  const MarketplaceApp({super.key});

  @override
  ConsumerState<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends ConsumerState<MarketplaceApp> {
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final currentUserId = ref.read(userIdProvider).value;
    final targetUserId = data['targetUserId'];
    
    // Si la notification est destinée à un autre utilisateur, on ignore le clic
    if (targetUserId != null && currentUserId != null && targetUserId != currentUserId) {
      print("Clic notification ignoré: destinée à un autre utilisateur (Target: $targetUserId, Current: $currentUserId)");
      return;
    }

    final screen = data['screen'];
    if (screen == null) return;

    final router = ref.read(routerProvider);
    
    // Nettoyer les notifications dès qu'on clique sur une action
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    
    switch (screen) {
      case 'chat':
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          // Si on vient d'une notification, on s'assure d'avoir la liste des convos en dessous
          router.go('/conversations');
          router.push('/chat/$conversationId');
        }
        break;
      case 'product_detail':
        final productId = data['productId'];
        if (productId != null) {
          router.push('/product/$productId');
        }
        break;
      case 'order_detail':
        final orderId = data['orderId'];
        if (orderId != null) {
          // IMPORTANT: On utilise .go pour réinitialiser la pile si besoin, 
          // ou on s'assure que le retour mène aux commandes.
          router.go('/orders');
          router.push('/order/$orderId');
        }
        break;
      case 'my_products':
        router.push('/my-products');
        break;
      case 'profile':
        router.go('/profile');
        break;
      case 'notifications':
        router.push('/notifications');
        break;
    }
  }

  void _setupNotifications() async {
    // Désactiver les notifications système en premier plan pour iOS
    // afin d'utiliser nos SnackBars personnalisés à la place (évite les doublons)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    // 1. Gérer les messages en premier plan (Foreground)
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      
      // Vérifier si l'utilisateur est authentifié avant toute action
      final token = ref.read(authTokenProvider);
      final currentUserId = ref.read(userIdProvider).value;
      
      if (token == null || currentUserId == null) {
        print("Notification reçue en premier plan mais ignorée: Utilisateur non connecté");
        return;
      }

      // Filtrer les notifications destinées à un autre utilisateur (anti-bleeding)
      final targetUserId = data['targetUserId'];
      if (targetUserId != null && targetUserId != currentUserId) {
        print("Notification ignorée: destinée à un autre utilisateur (Target: $targetUserId, Current: $currentUserId)");
        return;
      }

      // Mise à jour temps réel pour les commandes
      if (data['screen'] == 'order_detail' && data['orderId'] != null) {
        ref.invalidate(orderDetailProvider(data['orderId']));
        ref.invalidate(buyerOrdersProvider);
        ref.invalidate(sellerOrdersProvider);
      }

      // Mise à jour temps réel pour le statut vendeur
      if (data['type'] == 'SELLER_VERIFIED' || data['type'] == 'SELLER_REJECTED') {
        ref.invalidate(userProfileProvider);
      }

      // Mise à jour du compteur de notifications non lues
      ref.invalidate(unreadNotificationsCountProvider);

      if (message.notification != null) {
        // Ne pas afficher de notification en double si c'est un message chat et que le Socket fonctionne
        // (Socket.io s'en occupe déjà au premier plan pour plus de réactivité)
        if (data['screen'] == 'chat') {
          final chatSocket = ref.read(chatSocketProvider);
          final isSocketConnected = chatSocket?.connected ?? false;
          
          if (isSocketConnected) {
            print('DEBUG: FCM chat push ignored because Socket.IO is handling it');
            return;
          } else {
            print('DEBUG: Socket.IO disconnected! Falling back to FCM for chat notification');
          }
        }

        _showCloviNotification(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
          isSystem: true,
          message: message,
        );
      }
    });

    // 2. Gérer le clic sur une notification (Background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 3. Gérer le message initial si l'app était fermée (Terminated)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Un petit délai peut être nécessaire pour que le routeur soit prêt
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(initialMessage);
      });
    }
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  void _showCloviNotification(String title, String body, {bool isSystem = false, RemoteMessage? message}) {
    final messengerState = rootScaffoldMessengerKey.currentState;
    if (messengerState == null) {
      return;
    }

    // On ne supprime plus la SnackBar actuelle pour permettre l'empilement (queue)
    // si plusieurs messages arrivent à la suite.
    // messengerState.removeCurrentSnackBar();

    messengerState.showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            if (message != null) {
              _handleNotificationClick(message);
            }
          },
          child: Row(
            children: [
              Icon(
                isSystem ? Icons.notifications_active : Icons.chat_bubble,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cloviGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(
          bottom: 16, // Adjusted to be visible just above the BottomNavigationBar
          left: 16,
          right: 16,
        ),
        elevation: 6,
        duration: const Duration(seconds: 3), // Durée réduite (3s) pour moins d'encombrement
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialise le socket global
    ref.watch(chatSocketProvider);

    // Écoute la reconnexion pour rafraîchir les données
    ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (previous == false && next == true) {
        print('DEBUG: App reconnected, refreshing key providers');
        ref.invalidate(userProfileProvider);
        ref.invalidate(homeProductsProvider);
        ref.invalidate(unreadNotificationsCountProvider);
        ref.invalidate(conversationsProvider);
        ref.invalidate(unreadMessagesCountProvider);
      }
    });

    // Écoute les nouveaux messages entrants (Socket.io)
    ref.listen<MessageModel?>(
      lastIncomingMessageProvider,
      (previous, next) {
        if (next == null) {
          return;
        }

        // Récupérer les états actuels une fois les données chargées
        final currentUserId = ref.read(userIdProvider).value;
        final currentChatId = ref.read(currentChatConversationIdProvider);
        
        print('DEBUG: currentUserId=$currentUserId, senderId=${next.senderId}');
        print('DEBUG: currentChatId=$currentChatId, conversationId=${next.conversationId}');

        // NE PAS afficher de notification si :
        // 1. C'est nous qui avons envoyé le message
        if (next.senderId == currentUserId) {
          print('DEBUG: Notification skipped (own message)');
          return;
        }

        // 2. On est déjà dans la conversation en question ? 
        // (Vérifié via le provider géré par ChatScreen)
        
        if (currentChatId != null && currentChatId.toLowerCase() == next.conversationId.toLowerCase()) {
          print('DEBUG: Notification skipped (already in this chat: $currentChatId)');
          return;
        }

        // 3. (Supprimé) On affiche la notification même si l'on est sur la liste des discussions
        // pour que l'utilisateur soit clairement alerté

        print('DEBUG: Showing SnackBar for message: ${next.content}');
        _showCloviNotification(
          'Message de ${next.senderName ?? 'Vendeur'}',
          next.content,
          message: null, // On ne passe pas le message RemoteMessage ici car c'est un Socket message
        );

        // Reset pour permettre de redéclencher même si le même objet est réémis
        // (utile si le backend renvoie le même message ou si Equatable bloque)
        Future.microtask(() {
          ref.read(lastIncomingMessageProvider.notifier).state = null;
        });
      },
    );

    // On garde le watch pour les effets de bord (sync FCM, auth state changes)
    // mais on n'attend plus le chargement car on a déjà injecté le token dans le ProviderContainer
    ref.watch(authInitializerProvider);

    return MaterialApp.router(
      title: 'Marketplace',
      debugShowCheckedModeBanner: false,

      // Thème personnalisé
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Utilise une clé globale pour le ScaffoldMessenger
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      // Configuration du routeur (utilise le provider pour réagir aux changements d'auth)
      routerConfig: ref.watch(routerProvider),
      
      // Gestion globale du mode hors ligne
      builder: (context, child) {
        final isOnline = ref.watch(isOnlineProvider);
        
        if (!isOnline) {
          return NoInternetScreen(
            onRetry: () {
              // Invalider le stream pour forcer une nouvelle vérification
              ref.invalidate(connectivityStreamProvider);
            },
          );
        }
        
        return child!;
      },
    );
  }
}
