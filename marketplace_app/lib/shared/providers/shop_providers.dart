import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/features/products/data/products_service.dart';
import 'package:marketplace_app/features/products/data/favorites_service.dart';
import 'package:marketplace_app/features/categories/data/categories_service.dart';
import 'package:marketplace_app/features/orders/data/orders_service.dart';
import 'package:marketplace_app/shared/services/media_service.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
import 'package:marketplace_app/shared/models/order_model.dart';
import 'package:marketplace_app/shared/models/user_model.dart';
import 'package:marketplace_app/shared/models/conversation_model.dart';
import 'package:marketplace_app/features/chat/data/chat_service.dart';
import 'package:marketplace_app/shared/models/address_model.dart';
import 'package:marketplace_app/features/addresses/data/addresses_service.dart';
import 'package:marketplace_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:marketplace_app/features/users/data/users_service.dart';

enum SearchMode { articles, members }

final searchModeProvider = StateProvider<SearchMode>((ref) => SearchMode.articles);

// Services
// (usersServiceProvider moved to auth_providers.dart)


final productsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ProductsService(dio);
});

final favoritesServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return FavoritesService(dio);
});

final categoriesServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return CategoriesService(dio);
});

final ordersServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return OrdersService(dio);
});

final mediaServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return MediaService(dio);
});

final chatServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ChatService(dio);
});

// Addresses service/provider
final addressesServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AddressesService(dio);
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((
  ref,
) async {
  final service = ref.watch(categoriesServiceProvider);
  return service.getCategories(); // Fait maintenant appel au cache local implicitement
});

/// Provider to find a category ID by its slug
final categoryBySlugProvider = Provider.family<String?, String>((ref, slug) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.maybeWhen(
    data: (categories) {
      return _findCategoryRecursive(categories, slug)?.id;
    },
    orElse: () => null,
  );
});

CategoryModel? _findCategoryRecursive(List<CategoryModel> categories, String slug) {
  for (final cat in categories) {
    if (cat.slug == slug) return cat;
    if (cat.children.isNotEmpty) {
      final found = _findCategoryRecursive(cat.children, slug);
      if (found != null) return found;
    }
  }
  return null;
}

/// État des filtres de produits
class ProductFilters {
  final String? search;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;

  const ProductFilters({
    this.search,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
  });

  ProductFilters copyWith({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearPrice = false,
  }) {
    return ProductFilters(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
    );
  }
}

class ProductFilterNotifier extends Notifier<ProductFilters> {
  @override
  ProductFilters build() {
    print('DEBUG: ProductFilterNotifier.build() initialized');
    return const ProductFilters();
  }

  void updateSearch(String? search) {
    print('DEBUG: Changing search to: $search');
    state = state.copyWith(search: search);
  }

  void updateCategory(String? categoryId) {
    print('DEBUG: Changing categoryId to: $categoryId');
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );
  }

  void updatePriceRange(double min, double max) {
    print('DEBUG: Changing price range to: [$min - $max]');
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void clearAll() {
    print('DEBUG: Resetting all filters');
    state = const ProductFilters();
  }

  void clearSearch() {
    print('DEBUG: Clearing search filter');
    state = state.copyWith(clearSearch: true);
  }

  void clearPriceRange() {
    print('DEBUG: Clearing price range filters');
    state = state.copyWith(clearPrice: true);
  }
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilters>(() {
      return ProductFilterNotifier();
    });

final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  final filters = ref.watch(productFilterProvider);
  final service = ref.watch(productsServiceProvider);

  print(
    'Fetching products with filters: search=${filters.search}, categoryId=${filters.categoryId}, price=[${filters.minPrice}-${filters.maxPrice}]',
  );

  return service.getProducts(
    search: filters.search,
    category: filters.categoryId,
    minPrice: filters.minPrice,
    maxPrice: filters.maxPrice,
    limit: 50, // default limit for generic listings
  );
});

final userSearchProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final filters = ref.watch(productFilterProvider);
  final service = ref.watch(usersServiceProvider);
  final mode = ref.watch(searchModeProvider);

  if (mode != SearchMode.members || filters.search == null || filters.search!.isEmpty) {
    return [];
  }

  return service.searchUsers(filters.search!);
});

// Provider pour l'accueil (auto-refresh toutes les 30s)
final homeProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  // On observe les filtres pour que l'accueil se rafraîchisse quand ils sont réinitialisés
  ref.watch(productFilterProvider);
  final service = ref.watch(productsServiceProvider);

  // Mise en place d'un timer pour rafraîchir la page automatiquement
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });

  // Nettoyage du timer à la disposition du provider pour éviter les fuites de mémoire
  ref.onDispose(() => timer.cancel());

  print(
    'DEBUG: homeProductsProvider fetching all products (periodic refresh active)',
  );
  return service.getProducts(limit: 20); // only need newest items for home grid
});

// Category specific providers for Home Page
final jewelryProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getProducts(categorySlug: 'femme-accessoires-bijoux', limit: 10);
});

final womenShoesProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getProducts(categorySlug: 'femme-chaussures', limit: 10);
});

final bagsProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getProducts(categorySlug: 'femme-accessoires-sacs', limit: 10);
});

// User Products Provider (My Ads)
final userProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  final userId = await ref.watch(userIdProvider.future);
  if (userId == null) return [];

  final service = ref.watch(productsServiceProvider);
  return service.getProducts(sellerId: userId, limit: 50);
});

// Single Product Provider
final productDetailProvider = FutureProvider.autoDispose
    .family<ProductModel, String>((ref, id) async {
      final service = ref.watch(productsServiceProvider);
      return service.getProduct(id);
    });

// Buyer Orders Provider
final buyerOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((
  ref,
) async {
  final service = ref.watch(ordersServiceProvider);
  return service.getBuyerOrders();
});

// Seller Orders Provider
final sellerOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((
  ref,
) async {
  final service = ref.watch(ordersServiceProvider);
  return service.getSellerOrders();
});

// Single Order Detail Provider
final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderModel, String>((ref, id) async {
      final service = ref.watch(ordersServiceProvider);
      return service.getOrder(id);
    });

// User addresses provider (requires userId)
final userAddressesProvider = FutureProvider.autoDispose
    .family<List<AddressModel>, String>((ref, userId) async {
      final service = ref.watch(addressesServiceProvider);
      return service.fetchUserAddresses(userId);
    });

// Favorites Notifier
class FavoritesNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    // Watch the token so this notifier re-runs when auth state changes
    // (e.g., token restored from SharedPreferences on app start or login)
    final token = ref.watch(authTokenProvider);

    // If not authenticated, return empty list immediately without calling the API
    if (token == null || token.isEmpty) {
      return [];
    }

    final service = ref.watch(favoritesServiceProvider);
    return service.getFavorites();
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final service = ref.read(favoritesServiceProvider);

    // Use the current state value as the source of truth for the toggle action
    final currentList = state.value ?? [];
    final alreadyInFavorites = currentList.any((p) => p.id == product.id);
    final isAdding = !alreadyInFavorites;

    // Save state for rollback
    final previousState = state;

    if (state.hasValue) {
      if (isAdding) {
        // Optimistically add and guard against duplicates
        if (!alreadyInFavorites) {
          state = AsyncData([...currentList, product.copyWith(isFavorite: true)]);
        }
      } else {
        // Optimistically remove
        state = AsyncData(
          currentList.where((p) => p.id != product.id).toList(),
        );
      }
    }

    try {
      // 2. Perform API call
      await service.toggleFavorite(product.id);

      // 3. Instead of invalidateSelf (which causes a loading spinner), 
      // we only refresh other dependent providers in the background
      // to keep the isFavorite flag in sync elsewhere.
      
      // We don't invalidateSelf() here to keep the optimistic transition smooth.
      // If we really need a fresh list, we can use ref.refresh() or just let it be.
      
      ref.invalidate(homeProductsProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(productDetailProvider(product.id));
    } catch (e) {
      // Rollback on error
      state = previousState;
      rethrow;
    }
  }
}

// User Profile Provider (moved to auth_providers.dart)


// Seller Profile Provider (Public)
final sellerProfileProvider = FutureProvider.autoDispose
    .family<UserModel, String>((ref, id) async {
      final service = ref.watch(usersServiceProvider);
      return service.getPublicProfile(id);
    });

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<ProductModel>>(() {
      return FavoritesNotifier();
    });

/// Provider pour vérifier si un produit est dans les favoris
final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.maybeWhen(
    data: (favorites) => favorites.any((p) => p.id == productId),
    orElse: () => false,
  );
});

// Dernier message reçu via socket (global)
final lastIncomingMessageProvider = StateProvider<MessageModel?>((ref) => null);

// Conversation actuellement ouverte dans l'écran de chat (ou null)
final currentChatConversationIdProvider = StateProvider<String?>((ref) => null);

// Socket.io global pour le chat
final chatSocketProvider = Provider<IO.Socket?>((ref) {
  final baseUrl = AppConstants.mediaBaseUrl;
  final token = ref.watch(authTokenProvider);

  if (token == null) {
    print('DEBUG: Socket - No token available, postponing connection');
    return null;
  }

  // Ensure no double slash
  final socketUrl = baseUrl.endsWith('/') 
      ? '${baseUrl}chat' 
      : '$baseUrl/chat';

  print('DEBUG: Connecting to Socket: $socketUrl with token');

  final socket = IO.io(
    socketUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .build(),
  );

  socket
    ..onConnect((_) {
      print('DEBUG: Socket connected to /chat namespace');
      final userId = ref.read(userIdProvider).value;
      if (userId != null) {
        print('DEBUG: Socket emitting identify for user $userId');
        socket.emit('identify', {'userId': userId});
      }
    })
    ..onConnectError((err) {
      print('DEBUG: Socket connection error: $err');
    })
    ..onReconnect((_) {
      print('DEBUG: Socket reconnected');
    })
    ..on('new_message', (data) {
      print('DEBUG: Socket received new_message event: $data');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final message = MessageModel.fromJson(map);

        // Déférer les modifications de providers pour éviter l'erreur
        // "Tried to modify a provider while the widget tree is building"
        Future.microtask(() {
          print('DEBUG: Dispatched new_message to lastIncomingMessageProvider');
          // Met à jour le dernier message reçu
          ref.read(lastIncomingMessageProvider.notifier).state = message;

          // Rafraîchit les conversations et la conversation ciblée
          ref.invalidate(conversationsProvider);
          ref.invalidate(conversationMessagesProvider(message.conversationId));
          
          // AUSSI : rafraîchir le compteur de notifications non lues (point rouge)
          ref.invalidate(unreadNotificationsCountProvider);
        });
      }
    })
    ..connect();

  ref.onDispose(() {
    socket.dispose();
  });

  return socket;
});

// Conversations list
final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
      final service = ref.watch(chatServiceProvider);
      return service.getConversations();
    });

// Single conversation
final conversationProvider = FutureProvider.autoDispose
    .family<ConversationModel, String>((ref, id) async {
      final service = ref.watch(chatServiceProvider);
      return service.getConversation(id);
    });

// Messages for a conversation
final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, String>((ref, conversationId) async {
      final service = ref.watch(chatServiceProvider);
      return service.getMessages(conversationId);
    });

/// Provider pour calculer le nombre total de messages non lus
final unreadMessagesCountProvider = Provider.autoDispose<int>((ref) {
  final conversationsAsync = ref.watch(conversationsProvider);
  final currentUserId = ref.watch(userIdProvider).value;

  return conversationsAsync.maybeWhen(
    data: (conversations) {
      int total = 0;
      for (final convo in conversations) {
        // Compter les messages non lus dans cette conversation par rapport au user actuel
        // Note: Le backend devrait aussi envoyer l'info isRead par message
        // On vérifie si le dernier message est lu et s'il ne vient pas de nous
        if (convo.messages.isNotEmpty) {
          final lastMsg = convo.messages.last;
          if (!lastMsg.isRead && lastMsg.senderId != currentUserId) {
            // Ici on simplifie : si le dernier est non lu et pas de nous, on compte 1
            // Dans un système réel, on compterait tous les messages non lus par convo
            total += 1;
          }
        }
      }
      return total;
    },
    orElse: () => 0,
  );
});
