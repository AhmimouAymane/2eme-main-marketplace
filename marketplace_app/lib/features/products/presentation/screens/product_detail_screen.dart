import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/utils/formatters.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/models/address_model.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/models/order_model.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/shared/models/comment_model.dart';
import 'package:marketplace_app/shared/providers/system_settings_provider.dart';
import 'package:marketplace_app/shared/widgets/full_screen_image_viewer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  // IMPROVEMENT: PageController gives us smooth programmatic control & better perf
  late final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(productDetailProvider(widget.productId)).when(
      data: (product) => _buildContent(context, product),
      // IMPROVEMENT: Use a proper skeleton/shimmer instead of a bare spinner
      loading: () => const _ProductDetailSkeleton(),
      error: (error, stack) {
        final is404 = error is DioException && error.response?.statusCode == 404;
        final message = is404
            ? 'Cette annonce n\'est plus disponible\n(supprimée ou vendue).'
            : (error is DioException ? error.message : error.toString()) ??
                'Une erreur est survenue';

        return Scaffold(
          appBar: AppBar(title: const Text('Annonce indisponible')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    is404 ? Icons.inventory_2_outlined : Icons.wifi_off_outlined,
                    size: 72,
                    color: Colors.grey[350],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                  ),
                  // IMPROVEMENT: Add retry for non-404 errors
                  if (!is404) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(productDetailProvider(widget.productId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ProductModel product) {
    final images = product.fullImageUrls;

    // IMPROVEMENT: Compute isOwner once, cleanly, avoid nested maybeWhen noise
    final currentUserId = ref.watch(userIdProvider).valueOrNull;
    final isOwner = currentUserId != null && currentUserId == product.sellerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildImageSliver(images),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceAndFavorite(context, product),
                  const SizedBox(height: 8),
                  Text(
                    product.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // IMPROVEMENT: Grouped info in a styled card instead of raw rows
                  _buildProductInfoCard(context, product),
                  const SizedBox(height: 16),
                  _buildSellerCard(context, product),
                  const SizedBox(height: 20),
                  // IMPROVEMENT: Collapsible description if long
                  _buildDescription(context, product),
                  const SizedBox(height: 28),
                  _buildReviewsSection(product, isOwner),
                  const SizedBox(height: 24),
                  _buildCommentsSection(product, isOwner),
                  const SizedBox(height: 100), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, product, isOwner),
    );
  }

  // ─── Image Sliver ────────────────────────────────────────────────────────────

  Widget _buildImageSliver(List<String> images) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      // IMPROVEMENT: stretch gives a nice parallax rubber-band feel on iOS
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.isEmpty ? 1 : images.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (context, index) {
                if (images.isEmpty) {
                  return Container(
                    color: Colors.grey[100],
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 64, color: Colors.grey[300]),
                  );
                }
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                        imageUrls: images, initialIndex: index),
                  )),
                  child: Hero(
                    // IMPROVEMENT: Hero tag tied to productId, not just index
                    tag: 'product_${widget.productId}_img_$index',
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      // IMPROVEMENT: Show a shimmer placeholder while loading
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(color: Colors.grey[200]),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.broken_image_outlined,
                            size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
            // IMPROVEMENT: Gradient at bottom so back arrow stays visible
            Positioned(
              top: 0, left: 0, right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black38, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Page dots indicator
            if (images.length > 1)
              Positioned(
                bottom: 14, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final isActive = _currentImageIndex == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      // IMPROVEMENT: Active dot is wider, not just brighter
                      width: isActive ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                      ),
                    );
                  }),
                ),
              ),
            // IMPROVEMENT: Image counter badge (e.g. "2 / 5")
            if (images.length > 1)
              Positioned(
                bottom: 12, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Price & Favorite ────────────────────────────────────────────────────────

  Widget _buildPriceAndFavorite(BuildContext context, ProductModel product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            Formatters.price(product.price),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.cloviGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // IMPROVEMENT: Show sold badge prominently
        if (!product.isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'VENDU',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Consumer(
          builder: (context, ref, _) {
            final isFav = ref.watch(isFavoriteProvider(product.id));
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isFav),
                  color: isFav ? AppColors.error : Colors.grey,
                ),
              ),
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).toggleFavorite(product),
            );
          },
        ),
      ],
    );
  }

  // ─── Product Info Card ───────────────────────────────────────────────────────

  // IMPROVEMENT: Group product specs in a visual card with dividers
  Widget _buildProductInfoCard(BuildContext context, ProductModel product) {
    final rows = <_InfoItem>[
      _InfoItem('Marque', product.brand.isEmpty ? 'Non spécifiée' : product.brand,
          Icons.label_outline),
      _InfoItem('Taille', product.size.isEmpty ? 'Non spécifiée' : product.size,
          Icons.straighten_outlined),
      _InfoItem('État', _conditionLabel(product.condition.name),
          Icons.verified_outlined),
      _InfoItem('Catégorie', product.category, Icons.category_outlined),
      if (product.sellerCity != null)
        _InfoItem('Ville', product.sellerCity!, Icons.location_on_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: Colors.grey[500]),
                    const SizedBox(width: 10),
                    Text(item.label,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                    const Spacer(),
                    // IMPROVEMENT: Condition gets a colored chip
                    if (item.label == 'État')
                      _buildConditionChip(product.condition.name)
                    else
                      Text(item.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(height: 1, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConditionChip(String conditionName) {
    final (label, color) = switch (conditionName) {
      'newWithTags' => ('Neuf avec étiquette', Colors.green),
      'newWithoutTags' => ('Neuf sans étiquette', Colors.lightGreen),
      'veryGood' => ('Très bon état', Colors.teal),
      'good' => ('Bon état', Colors.blue),
      'fair' => ('État correct', Colors.orange),
      _ => ('Usé', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _conditionLabel(String raw) => switch (raw) {
        'newWithTags' => 'Neuf avec étiquette',
        'newWithoutTags' => 'Neuf sans étiquette',
        'veryGood' => 'Très bon état',
        'good' => 'Bon état',
        'fair' => 'État correct',
        _ => raw.toUpperCase(),
      };

  // ─── Seller Card ─────────────────────────────────────────────────────────────

  Widget _buildSellerCard(BuildContext context, ProductModel product) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/seller/${product.sellerId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cloviGreen.withOpacity(0.15),
                backgroundImage: (product.sellerAvatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(product.sellerAvatarUrl!)
                    : null,
                child: (product.sellerAvatarUrl?.isEmpty ?? true)
                    ? Text(
                        (product.sellerName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.cloviGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerName ?? 'Vendeur anonyme',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // IMPROVEMENT: Cleaner subtitle
                      [
                        'Membre depuis ${Formatters.date(product.createdAt)}',
                        if (product.sellerCity != null) product.sellerCity!,
                      ].join(' • '),
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────────

  // IMPROVEMENT: Expandable description for long texts
  Widget _buildDescription(BuildContext context, ProductModel product) {
    const maxLines = 4;
    final isLong = product.description.length > 200;

    return _ExpandableText(
      text: product.description,
      maxLines: isLong ? maxLines : null,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection(ProductModel product, bool isOwner) {
    // IMPROVEMENT: Show average rating prominently when reviews exist
    final hasReviews = product.reviews.isNotEmpty;
    final avgRating = hasReviews
        ? product.reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            product.reviews.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Avis',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (hasReviews) ...[
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              Text(avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(' (${product.reviews.length})',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ] else
              Text('(0)',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 13)),
            const Spacer(),
            if (!isOwner)
              TextButton.icon(
                onPressed: () => _showAddReviewDialog(product),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Avis'),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasReviews)
          _buildEmptyState(
              Icons.chat_bubble_outline, 'Aucun avis pour le moment')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.reviews.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey.shade100, height: 24),
            itemBuilder: (context, index) {
              final review = product.reviews[index];
              return _ReviewTile(review: review);
            },
          ),
      ],
    );
  }

  // ─── Comments ────────────────────────────────────────────────────────────────

  Widget _buildCommentsSection(ProductModel product, bool isOwner) {
    // Group comments: Map of parentId -> list of children
    final Map<String?, List<CommentModel>> grouped = {};
    for (var c in product.comments) {
      grouped.putIfAbsent(c.parentCommentId, () => []).add(c);
    }

    final rootComments = grouped[null] ?? [];
    // Sort root comments by newest first (as they come from backend) or keep as is
    // Root comments are usually the questions

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Questions & Réponses',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('(${product.comments.length})',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddCommentDialog(product),
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('Question'),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (product.comments.isEmpty)
          _buildEmptyState(
              Icons.question_answer_outlined, 'Aucune discussion pour le moment')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rootComments.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey.shade100, height: 20),
            itemBuilder: (context, index) {
        final comment = rootComments[index];
        final currentUserId = ref.watch(userIdProvider).value;
        return _CommentThread(
          comment: comment,
          product: product,
          replies: grouped[comment.id] ?? [],
          currentUserId: currentUserId,
          onReply: (parent) => _showAddCommentDialog(product, parentCommentId: parent.id),
          onEdit: (c) => _showAddCommentDialog(product, commentToEdit: c),
          onDelete: (c) => _confirmDeleteComment(c),
        );
      },
          ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[350]),
          const SizedBox(width: 8),
          Text(message,
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar(
      BuildContext context, ProductModel product, bool isOwner) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // IMPROVEMENT: subtle top shadow so bar feels elevated
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            if (!isOwner) ...[
              // Chat button
              _CircleActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => _openChat(context, product),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: product.isAvailable
                      ? () => _showOfferDialog(context, product)
                      : null,
                  child: const Text('Faire une offre'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: product.isAvailable
                      ? () => _showPurchaseDialog(context, product)
                      : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cloviGreen),
                  child: Text(product.isAvailable ? 'Acheter' : 'Vendu'),
                ),
              ),
            ] else ...[
              if (product.isEditable)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.createProduct, extra: product),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier mon annonce'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cloviGreen),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_clock_outlined,
                            color: Colors.grey[500], size: 16),
                        const SizedBox(width: 8),
                        Text('Commande en cours',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _openChat(BuildContext context, ProductModel product) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/conversations/product/${product.id}');
      if (!mounted) return;
      final id = response.data['id'] as String?;
      if (id == null || id.isEmpty) throw Exception('ID manquant');
      context.push('/chat/$id');
    } catch (e) {
      if (!mounted) return;
      _showError(context, 'Impossible d\'ouvrir la messagerie: $e');
    }
  }

  void _showPurchaseDialog(BuildContext context, ProductModel product) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => _CheckoutDialog(
        product: product,
        onConfirm: (addr, svc, ship, total) => _createOrder(
          context, dlgCtx, product, addr,
          OrderStatus.awaitingSellerConfirmation,
          serviceFee: svc, shippingFee: ship, totalPrice: total,
        ),
        onCancel: () => Navigator.pop(dlgCtx),
      ),
    );
  }

  void _showOfferDialog(BuildContext context, ProductModel product) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faire une offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prix actuel : ${Formatters.price(product.price)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Votre offre',
                prefixText: 'DH ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val == null || val <= 0) return;
              Navigator.pop(context);
              showDialog<void>(
                context: context,
                builder: (dlgCtx) => _CheckoutDialog(
                  product: product.copyWith(price: val),
                  onConfirm: (addr, svc, ship, total) => _createOrder(
                    context, dlgCtx, product.copyWith(price: val), addr,
                    OrderStatus.offerMade,
                    serviceFee: svc, shippingFee: ship, totalPrice: total,
                  ),
                  onCancel: () => Navigator.pop(dlgCtx),
                ),
              );
            },
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrder(
    BuildContext context,
    BuildContext dlgCtx,
    ProductModel product,
    String shippingAddress,
    OrderStatus status, {
    required double serviceFee,
    required double shippingFee,
    required double totalPrice,
  }) async {
    Navigator.pop(dlgCtx);
    try {
      await ref.read(ordersServiceProvider).createOrder(
            OrderModel(
              id: '',
              productId: product.id,
              buyerId: '',
              sellerId: product.sellerId,
              totalPrice: totalPrice,
              serviceFee: serviceFee,
              shippingFee: shippingFee,
              status: status,
              shippingAddress: shippingAddress.trim(),
              createdAt: DateTime.now(),
              updatedAt: null,
              deliveredAt: null,
            ),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == OrderStatus.offerMade
              ? '✅ Offre envoyée au vendeur !'
              : '✅ Commande créée. Paiement à la livraison.'),
          backgroundColor: AppColors.cloviGreen,
        ),
      );
      ref
        ..invalidate(productsProvider)
        ..invalidate(productDetailProvider(product.id));
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is DioException && e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString() ?? e.toString()
          : e.toString();
      _showError(context, 'Erreur: $msg');
    }
  }

  void _showAddReviewDialog(ProductModel product) {
    int rating = 5;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Donner votre avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMPROVEMENT: Star row with label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => rating = i + 1),
                    child: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(_ratingLabel(rating),
                  style: TextStyle(
                      color: Colors.amber[800], fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                try {
                  await ref
                      .read(productsServiceProvider)
                      .addReview(product.id, rating, ctrl.text.trim());
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ref.invalidate(productDetailProvider(product.id));
                  _showSuccess(context, 'Avis ajouté !');
                } catch (e) {
                  _showError(context, 'Erreur: $e');
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCommentDialog(ProductModel product,
      {String? parentCommentId, CommentModel? commentToEdit}) {
    final ctrl = TextEditingController(text: commentToEdit?.content);
    final isEdit = commentToEdit != null;
    final isReply = parentCommentId != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit
            ? 'Modifier'
            : (isReply ? 'Répondre' : 'Poser une question')),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEdit
                ? 'Écrivez votre message ici…'
                : (isReply
                    ? 'Écrivez votre réponse ici…'
                    : 'Écrivez votre question ici…'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final content = ctrl.text.trim();
              if (content.isEmpty) return;
              try {
                final service = ref.read(productsServiceProvider);
                if (isEdit) {
                  await service.updateComment(commentToEdit.id, content);
                } else {
                  await service.addComment(product.id, content,
                      parentCommentId: parentCommentId);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ref.invalidate(productDetailProvider(product.id));
                _showSuccess(
                    context,
                    isEdit
                        ? 'Message mis à jour !'
                        : (isReply ? 'Réponse envoyée !' : 'Question envoyée !'));
              } catch (e) {
                _showError(context, 'Erreur: $e');
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text(
            'Voulez-vous vraiment supprimer ce message ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(productsServiceProvider)
                    .deleteComment(comment.id);
                if (!mounted) return;
                Navigator.pop(ctx);
                ref.invalidate(productDetailProvider(comment.productId));
                _showSuccess(context, 'Message supprimé');
              } catch (e) {
                _showError(context, 'Erreur: $e');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  String _ratingLabel(int r) => switch (r) {
        1 => 'Très mauvais',
        2 => 'Mauvais',
        3 => 'Correct',
        4 => 'Bien',
        _ => 'Excellent !',
      };

  void _showSuccess(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.cloviGreen),
      );

  void _showError(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
}

// ─── Helper data class ────────────────────────────────────────────────────────

class _InfoItem {
  final String label, value;
  final IconData icon;
  const _InfoItem(this.label, this.value, this.icon);
}

// ─── Extracted sub-widgets ────────────────────────────────────────────────────

/// IMPROVEMENT: Extracted to its own widget → avoids rebuilding parent on state change
class _ReviewTile extends StatelessWidget {
  final dynamic review; // replace with your ReviewModel type
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[200],
          backgroundImage: (review.user?.avatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(review.user!.avatarUrl!)
              : null,
          child: (review.user?.avatarUrl?.isEmpty ?? true)
              ? Icon(Icons.person, size: 16, color: Colors.grey[400])
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(review.user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Text(Formatters.date(review.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 14,
                  color: i < review.rating ? Colors.amber : Colors.grey[300],
                )),
              ),
              if (review.comment?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(review.comment!,
                    style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentThread extends StatelessWidget {
  final CommentModel comment;
  final ProductModel product;
  final List<CommentModel> replies;
  final String? currentUserId;
  final Function(CommentModel) onReply;
  final Function(CommentModel) onEdit;
  final Function(CommentModel) onDelete;

  const _CommentThread({
    required this.comment,
    required this.product,
    required this.replies,
    this.currentUserId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentTile(
          comment: comment,
          product: product,
          currentUserId: currentUserId,
          onReply: () => onReply(comment),
          onEdit: () => onEdit(comment),
          onDelete: () => onDelete(comment),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 8),
            child: Column(
              children: replies
                  .map((reply) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CommentTile(
                          comment: reply,
                          product: product,
                          currentUserId: currentUserId,
                          isReply: true,
                          onEdit: () => onEdit(reply),
                          onDelete: () => onDelete(reply),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final ProductModel product;
  final String? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    required this.product,
    this.currentUserId,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSeller = comment.userId == product.sellerId;
    final isOwner = currentUserId != null && comment.userId == currentUserId;
    final canDelete = isOwner || (currentUserId != null && product.sellerId == currentUserId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 12 : 14,
          backgroundColor: Colors.grey[100],
          backgroundImage: (comment.user?.avatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(comment.user!.avatarUrl!)
              : null,
          child: (comment.user?.avatarUrl?.isEmpty ?? true)
              ? Icon(Icons.person, size: isReply ? 12 : 14, color: Colors.grey[400])
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(comment.user?.fullName ?? 'Utilisateur',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: isReply ? 12 : 13)),
                  if (isSeller) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.cloviGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Vendeur',
                          style: TextStyle(
                              color: AppColors.cloviGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const Spacer(),
                  Text(Formatters.relativeTime(comment.createdAt),
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 11)),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 100),
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
                        if (isOwner)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Modifier', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        if (canDelete)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                                const SizedBox(width: 8),
                                Text('Supprimer', 
                                    style: TextStyle(fontSize: 13, color: Colors.red[400])),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(comment.content,
                  style: TextStyle(fontSize: isReply ? 12 : 13)),
              if (onReply != null && currentUserId != null)
                GestureDetector(
                  onTap: onReply,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Répondre',
                        style: TextStyle(
                            color: AppColors.cloviGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// IMPROVEMENT: Skeleton screen while loading — much better UX than a spinner
class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Image placeholder
          Container(height: 320, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(height: 28, width: 120),
                const SizedBox(height: 10),
                _shimmer(height: 20, width: double.infinity),
                const SizedBox(height: 6),
                _shimmer(height: 20, width: 200),
                const SizedBox(height: 20),
                _shimmer(height: 110, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer({required double height, required double width}) =>
      Container(
        height: height,
        width: width,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

/// IMPROVEMENT: Expandable text for long descriptions
class _ExpandableText extends StatefulWidget {
  final String text;
  final int? maxLines;
  final TextStyle? style;
  const _ExpandableText({required this.text, this.maxLines, this.style});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.maxLines == null) {
      return Text(widget.text, style: widget.style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _expanded ? 'Voir moins' : 'Voir plus',
              style: TextStyle(
                  color: AppColors.cloviGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

/// IMPROVEMENT: Reusable circle icon button for the bottom bar
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Icon(icon, size: 22),
      ),
    );
  }
}

// ─── _CheckoutDialog (unchanged logic, minor UI polish) ──────────────────────
// Keep your existing _CheckoutDialog — it's already well-structured.
// Minor suggestions:
// 1. Replace AlertDialog with a BottomSheet for better mobile UX on small screens
// 2. Use FilledButton instead of ElevatedButton for the confirm action
// 3. Add a loading state on the confirm button to prevent double-taps
/// Dialog de checkout : paiement à la livraison + adresse de livraison
class _CheckoutDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  final void Function(
    String shippingAddress,
    double serviceFee,
    double shippingFee,
    double totalPrice,
  ) onConfirm;
  final VoidCallback onCancel;

  const _CheckoutDialog({
    required this.product,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  ConsumerState<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<_CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  AddressModel? _selectedAddress;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final userAsync = ref.watch(userIdProvider);


    return ref.watch(systemSettingsProvider).when(
      data: (settings) {
        final double serviceFee = (product.price * (settings.serviceFeePercentage / 100)).ceilToDouble();
        final double shippingFee = settings.shippingFee;
        final double totalPayable = product.price + serviceFee + shippingFee;

        return AlertDialog(
          title: const Text(
            'Vérifier votre commande',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Card
                  _buildSectionCard(
                    context,
                    'Résumé du paiement',
                    Column(
                      children: [
                        _buildSummaryRow('Prix du produit', product.price),
                        _buildSummaryRow(
                          'Frais de service (${settings.serviceFeePercentage.toStringAsFixed(1)}%)',
                          serviceFee,
                        ),
                        _buildSummaryRow('Frais de livraison', shippingFee),
                        const Divider(height: 20),
                        _buildSummaryRow('Total à payer', totalPayable, isBold: true),
                      ],
                    ),
                  ),

              const SizedBox(height: 16),

              // Address Section
              userAsync.when(
                data: (userId) {
                  if (userId == null) return const Text('Non connecté');
                  return ref.watch(userAddressesProvider(userId)).when(
                        data: (addrs) {
                          if (addrs.isEmpty) {
                            return _buildSectionCard(
                              context,
                              'Adresse de livraison',
                              Column(
                                children: [
                                  const Text(
                                    'Aucune adresse enregistrée.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => context.push(AppRoutes.addresses),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ajouter une adresse'),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Auto-select once
                          if (_selectedAddress == null) {
                            _selectedAddress = addrs.firstWhere(
                              (a) => a.isDefault,
                              orElse: () => addrs.first,
                            );
                            if (_selectedAddress?.phone != null && _phoneController.text.isEmpty) {
                              _phoneController.text = _selectedAddress!.phone!;
                            }
                          }

                          return _buildSectionCard(
                            context,
                            'Adresse de livraison',
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Indiquez où le livreur livrera le colis :',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<AddressModel>(
                                        value: _selectedAddress,
                                        decoration: InputDecoration(
                                          labelText: 'Adresse de livraison',
                                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: addrs
                                            .map((a) => DropdownMenuItem(
                                                  value: a,
                                                  child: Text(a.label, style: const TextStyle(fontSize: 14)),
                                                ))
                                            .toList(),
                                        onChanged: (a) {
                                          setState(() {
                                            _selectedAddress = a;
                                            if (a?.phone != null) {
                                              _phoneController.text = a!.phone!;
                                            }
                                          });
                                        },
                                        validator: (a) => a == null ? 'Requis' : null,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => context.push(AppRoutes.addresses),
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.cloviGreen),
                                      tooltip: 'Ajouter une adresse',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Téléphone de contact',
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Requis pour le livreur'
                                      : (v.length < 10 ? 'Numéro invalide' : null),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Erreur: $e'),
                      );
                },
                loading: () => const SizedBox(height: 100),
                error: (e, _) => Text('Erreur: $e'),
              ),
              
              const SizedBox(height: 16),
              
              // Payment info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Paiement à la livraison.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _selectedAddress == null
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final addressText =
                        '${_selectedAddress!.street}, ${_selectedAddress!.postal} ${_selectedAddress!.city}';
                    final phone = _phoneController.text.trim();
                    var payload = addressText;
                    if (phone.isNotEmpty) {
                      payload = '$payload — Tél: $phone';
                    }
                    widget.onConfirm(payload, serviceFee, shippingFee, totalPayable);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cloviGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirmer'),
        ),
      ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur settings: $e')),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.cloviGreen : Colors.grey[700],
            ),
          ),
          Text(
            Formatters.price(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.cloviGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
