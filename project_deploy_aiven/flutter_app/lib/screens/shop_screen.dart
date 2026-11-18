import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_service.dart';
import '../models.dart';
import '../widgets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _search = TextEditingController();
  final Map<int, int> _quantities = {};
  List<Product> _products = [];
  List<CartItem> _cart = [];
  User? _user;
  bool _loading = true;
  bool _checkingOut = false;
  int? _updatingCartId;
  String? _error;
  String? _notice;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait<dynamic>([
        apiService.currentUser(),
        apiService.products(),
      ]);
      final user = results[0] as User?;
      final products = results[1] as List<Product>;
      if (user?.role == 'admin') {
        if (mounted) Navigator.of(context).pushReplacementNamed('/maker');
        return;
      }
      final cart = user == null ? <CartItem>[] : await apiService.cart();
      if (!mounted) return;
      setState(() {
        _user = user;
        _products = products;
        _cart = cart;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat toko.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh({bool showLoading = false}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final products = await apiService.products();
      final cart = _user == null ? <CartItem>[] : await apiService.cart();
      if (!mounted) return;
      setState(() {
        _products = products;
        _cart = cart;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memperbarui katalog.');
    } finally {
      if (showLoading && mounted) setState(() => _loading = false);
    }
  }

  int get _cartCount =>
      _cart.fold(0, (total, item) => total + item.quantity);

  int get _cartTotal =>
      _cart.fold(0, (total, item) => total + item.price * item.quantity);

  List<Product> get _filteredProducts {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((product) {
      return '${product.name} ${product.category} ${product.description}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  Future<void> _addToCart(Product product) async {
    final quantity = _quantities[product.id] ?? 1;
    if (quantity < 1 || quantity > product.stock) {
      setState(() => _error = 'Jumlah produk tidak valid atau melebihi stok.');
      return;
    }
    setState(() {
      _error = null;
      _notice = null;
      _updatingCartId = product.id;
    });
    try {
      final current = _cart
          .where((item) => item.productId == product.id)
          .fold(0, (sum, item) => sum + item.quantity);
      await apiService.setCartQuantity(product.id, current + quantity);
      await _refresh();
      if (mounted) {
        setState(
          () => _notice =
              '${product.name} ditambahkan ke keranjang dan stok direservasi.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _updatingCartId = null);
    }
  }

  Future<void> _buyNow(Product product) async {
    final quantity = _quantities[product.id] ?? 1;
    if (quantity < 1 || quantity > product.stock) {
      setState(() => _error = 'Jumlah produk tidak valid atau melebihi stok.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi pembelian'),
        content: Text(
          'Apakah Anda ingin membeli ${product.name} × $quantity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, beli'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _error = null;
      _notice = null;
      _checkingOut = true;
    });
    try {
      await apiService.createOrder(
        productId: product.id,
        quantity: quantity,
      );
      await _refresh();
      if (mounted) {
        setState(
          () => _notice =
              'Pesanan dibuat. Admin akan menghubungi Anda untuk konfirmasi pembayaran.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _error = null);
    try {
      if (_user?.role != 'admin') await apiService.clearCart();
      await apiService.logout();
      if (!mounted) return;
      setState(() {
        _user = null;
        _cart = [];
        _notice = 'Logout berhasil.';
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _sendRequest() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Barang'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 3000,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Pesan',
                hintText: 'Tulis barang atau permintaan Anda...',
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Pesan wajib diisi.'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Kirim permintaan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null) return;
    try {
      final adminEmail = await apiService.sendRequest(message);
      if (!mounted) return;
      setState(() {
        _error = null;
        _notice = 'Permintaan tersimpan dan sudah masuk notifikasi admin.';
      });
      if (adminEmail != null && adminEmail.isNotEmpty) {
        final mailUri = Uri(
          scheme: 'mailto',
          path: adminEmail,
          queryParameters: {
            'subject': 'Permintaan barang dari pengguna',
            'body':
                'Nama: ${_user?.name}\nEmail: ${_user?.email}\n\n$message',
          },
        );
        await launchUrl(mailUri);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _showCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) {
          Future<void> updateCart(Future<void> Function() action) async {
            modalSetState(() => _error = null);
            try {
              await action();
              await _refresh();
              modalSetState(() {});
            } on ApiException catch (error) {
              modalSetState(() => _error = error.message);
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              20,
              22,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 640,
                maxHeight: MediaQuery.sizeOf(context).height * .82,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keranjang ($_cartCount)',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null) ErrorBanner(message: _error!),
                  if (_cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: EmptyState(title: 'Keranjang masih kosong.'),
                    )
                  else ...[
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _cart.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: MerchColors.line),
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${formatMoney(item.price)} × ${item.quantity}',
                            ),
                            trailing: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Kurangi jumlah',
                                  onPressed: item.quantity <= 1
                                      ? null
                                      : () => updateCart(
                                            () => apiService.setCartQuantity(
                                              item.productId,
                                              item.quantity - 1,
                                            ),
                                          ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  tooltip: 'Tambah jumlah',
                                  onPressed: item.quantity >= 99 ||
                                          item.stock < 1
                                      ? null
                                      : () => updateCart(
                                            () => apiService.setCartQuantity(
                                              item.productId,
                                              item.quantity + 1,
                                            ),
                                          ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Hapus',
                                  onPressed: () => updateCart(
                                    () => apiService
                                        .removeCartItem(item.productId),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: MerchColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: MerchColors.line),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          formatMoney(_cartTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: _checkingOut ? 'Memproses...' : 'Checkout',
                        icon: Icons.receipt_long,
                        busy: _checkingOut,
                        onPressed: _checkout,
                      ),
                    ),
                  ],
                  if (_cart.isEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Lihat produk'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkout() async {
    if (_user == null) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/auth');
      return;
    }
    if (_cart.isEmpty) return;
    setState(() {
      _checkingOut = true;
      _error = null;
    });
    try {
      await apiService.checkout(_cart);
      if (!mounted) return;
      setState(() {
        _cart = [];
        _notice =
            'Pesanan dibuat. Admin akan menghubungi Anda untuk konfirmasi pembayaran.';
      });
      Navigator.of(context).pop();
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    return Scaffold(
      appBar: MerchHeader(
        user: _user,
        cartCount: _cartCount,
        onCart: _showCart,
        onLogin: () => Navigator.of(context).pushNamed('/auth'),
        onLogout: _logout,
      ),
      body: ListView(
        children: [
          const MerchHero(
            eyebrow: 'Koleksi MerchBox',
            title: 'Temukan barang\nfavoritmu',
            subtitle: 'Produk pilihan yang sudah tersedia untuk dipesan',
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 38, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Cari barang',
                        hintText: 'Cari nama, kategori, atau deskripsi...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Produk tersedia',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Pesanan akan menunggu konfirmasi admin',
                                style: TextStyle(color: MerchColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _search.text.isEmpty
                              ? '${_products.length} produk'
                              : '${filtered.length} dari ${_products.length}',
                          style: const TextStyle(color: MerchColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ErrorBanner(message: _error!),
                    if (_notice != null) NoticeBanner(message: _notice!),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: MerchColors.accent,
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      EmptyState(
                        title: _products.isEmpty
                            ? 'Belum ada produk yang dipublikasikan.'
                            : 'Tidak ada barang yang cocok dengan pencarian.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final count = constraints.maxWidth >= 900
                              ? 3
                              : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 18),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: count == 1 ? .76 : .66,
                            ),
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              return ProductCard(
                                product: product,
                                quantity: _quantities[product.id] ?? 1,
                                onQuantityChanged: (value) => setState(
                                  () => _quantities[product.id] = value,
                                ),
                                onAddToCart: () => _addToCart(product),
                                onBuyNow: () => _buyNow(product),
                                onLogin: () =>
                                    Navigator.of(context).pushNamed('/auth'),
                                updating: _updatingCartId == product.id,
                              );
                            },
                          );
                        },
                      ),
                    if (_user != null) ...[
                      const SizedBox(height: 34),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: MerchColors.line)),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            const Text(
                              'Tidak menemukan barang yang dicari?',
                              style: TextStyle(color: MerchColors.muted),
                            ),
                            SecondaryButton(
                              label: 'Request Barang',
                              icon: Icons.chat_bubble_outline,
                              onPressed: _sendRequest,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
