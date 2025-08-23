import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/species_selection_screen.dart';
import 'screens/preparation_screen.dart';
import 'screens/ar_experience_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/butterfly_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => ButterflyProvider()..loadButterflies(),
        ),
      ],
      child: const ButterflyARApp(),
    ),
  );
}

class ButterflyARApp extends StatelessWidget {
  const ButterflyARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Configurar colores de sistema según el tema
        _configureSystemUI(themeProvider);

        return MaterialApp(
          title: 'ButterflyAR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/onboarding',
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/hub': (context) => const HubScreen(),
            '/species': (context) => const SpeciesSelectionScreen(),
            '/preparation': (context) => const PreparationScreen(),
            '/ar': (context) => _buildARRoute(context),
            '/settings': (context) => const SettingsScreen(),
            '/qr': (context) => const QRScanScreen(),
          },
        );
      },
    );
  }

  void _configureSystemUI(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildARRoute(BuildContext context) {
    final butterflyProvider = Provider.of<ButterflyProvider>(
      context,
      listen: false,
    );

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is Map<String, dynamic>) {
      final butterflyId = args['butterflyId'] as String?;
      if (butterflyId != null) {
        final butterfly = butterflyProvider.getButterflyById(butterflyId);
        if (butterfly != null) {
          return ARExperienceScreen(butterfly: butterfly);
        }
      }
    }

    // Si no hay mariposas cargadas, mostrar loading
    if (butterflyProvider.butterflies.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 20),
              Text(
                'Cargando experiencia AR...',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // Usar la primera mariposa como fallback
    return ARExperienceScreen(butterfly: butterflyProvider.butterflies.first);
  }
}