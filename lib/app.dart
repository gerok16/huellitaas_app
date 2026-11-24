import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/carrito_provider.dart';

class HuellitasApp extends StatelessWidget {
  const HuellitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),

        // El carrito escucha a AuthProvider: cuando cambia el usuario
        // (cierre de sesión o ingreso de otra cuenta) se vacía solo.
        ChangeNotifierProxyProvider<AuthProvider, CarritoProvider>(
          create: (_) => CarritoProvider(),
          update: (_, auth, carrito) {
            final actual = carrito ?? CarritoProvider();
            actual.sincronizarUsuario(auth.usuario?.id);
            return actual;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Huellitas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
