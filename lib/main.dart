import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ozgqsbdmtcdtjbrxrybc.supabase.co',
    publishableKey: 'sb_publishable_FAAPQj2RQWzKHnwbnHhDTA_afoyjZXp',
  );

  // Recupera la sesión y el perfil si el cliente ya había iniciado sesión.
  await authProvider.inicializar();

  runApp(const HuellitasApp());
}
