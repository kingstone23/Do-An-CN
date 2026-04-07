import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/profile_screen.dart';
import 'services/backend_api_service.dart';
import 'services/expiry_reminder_service.dart';
import 'widgets/add_food_modal.dart';
import 'widgets/time_simulator_console.dart';

/// Built once — avoids rebuilding [ColorScheme] / [ThemeData] on every [AppProvider] tick.
final ThemeData kAppLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: Brightness.light,
    secondary: const Color(0xFFFF9800),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAF9),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF8FAF9),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE0E7E2)),
    ),
    color: Colors.white,
  ),
);

final ThemeData kAppDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF176A21),
    brightness: Brightness.dark,
    secondary: const Color(0xFFFFB74D),
  ),
  scaffoldBackgroundColor: const Color(0xFF050C07),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF050C07),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF1A3320)),
    ),
    color: const Color(0xFF0D1F11),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await ExpiryReminderService.instance.init();

  final api = dotenv.env['API_BASE_URL'] ?? '';
  BackendApiService.instance.configure(baseUrl: api);

  final pk = dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '';

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: pk.trim().isEmpty
          ? const _MissingClerkKeyApp()
          : ClerkAuth(
              config: ClerkAuthConfig(publishableKey: pk.trim()),
              child: const HarvestAndHearthApp(),
            ),
    ),
  );
}

class _MissingClerkKeyApp extends StatelessWidget {
  const _MissingClerkKeyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harvest & Hearth',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Thiếu CLERK_PUBLISHABLE_KEY trong .env.\n'
              'See .env.example.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Only theme + routing inputs — avoids rebuilding [MaterialApp] when inventory/recipes change.
@immutable
class _AppUiState {
  const _AppUiState({
    required this.isDark,
    required this.isInitialized,
  });

  final bool isDark;
  final bool isInitialized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AppUiState &&
          runtimeType == other.runtimeType &&
          isDark == other.isDark &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode => Object.hash(isDark, isInitialized);
}

class HarvestAndHearthApp extends StatelessWidget {
  const HarvestAndHearthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, _AppUiState>(
      selector: (_, p) => _AppUiState(
        isDark: p.isDark,
        isInitialized: p.isInitialized,
      ),
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Harvest & Hearth',
          debugShowCheckedModeBanner: false,
          themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: kAppLightTheme,
          darkTheme: kAppDarkTheme,
          home: !state.isInitialized
              ? const _SplashScreen()
              : ClerkErrorListener(
                  child: ClerkAuthBuilder(
                    signedOutBuilder: (context, _) => const _SignedOutShell(),
                    signedInBuilder: (context, _) => const _ClerkBootstrap(),
                  ),
                ),
        );
      },
    );
  }
}

/// Clears [AppProvider] once when showing the signed-out flow.
class _SignedOutShell extends StatefulWidget {
  const _SignedOutShell();

  @override
  State<_SignedOutShell> createState() => _SignedOutShellState();
}

class _SignedOutShellState extends State<_SignedOutShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().clearSession();
    });
  }

  @override
  Widget build(BuildContext context) => const AuthScreen();
}

/// Loads profile/inventory from the API after Clerk session is ready.
class _ClerkBootstrap extends StatefulWidget {
  const _ClerkBootstrap();

  @override
  State<_ClerkBootstrap> createState() => _ClerkBootstrapState();
}

class _ClerkBootstrapState extends State<_ClerkBootstrap> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _started = true);
      final auth = ClerkAuth.of(context, listen: false);
      final user = auth.client.user;
      if (user is clerk.User) {
        await context.read<AppProvider>().bindClerkSession(auth, user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({bool loading, bool hasUser})>(
      selector: (_, p) =>
          (loading: p.isLoadingUser, hasUser: p.user != null),
      builder: (context, s, _) {
        if (!_started || s.loading || !s.hasUser) {
          return const _SplashScreen();
        }
        return const MainShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Harvest & Hearth',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
    RecipesScreen(),
    ProfileScreen(),
  ];

  void _showAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddFoodModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppProvider, String>((p) => p.language);
    final t = context.read<AppProvider>().t;
    final showTimeSim = isTimeSimulatorFabVisible();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (showTimeSim)
            const Positioned(
              left: 16,
              bottom: 16,
              child: TimeSimulatorFab(),
            ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              heroTag: 'add_food_fab',
              onPressed: _showAddFoodModal,
              tooltip: t('add_food'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        key: ValueKey<String>(lang),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: t('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: t('nav_inventory'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: t('nav_recipes'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t('nav_profile'),
          ),
        ],
      ),
    );
  }
}
