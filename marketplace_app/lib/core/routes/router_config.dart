import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/features/auth/presentation/screens/login_screen.dart';
import 'package:marketplace_app/features/auth/presentation/screens/register_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/home_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/product_detail_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/search_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/create_product_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/my_products_screen.dart';
import 'package:marketplace_app/features/orders/presentation/screens/orders_screen.dart';
import 'package:marketplace_app/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:marketplace_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:marketplace_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:marketplace_app/features/profile/presentation/screens/seller_profile_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/favorites_screen.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/features/chat/presentation/screens/conversations_screen.dart';
import 'package:marketplace_app/features/chat/presentation/screens/chat_screen.dart';

/// Configuration du routeur Go Router
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      
      // Home
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      
      // Products
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'product-detail',
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: ProductDetailScreen(productId: productId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createProduct,
        name: 'create-product',
        pageBuilder: (context, state) {
          final productToEdit = state.extra as ProductModel?;
          return MaterialPage(
            key: state.pageKey,
            child: CreateProductScreen(productToEdit: productToEdit),
          );
        },
      ),
      
      // Orders
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const OrdersScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        name: 'order-detail',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: OrderDetailScreen(orderId: orderId),
          );
        },
      ),
      
      // Profile
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.myProducts,
        name: 'my-products',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MyProductsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerProfile,
        name: 'seller-profile',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: SellerProfileScreen(userId: userId),
          );
        },
      ),

      // Chat
      GoRoute(
        path: AppRoutes.conversations,
        name: 'conversations',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ConversationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: ChatScreen(conversationId: conversationId),
          );
        },
      ),
    ],
  );
}
