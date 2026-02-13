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
import 'package:marketplace_app/features/users/data/users_service.dart';
import 'package:marketplace_app/shared/models/order_model.dart';
import 'package:marketplace_app/shared/models/user_model.dart';
import 'package:marketplace_app/shared/models/conversation_model.dart';
import 'package:marketplace_app/features/chat/data/chat_service.dart';

// Services
final usersServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return UsersService(dio);
});

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

final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoriesServiceProvider);
  return service.getCategories();
});

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
    state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
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

final productFilterProvider = NotifierProvider<ProductFilterNotifier, ProductFilters>(() {
  return ProductFilterNotifier();
});

final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final filters = ref.watch(productFilterProvider);
  final service = ref.watch(productsServiceProvider);
  
  print('Fetching products with filters: search=${filters.search}, categoryId=${filters.categoryId}, price=[${filters.minPrice}-${filters.maxPrice}]');
  
  return service.getProducts(
    search: filters.search,
    category: filters.categoryId,
    minPrice: filters.minPrice,
    maxPrice: filters.maxPrice,
  );
});

// Provider pour l'accueil (ignore les filtres de recherche et de prix)
final homeProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final filters = ref.watch(productFilterProvider);
  final service = ref.watch(productsServiceProvider);
  
  return service.getProducts(
    category: filters.categoryId,
  );
});

// User Products Provider (My Ads)
final userProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final userId = await ref.watch(userIdProvider.future);
  if (userId == null) return [];
  
  final service = ref.watch(productsServiceProvider);
  return service.getProducts(sellerId: userId);
});

// Single Product Provider
final productDetailProvider = FutureProvider.autoDispose.family<ProductModel, String>((ref, id) async {
  final service = ref.watch(productsServiceProvider);
  return service.getProduct(id);
});

// Buyer Orders Provider
final buyerOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final service = ref.watch(ordersServiceProvider);
  return service.getBuyerOrders();
});

// Seller Orders Provider
final sellerOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final service = ref.watch(ordersServiceProvider);
  return service.getSellerOrders();
});

// Favorites Notifier
class FavoritesNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    final service = ref.watch(favoritesServiceProvider);
    return service.getFavorites();
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final service = ref.read(favoritesServiceProvider);
    
    // Optimistic update
    final previousState = state;
    final isAdding = !product.isFavorite;
    
    // Create new list for state
    if (state.hasValue) {
      final currentList = state.value!;
      if (isAdding) {
        state = AsyncData([...currentList, product.copyWith(isFavorite: true)]);
      } else {
        state = AsyncData(currentList.where((p) => p.id != product.id).toList());
      }
    }

    try {
      await service.toggleFavorite(product.id);
      // Refresh after toggle to be sure
      ref.invalidateSelf();
      
      // Also invalidate productsProvider to update isFavorite flag there
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

// User Profile Provider (Current User)
final userProfileProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final service = ref.watch(usersServiceProvider);
  final userId = await ref.watch(userIdProvider.future);
  if (userId == null) return null;
  
  return service.getMe();
});

// Seller Profile Provider (Public)
final sellerProfileProvider = FutureProvider.autoDispose.family<UserModel, String>((ref, id) async {
  final service = ref.watch(usersServiceProvider);
  return service.getPublicProfile(id);
});

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<ProductModel>>(() {
  return FavoritesNotifier();
});

// Dernier message reçu via socket (global)
final lastIncomingMessageProvider = StateProvider<MessageModel?>((ref) => null);

// Conversation actuellement ouverte dans l'écran de chat (ou null)
final currentChatConversationIdProvider = StateProvider<String?>((ref) => null);

// Socket.io global pour le chat
final chatSocketProvider = Provider<IO.Socket>((ref) {
  final baseUrl = AppConstants.mediaBaseUrl; // ex: http://192.168.100.118:8080

  final socket = IO.io(
    '$baseUrl/chat',
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

  socket
    ..onConnect((_) {
      // Connecté au namespace /chat
    })
    ..on('new_message', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final message = MessageModel.fromJson(map);

        // Met à jour le dernier message reçu
        ref.read(lastIncomingMessageProvider.notifier).state = message;

        // Rafraîchit les conversations et la conversation ciblée
        ref.invalidate(conversationsProvider);
        ref.invalidate(conversationMessagesProvider(message.conversationId));
      }
    })
    ..connect();

  ref.onDispose(() {
    socket.dispose();
  });

  return socket;
});

// Conversations list
final conversationsProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  final service = ref.watch(chatServiceProvider);
  return service.getConversations();
});

// Single conversation
final conversationProvider =
    FutureProvider.autoDispose.family<ConversationModel, String>((ref, id) async {
  final service = ref.watch(chatServiceProvider);
  return service.getConversation(id);
});

// Messages for a conversation
final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, String>((ref, conversationId) async {
  final service = ref.watch(chatServiceProvider);
  return service.getMessages(conversationId);
});
