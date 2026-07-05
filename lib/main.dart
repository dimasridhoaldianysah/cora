import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/models/joint_config.dart';
import 'data/models/robot_profile.dart';
import 'data/repositories/profile_repository.dart';
import 'providers/profile_provider.dart';

import 'presentation/splash/splash_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/profile/profile_list_screen.dart';
import 'presentation/profile/profile_form_screen.dart';
import 'presentation/firmware/firmware_screen.dart';
import 'presentation/control/control_screen.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/about/about_screen.dart';
import 'presentation/bluetooth/bt_scanner_sheet.dart';
import 'providers/bt_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set full screen (hide status bar and navigation bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Hive.initFlutter();

  // Register Hive adapters for local storage models
  // Ensure correct typeId order matching models
  // 1. JointConfigAdapter (karena nested di RobotProfile)
  Hive.registerAdapter(JointConfigAdapter());
  // 2. RobotProfileAdapter
  Hive.registerAdapter(RobotProfileAdapter());

  final profileRepo = ProfileRepository();
  await profileRepo.init();

  runApp(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(profileRepo)],
      child: const CoraApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileListScreen(),
        ),
        GoRoute(
          path: '/profile_form',
          builder: (context, state) {
            final profileId = state.uri.queryParameters['id'];
            return ProfileFormScreen(profileId: profileId);
          },
        ),
        GoRoute(
          path: '/firmware',
          builder: (context, state) => const FirmwareScreen(),
        ),
        GoRoute(
          path: '/control',
          builder: (context, state) => const ControlScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
      ],
    ),
  ],
);

class CoraApp extends StatelessWidget {
  const CoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CORA',
      theme: coraTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  String _getAppbarTitle(String location) {
    if (location.startsWith('/home')) return 'Home';
    if (location.startsWith('/profile_form')) {
      final uri = Uri.parse(location);
      return uri.queryParameters.containsKey('id')
          ? 'Edit Profil'
          : 'Tambah Profil Baru';
    }
    if (location.startsWith('/profile')) return 'Robot Profile';
    if (location.startsWith('/firmware')) return 'Firmware';
    if (location.startsWith('/control')) return 'Kontrol';
    if (location.startsWith('/settings')) return 'Pengaturan';
    if (location.startsWith('/about')) return 'Tentang';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final customColors = Theme.of(context).extension<CustomColors>();
    final title = 'CORA — ${_getAppbarTitle(location)}';

    final btState = ref.watch(btProvider);

    return Scaffold(
      appBar: AppBar(
        leading: location.startsWith('/profile_form')
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: btState.isConnected
                          ? (customColors?.success ?? Colors.green)
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    btState.isConnected
                        ? (btState.deviceName ?? 'Terhubung')
                        : 'Tidak Terhubung',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: btState.isConnected
                          ? (customColors?.success ?? Colors.green)
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            tooltip: 'Pindai Bluetooth',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const BtScannerSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          Navigator.pop(context); // Close drawer
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/profile');
              break;
            case 2:
              context.go('/firmware');
              break;
            case 3:
              context.go('/control');
              break;
            case 4:
              context.go('/settings');
              break;
            case 5:
              context.go('/about');
              break;
          }
        },
        selectedIndex: _getSelectedIndex(location),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CORA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text('v1.0.0', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final activeProfile = ref
                        .watch(profileProvider)
                        .activeProfile;
                    final profileName =
                        activeProfile?.name ?? 'Tidak Ada Profil';
                    final statusText = btState.isConnected
                        ? 'Terhubung'
                        : 'Tidak Terhubung';
                    final isConnected = btState.isConnected;

                    return Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: isConnected
                              ? (customColors?.success ?? Colors.green)
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$profileName ($statusText)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isConnected
                                      ? (customColors?.success ?? Colors.green)
                                      : Theme.of(context).colorScheme.error,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing),
            label: Text('Robot Profile'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: Text('Firmware'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.gamepad_outlined),
            selectedIcon: Icon(Icons.gamepad),
            label: Text('Kontrol'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Pengaturan'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: Text('Tentang'),
          ),
        ],
      ),
      body: child,
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/profile')) return 1;
    if (location.startsWith('/firmware')) return 2;
    if (location.startsWith('/control')) return 3;
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/about')) return 5;
    return 0;
  }
}
