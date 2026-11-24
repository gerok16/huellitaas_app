import 'package:go_router/go_router.dart';

import '../models/usuario.dart';
import '../models/venta.dart';
import '../models/compra.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';

import '../providers/auth_provider.dart';

import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registro_screen.dart';
import '../screens/auth/recuperar_password_screen.dart';
import '../screens/auth/verificar_codigo_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/client/cliente_dashboard_screen.dart';
import '../screens/products/gestion_productos_screen.dart';
import '../screens/sales/punto_venta_screen.dart';
import '../screens/sales/consulta_venta_screen.dart';
import '../screens/sales/detalle_venta_screen.dart';
import '../screens/branches/sucursales_screen.dart';

import '../screens/supply/nueva_compra_screen.dart';
import '../screens/supply/detalle_compra_screen.dart';

// Pantalla de inicio según el rol del usuario.
String _inicioPara(Usuario usuario) =>
    usuario.esCliente ? '/cliente' : '/inicio';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authProvider,

  redirect: (context, state) {
    final usuario = authProvider.usuario;
    final ruta = state.matchedLocation;

    // Rutas públicas.
    const rutasPublicas = {
      '/',
      '/login',
      '/registro',
      '/catalogo',
      '/recuperar',
      '/verificar',
    };

    final esRutaPublica = rutasPublicas.contains(ruta);

    // 1. Sin sesión: permitir únicamente rutas públicas.
    if (usuario == null) {
      return esRutaPublica ? null : '/login';
    }

    // 2. Con sesión: dirigir al panel correspondiente.
    final inicio = _inicioPara(usuario);

    if (ruta == '/' || ruta == '/login' || ruta == '/registro') {
      return inicio;
    }

    // 3. Protección por roles.
    if (ruta == '/inicio' && usuario.esCliente) {
      return '/cliente';
    }

    if (ruta == '/cliente' && !usuario.esCliente) {
      return '/inicio';
    }

    if (ruta.startsWith('/productos') && !usuario.esDueno) {
      return inicio;
    }

    // Abastecimiento: solo el dueño.
    if (ruta.startsWith('/compras') && !usuario.esDueno) {
      return inicio;
    }

    // Ventas: solo dueño y empleados.
    if ((ruta.startsWith('/punto-venta') ||
        ruta.startsWith('/consulta-venta') ||
        ruta.startsWith('/ventas')) &&
        !usuario.esPersonal) {
      return inicio;
    }

    return null;
  },

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
      path: '/registro',
      builder: (context, state) => const RegistroScreen(),
    ),
    GoRoute(
      path: '/recuperar',
      builder: (context, state) {
        final extra = state.extra;

        return RecuperarPasswordScreen(
          correoInicial: extra is String ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/verificar',
      builder: (context, state) {
        final extra = state.extra;

        return VerificarCodigoScreen(
          correo: extra is String ? extra : '',
        );
      },
    ),
    GoRoute(
      path: '/catalogo',
      builder: (context, state) => const CatalogScreen(),
    ),
    GoRoute(
      path: '/inicio',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/cliente',
      builder: (context, state) => const ClienteDashboardScreen(),
    ),
    GoRoute(
      path: '/punto-venta',
      builder: (context, state) => const PuntoVentaScreen(),
    ),
    GoRoute(
      path: '/productos',
      builder: (context, state) => const GestionProductosScreen(),
    ),
    GoRoute(
      path: '/consulta-venta',
      builder: (context, state) => const ConsultaVentaScreen(),
    ),

    // Módulo de sucursales.
    GoRoute(
      path: '/sucursales',
      builder: (context, state) => const SucursalesScreen(),
    ),

    // Abastecimiento (solo dueño).
    // Esta ruta debe estar antes de /compras/:codigo.
    GoRoute(
      path: '/compras/nueva',
      builder: (context, state) {
        final extra = state.extra;
        final datos = extra is Map ? extra : <dynamic, dynamic>{};

        return NuevaCompraScreen(
          proveedorInicial: datos['proveedor'] is Proveedor
              ? datos['proveedor'] as Proveedor
              : null,
          productosIniciales: datos['productos'] is List
              ? (datos['productos'] as List)
              .whereType<Producto>()
              .toList()
              : const [],
        );
      },
    ),
    GoRoute(
      path: '/compras/:codigo',
      builder: (context, state) {
        final extra = state.extra;

        return DetalleCompraScreen(
          codigo: state.pathParameters['codigo'] ?? '',
          compra: extra is Compra ? extra : null,
        );
      },
    ),

    // Detalle de venta.
    GoRoute(
      path: '/ventas/:codigo',
      builder: (context, state) {
        final extra = state.extra;

        return DetalleVentaScreen(
          codigo: state.pathParameters['codigo'] ?? '',
          venta: extra is Venta ? extra : null,
        );
      },
    ),
  ],
);