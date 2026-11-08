import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/welcome/welcome_screen.dart';

/// Rutas de la app. Más adelante aquí se agregan las rutas protegidas por rol.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/catalogo',
      builder: (context, state) => const CatalogScreen(),
    ),
  ],
);
