import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:marketplace_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:marketplace_app/features/profile/presentation/screens/seller_profile_screen.dart';
import 'package:marketplace_app/features/products/presentation/screens/favorites_screen.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/features/chat/presentation/screens/conversations_screen.dart';
import 'package:marketplace_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:marketplace_app/features/addresses/presentation/screens/addresses_screen.dart';
import 'package:marketplace_app/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:marketplace_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:marketplace_app/features/profile/presentation/screens/help_support_screen.dart';
import 'package:marketplace_app/features/profile/presentation/screens/about_screen.dart';
import 'package:marketplace_app/shared/models/address_model.dart';
import 'package:marketplace_app/shared/widgets/app_shell.dart';
import 'package:marketplace_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:marketplace_app/features/verification/presentation/screens/seller_verification_screen.dart';

import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';

/// Provider pour le routeur Go Router
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isRegistering = state.matchedLocation == AppRoutes.register;

      if (!isAuthenticated && !isLoggingIn && !isRegistering) {
        return AppRoutes.login;
      }

      if (isAuthenticated && (isLoggingIn || isRegistering)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Auth routes (outside the shell — no nav bar)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RegisterScreen()),
      ),

      // Modal routes pushed on top of the shell (no nav bar)
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
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const OrdersScreen()),
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
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myProducts,
        name: 'my-products',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MyProductsScreen()),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const FavoritesScreen()),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        name: 'addresses',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const AddressesScreen()),
      ),
      GoRoute(
        path: AppRoutes.addressForm,
        name: 'address-form',
        pageBuilder: (context, state) {
          final addr = state.extra as AddressModel?;
          return MaterialPage(
            key: state.pageKey,
            child: AddressFormScreen(initial: addr),
          );
        },
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
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        name: 'help-support',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HelpSupportScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WalletScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerVerification,
        name: 'seller-verification',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SellerVerificationScreen(),
        ),
      ),

      // ──────────────────────────────────────────────────────────────
      // StatefulShellRoute: 4 branches with persistent nav bar
      // Branch 0 → Home (/)
      // Branch 1 → Search (/search)
      // Branch 2 → Messages (/conversations)
      // Branch 3 → Profile (/profile)
      // ──────────────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) =>
                    NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
              ),
            ],
          ),

          // Branch 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                pageBuilder: (context, state) =>
                    NoTransitionPage(key: state.pageKey, child: const SearchScreen()),
              ),
            ],
          ),

          // Branch 2: Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conversations,
                name: 'conversations',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ConversationsScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) =>
                    NoTransitionPage(key: state.pageKey, child: const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
