import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/router.dart';
import 'core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not found or malformed — fall through; API_BASE_URL must be
    // set via environment or the API class will throw at call-time.
  }

  runApp(const ProviderScope(child: ScoutApp()));
}

class ScoutApp extends ConsumerWidget {
  const ScoutApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Scout',
    debugShowCheckedModeBanner: false,
    theme: ScoutTheme.light,
    darkTheme: ScoutTheme.dark,
    themeMode: ThemeMode.system,
    routerConfig: ref.watch(routerProvider),
  );
}
