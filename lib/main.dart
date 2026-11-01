import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/utils/logger.dart';
import 'data/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the status and navigation bars (Android 15 edge-to-edge).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  var config = AppConfig.fromEnvironment();
  if (config.isComplete) {
    try {
      await initSupabase(config);
    } on Object catch (e, s) {
      // Never crash on start: show the setup screen with a reason instead.
      Log.error('Supabase failed to start', e, s);
      config = const AppConfig(supabaseUrl: '', supabaseAnonKey: '');
    }
  }

  runApp(ProviderScope(child: PlannerApp(config: config)));
}
