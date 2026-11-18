import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _showPassword = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final user = await apiService.currentUser();
      if (user != null && mounted) {
        _goToDestination(user);
        return;
      }
    } on ApiException catch (error) {
      if (error.statusCode != 401 && mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToDestination(User user) {
    Navigator.of(context)
        .pushReplacementNamed(user.role == 'admin' ? '/maker' : '/shop');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      if (_register) {
        await apiService.register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await apiService.login(_email.text.trim(), _password.text);
      }
      final user = await apiService.currentUser();
      if (user == null) {
        throw const ApiException('Gagal memeriksa sesi setelah login.');
      }
      if (mounted) _goToDestination(user);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Autentikasi gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: MerchColors.accent),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Container(
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: MerchColors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Brand(),
                    const SizedBox(height: 8),
                    const Text(
                      'MERCHANDISE MAKER & SHOP',
                      style: TextStyle(
                        color: MerchColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _register ? 'Buat akun baru.' : 'Selamat datang kembali.',
                      style: const TextStyle(
                        color: MerchColors.ink,
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _register
                          ? 'Buat akun untuk berbelanja dan menghubungi pengelola.'
                          : 'Login untuk memesan produk dan mengirim permintaan barang.',
                      style: const TextStyle(
                        color: MerchColors.muted,
                        height: 1.5,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 18),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        validator: (value) => (value?.trim().length ?? 0) < 2
                            ? 'Nama minimal 2 karakter.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return email.contains('@')
                            ? null
                            : 'Masukkan alamat email yang valid.';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: _register ? 'Minimal 8 karakter' : null,
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Sembunyikan password'
                              : 'Lihat password',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Password minimal 8 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: _register ? 'Register' : 'Login',
                        icon: _register ? Icons.person_add_alt : Icons.login,
                        busy: _submitting,
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _error = null;
                                _showPassword = false;
                              }),
                        child: Text(
                          _register
                              ? 'Sudah punya akun? Login'
                              : 'Belum punya akun? Register',
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed('/shop'),
                        icon: const Icon(Icons.arrow_back, size: 17),
                        label: const Text('Kembali ke toko'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
