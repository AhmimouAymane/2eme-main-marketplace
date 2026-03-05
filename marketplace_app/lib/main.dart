import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/router_config.dart';
import 'shared/providers/shop_providers.dart';
import 'shared/providers/settings_providers.dart';
import 'shared/models/conversation_model.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'dart:async';
import 'core/theme/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  runApp(
    const ProviderScope(
      child: MarketplaceApp(),
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
    print("Notification clicked: ${message.data}");
    final data = message.data;
    final screen = data['screen'];
    
    if (screen == null) return;

    final router = ref.read(routerProvider);
    
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
      if (token == null) {
        print("Notification reçue en premier plan mais ignorée: Utilisateur non connecté");
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
        // Ne pas afficher de notification si c'est un message chat
        // et qu'on est déjà dans cette conversation
        if (data['screen'] == 'chat' && data['conversationId'] != null) {
          final currentChatId = ref.read(currentChatConversationIdProvider);
          if (currentChatId == data['conversationId']) {
            return; // On est déjà dans cette conversation
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

    // Nettoyer toute notification existante pour éviter l'empilement
    messengerState.removeCurrentSnackBar();

    messengerState.showSnackBar(
      SnackBar(
        content: Row(
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cloviGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(
          bottom: 16, // Adjusted to be visible just above the BottomNavigationBar
          left: 16,
          right: 16,
        ),
        elevation: 6,
        duration: const Duration(seconds: 3), // Reduced duration for transient effect
        action: SnackBarAction(
          label: 'VOIR',
          textColor: Colors.white70,
          onPressed: () {
            if (message != null) {
              _handleNotificationClick(message);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialise le socket global
    ref.watch(chatSocketProvider);

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
        // 2. On est déjà dans la conversation en question
        if (next.senderId == currentUserId || next.conversationId == currentChatId) {
          print('DEBUG: Notification skipped (own message or active chat)');
          return;
        }

        print('DEBUG: Showing SnackBar for message: ${next.content}');
        _showCloviNotification(
          'Message de ${next.senderName ?? next.senderId}',
          next.content,
        );

        // Reset pour permettre de redéclencher même si le même objet est réémis
        // (utile si le backend renvoie le même message ou si Equatable bloque)
        Future.microtask(() {
          ref.read(lastIncomingMessageProvider.notifier).state = null;
        });
      },
    );

    // Initialise le token au démarrage
    final authInit = ref.watch(authInitializerProvider);

    if (authInit.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.cloviGreen),
          ),
        ),
      );
    }

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
    );
  }
}
