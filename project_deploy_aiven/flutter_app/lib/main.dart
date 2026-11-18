import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/maker_screen.dart';
import 'screens/shop_screen.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const MerchBoxApp());
}

class MerchBoxApp extends StatelessWidget {
  const MerchBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MerchBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MerchColors.accent,
          surface: MerchColors.paper,
        ),
        scaffoldBackgroundColor: MerchColors.paper,
        appBarTheme: const AppBarTheme(
          backgroundColor: MerchColors.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: MerchColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: MerchColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: MerchColors.accent, width: 1.5),
          ),
        ),
      ),
      initialRoute: _initialRoute(),
      routes: {
        '/': (_) => const HomeGate(),
        '/shop': (_) => const ShopScreen(),
        '/auth': (_) => const AuthScreen(),
        '/maker': (_) => const MakerScreen(),
        '/admin': (_) => const MakerScreen(),
      },
    );
  }

  String _initialRoute() {
    final fragment = Uri.base.fragment;
    if (fragment.startsWith('/')) return fragment;
    final path = Uri.base.path;
    return path == '/' ? '/' : path;
  }
}

class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() => _error = null);
    try {
      final user = await apiService.currentUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        user?.role == 'admin' ? '/maker' : '/shop',
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Tidak dapat terhubung ke server.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Brand(),
                const SizedBox(height: 22),
                if (_error == null) ...[
                  const CircularProgressIndicator(color: MerchColors.accent),
                  const SizedBox(height: 14),
                  const Text('Memeriksa sesi...'),
                ] else ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Coba lagi', onPressed: _checkSession),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/shop'),
                    child: const Text('Tetap buka toko'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
