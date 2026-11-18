import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_service.dart';
import '../models.dart';
import '../widgets.dart';

class MakerScreen extends StatefulWidget {
  const MakerScreen({super.key});

  @override
  State<MakerScreen> createState() => _MakerScreenState();
}

class _MakerScreenState extends State<MakerScreen> {
  User? _user;
  List<Product> _products = [];
  List<ProductRequest> _requests = [];
  bool _checkingSession = true;
  bool _showRequests = false;
  String? _error;
  String? _notice;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = await apiService.currentUser();
      if (user == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
        return;
      }
      if (user.role != 'admin') {
        if (mounted) Navigator.of(context).pushReplacementNamed('/shop');
        return;
      }
      if (mounted) setState(() => _user = user);
      await _loadAll();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _loadAll(showErrors: true),
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memeriksa sesi admin.');
    } finally {
      if (mounted) setState(() => _checkingSession = false);
    }
  }

  Future<void> _loadAll({bool showErrors = false}) async {
    try {
      final results = await Future.wait<Object>([
        apiService.products(admin: true),
        apiService.requests(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _requests = results[1] as List<ProductRequest>;
        if (showErrors) _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat panel maker.');
    }
  }

  int get _unreadCount => _requests.where((request) => !request.isRead).length;

  Future<void> _logout() async {
    try {
      await apiService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/shop');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _editProduct([Product? product]) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.name ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final price = TextEditingController(text: '${product?.price ?? 8000}');
    final stock = TextEditingController(text: '${product?.stock ?? 10}');
    final imageUrl = TextEditingController(text: product?.imageUrl ?? '');
    var category = product?.category ?? 'Gantungan Kunci';
    var published = product?.isPublished ?? false;

    final value = await showDialog<Product>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'Nama produk'),
                      validator: (value) => value?.trim().isNotEmpty == true
                          ? null
                          : 'Nama produk wajib diisi.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Gantungan Kunci',
                          child: Text('Gantungan Kunci'),
                        ),
                        DropdownMenuItem(value: 'Pin', child: Text('Pin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: price,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Harga (Rp)'),
                            validator: (value) =>
                                int.tryParse(value ?? '') != null &&
                                        int.parse(value!) >= 0
                                    ? null
                                    : 'Harga tidak valid.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stock,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stok'),
                            validator: (value) =>
                                int.tryParse(value ?? '') != null &&
                                        int.parse(value!) >= 0
                                    ? null
                                    : 'Stok tidak valid.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageUrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL gambar (opsional)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final uri = Uri.tryParse(value.trim());
                        return uri != null &&
                                (uri.scheme == 'https' || uri.scheme == 'http')
                            ? null
                            : 'URL gambar tidak valid.';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      minLines: 3,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(labelText: 'Deskripsi'),
                      validator: (value) => value?.trim().isNotEmpty == true
                          ? null
                          : 'Deskripsi wajib diisi.',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publikasikan produk'),
                      subtitle: const Text(
                        'Produk draft tidak tampil di katalog.',
                      ),
                      value: published,
                      activeTrackColor: MerchColors.accent,
                      onChanged: (value) =>
                          setDialogState(() => published = value),
                    ),
                  ],
                ),
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
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  Product(
                    id: product?.id ?? 0,
                    name: name.text.trim(),
                    description: description.text.trim(),
                    category: category,
                    price: int.parse(price.text),
                    stock: int.parse(stock.text),
                    imageUrl: imageUrl.text.trim().isEmpty
                        ? null
                        : imageUrl.text.trim(),
                    isPublished: published,
                  ),
                );
              },
              child: Text(product == null ? 'Tambah Produk' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    description.dispose();
    price.dispose();
    stock.dispose();
    imageUrl.dispose();
    if (value == null) return;

    try {
      await apiService.saveProduct(value, id: product?.id);
      await _loadAll();
      if (mounted) {
        setState(
          () => _notice = product == null
              ? 'Produk berhasil ditambahkan.'
              : 'Produk berhasil diperbarui.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Produk “${product.name}” akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MerchColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await apiService.deleteProduct(product.id);
      await _loadAll();
      if (mounted) setState(() => _notice = 'Produk berhasil dihapus.');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _markRead(ProductRequest request) async {
    try {
      await apiService.markRequestRead(request.id);
      await _loadAll();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _deleteRequest(ProductRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus notifikasi?'),
        content: const Text('Notifikasi permintaan ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await apiService.deleteRequest(request.id);
      await _loadAll();
      if (mounted) setState(() => _notice = 'Notifikasi berhasil dihapus.');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date.toLocal());
  }

  Future<void> _openEmail(String email) async {
    final opened = await launchUrl(Uri(scheme: 'mailto', path: email));
    if (!opened && mounted) {
      setState(() => _error = 'Tidak dapat membuka aplikasi email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: MerchColors.accent)),
      );
    }
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Akses admin diperlukan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(_error ?? 'Silakan login menggunakan akun admin.'),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Ke halaman login',
                  icon: Icons.login,
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/auth'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: MerchHeader(
        user: _user,
        unreadCount: _unreadCount,
        onRequests: () => setState(() => _showRequests = !_showRequests),
        onAddProduct: () => _editProduct(),
        onLogout: _logout,
      ),
      body: ListView(
        children: [
          const MerchHero(
            eyebrow: 'Halaman Maker · Admin MerchBox',
            title: 'Kelola\nmerchandise',
            subtitle: 'Tambah, edit, hapus, dan publikasikan barang untuk pengguna',
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ErrorBanner(message: _error!),
                    if (_notice != null) NoticeBanner(message: _notice!),
                    if (_showRequests) _requestInbox(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Merchandise',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Perubahan yang disimpan akan tampil di katalog pengguna',
                                style: TextStyle(color: MerchColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_products.length} produk',
                          style: const TextStyle(color: MerchColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_products.isEmpty)
                      const EmptyState(
                        title: 'Belum ada data merchandise.',
                        subtitle: 'Tambahkan barang pertama untuk mulai.',
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
                            itemCount: _products.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: count == 1 ? .78 : .68,
                            ),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return ProductCard(
                                product: product,
                                admin: true,
                                onEdit: () => _editProduct(product),
                                onDelete: () => _deleteProduct(product),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Footer(admin: true),
        ],
      ),
    );
  }

  Widget _requestInbox() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 26),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: MerchColors.line),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi permintaan barang',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (_requests.isEmpty)
              const Text(
                'Belum ada permintaan barang.',
                style: TextStyle(color: MerchColors.muted),
              )
            else
              ..._requests.map(
                (request) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: request.isRead
                        ? MerchColors.paper
                        : const Color(0xFFFFF6F2),
                    border: Border(
                      left: BorderSide(
                        color: request.isRead
                            ? MerchColors.line
                            : MerchColors.accent,
                        width: 4,
                      ),
                      top: const BorderSide(color: MerchColors.line),
                      right: const BorderSide(color: MerchColors.line),
                      bottom: const BorderSide(color: MerchColors.line),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          Text(
                            request.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Wrap(
                            spacing: 5,
                            children: [
                              if (!request.isRead)
                                TextButton(
                                  onPressed: () => _markRead(request),
                                  child: const Text('Tandai dibaca'),
                                ),
                              TextButton.icon(
                                onPressed: () => _deleteRequest(request),
                                icon: const Icon(Icons.delete_outline, size: 17),
                                label: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _openEmail(request.email),
                        child: Text(
                          '${request.name} · ${request.email}',
                          style: const TextStyle(
                            color: MerchColors.muted,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(request.message, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(request.createdAt),
                        style: const TextStyle(
                          color: MerchColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
