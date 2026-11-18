import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';

abstract final class MerchColors {
  static const ink = Color(0xFF17202A);
  static const muted = Color(0xFF6D747D);
  static const line = Color(0xFFE7E1D8);
  static const accent = Color(0xFFEE6C4D);
  static const paper = Color(0xFFFFFDF9);
  static const soft = Color(0xFFF5EFE7);
  static const error = Color(0xFFB42318);
  static const success = Color(0xFF176B2C);
}

String formatMoney(int amount) => NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: TextStyle(
            color: MerchColors.ink,
            fontSize: compact ? 20 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
          children: const [
            TextSpan(text: 'MERCH'),
            TextSpan(
              text: 'BOX',
              style: TextStyle(color: MerchColors.accent),
            ),
          ],
        ),
      );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _MessageBox(
        message: message,
        color: const Color(0xFFFFF0EE),
        foreground: MerchColors.error,
        icon: Icons.error_outline,
      );
}

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _MessageBox(
        message: message,
        color: const Color(0xFFEDF9F0),
        foreground: MerchColors.success,
        icon: Icons.check_circle_outline,
      );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.foreground,
    required this.icon,
  });

  final String message;
  final Color color;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: foreground, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: MerchColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: MerchColors.ink,
          side: const BorderSide(color: MerchColors.ink),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      );
}

class MerchHeader extends StatelessWidget implements PreferredSizeWidget {
  const MerchHeader({
    super.key,
    this.user,
    this.cartCount,
    this.onCart,
    this.onLogin,
    this.onLogout,
    this.onRequests,
    this.onAddProduct,
    this.unreadCount = 0,
  });

  final User? user;
  final int? cartCount;
  final VoidCallback? onCart;
  final VoidCallback? onLogin;
  final VoidCallback? onLogout;
  final VoidCallback? onRequests;
  final VoidCallback? onAddProduct;
  final int unreadCount;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 650;
    return AppBar(
      title: const Brand(compact: true),
      titleSpacing: 24,
      actions: [
        if (isWide && user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text('Halo, ${user!.name}', overflow: TextOverflow.ellipsis),
            ),
          ),
        if (onCart != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              tooltip: 'Keranjang ($cartCount)',
              onPressed: onCart,
              icon: Badge(
                label: Text('${cartCount ?? 0}'),
                isLabelVisible: (cartCount ?? 0) > 0,
                backgroundColor: MerchColors.accent,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
        if (isWide) ...[
          if (onRequests != null)
            TextButton.icon(
              onPressed: onRequests,
              icon: Badge(
                label: Text('$unreadCount'),
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              label: const Text('Permintaan masuk'),
            ),
          if (onAddProduct != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: PrimaryButton(
                label: 'Tambah Barang',
                icon: Icons.add,
                onPressed: onAddProduct,
              ),
            ),
          if (user == null && onLogin != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SecondaryButton(
                label: 'Login untuk membeli',
                icon: Icons.login,
                onPressed: onLogin,
              ),
            ),
          if (user != null && onLogout != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 20),
              child: TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
        ] else
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (value) {
              switch (value) {
                case 'login':
                  onLogin?.call();
                case 'logout':
                  onLogout?.call();
                case 'requests':
                  onRequests?.call();
                case 'add':
                  onAddProduct?.call();
              }
            },
            itemBuilder: (context) => [
              if (user != null)
                PopupMenuItem(
                  enabled: false,
                  value: 'user',
                  child: Text('Halo, ${user!.name}'),
                ),
              if (onLogin != null)
                const PopupMenuItem(value: 'login', child: Text('Login')),
              if (onRequests != null)
                const PopupMenuItem(
                  value: 'requests',
                  child: Text('Permintaan masuk'),
                ),
              if (onAddProduct != null)
                const PopupMenuItem(
                  value: 'add',
                  child: Text('Tambah barang'),
                ),
              if (onLogout != null)
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class MerchHero extends StatelessWidget {
  const MerchHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 340),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/merchbox-hero.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xDDF5EFE7),
              Color(0xA6F5EFE7),
              Color(0x22F5EFE7),
            ],
            stops: [0, .54, 1],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width > 1120 ? (width - 1072) / 2 : 24,
            vertical: 58,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: MerchColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: MerchColors.ink,
                  fontSize: width < 600 ? 42 : 62,
                  height: .98,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: MerchColors.muted,
                    fontSize: 17,
                    height: 1.5,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.quantity = 1,
    this.onQuantityChanged,
    this.onAddToCart,
    this.onBuyNow,
    this.onLogin,
    this.onEdit,
    this.onDelete,
    this.updating = false,
    this.admin = false,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onLogin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool updating;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = width > 850 ? 210.0 : 230.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: MerchColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: imageHeight,
            child: _ProductImage(product: product),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryTag(category: product.category),
                      const Spacer(),
                      if (admin)
                        Text(
                          product.isPublished ? 'Tayang' : 'Draft',
                          style: TextStyle(
                            color: product.isPublished
                                ? MerchColors.success
                                : MerchColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MerchColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Text(
                      product.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MerchColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatMoney(product.price),
                        style: const TextStyle(
                          color: MerchColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Stok ${product.stock}',
                        style: const TextStyle(color: MerchColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (admin)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 17),
                            label: const Text('Hapus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MerchColors.error,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    _ShopActions(
                      product: product,
                      quantity: quantity,
                      onQuantityChanged: onQuantityChanged,
                      onAddToCart: onAddToCart,
                      onBuyNow: onBuyNow,
                      onLogin: onLogin,
                      updating: updating,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    if (imageUrl == null) return _placeholder();
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() => ColoredBox(
        color: MerchColors.soft,
        child: Center(
          child: Icon(
            product.category == 'Pin' ? Icons.push_pin : Icons.key,
            color: MerchColors.accent,
            size: 60,
          ),
        ),
      );
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) => Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: MerchColors.accent,
          fontSize: 11,
          letterSpacing: .8,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _ShopActions extends StatelessWidget {
  const _ShopActions({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onLogin,
    required this.updating,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onLogin;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    if (onLogin != null) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: 'Login untuk memesan',
          icon: Icons.login,
          onPressed: onLogin,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Jumlah'),
            const SizedBox(width: 12),
            SizedBox(
              width: 86,
              child: DropdownButtonFormField<int>(
                initialValue: quantity.clamp(1, product.stock.clamp(1, 99)),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                items: List.generate(
                  product.stock.clamp(0, 99),
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: product.stock < 1
                    ? null
                    : (value) {
                        if (value != null) onQuantityChanged?.call(value);
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: product.stock < 1 || updating ? null : onAddToCart,
              style: FilledButton.styleFrom(
                backgroundColor: MerchColors.accent,
                foregroundColor: Colors.white,
              ),
              child: updating
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Tambah ke keranjang'),
            ),
            OutlinedButton(
              onPressed: product.stock < 1 ? null : onBuyNow,
              child: const Text('Beli Sekarang'),
            ),
          ],
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inventory_2_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
        decoration: BoxDecoration(
          color: MerchColors.soft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: MerchColors.muted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MerchColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MerchColors.muted),
              ),
            ],
          ],
        ),
      );
}

class Footer extends StatelessWidget {
  const Footer({super.key, this.admin = false});

  final bool admin;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 28),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: MerchColors.line)),
        ),
        child: Text(
          admin ? 'MerchBox · Panel Maker' : 'MerchBox · Merchandise pilihan',
          textAlign: TextAlign.center,
          style: const TextStyle(color: MerchColors.muted),
        ),
      );
}
