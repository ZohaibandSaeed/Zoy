import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/feed_provider.dart';
import 'providers/search_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/main_nav_screen.dart';
import 'services/storage_service.dart';
import 'utils/env_config.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  await EnvConfig.init();

  // Initialize local storage (shared_preferences) for subscriptions
  await StorageService.init();

  runApp(const ZoyApp());
}

class ZoyApp extends StatelessWidget {
  const ZoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: MaterialApp(
        title: 'zoy',
        debugShowCheckedModeBanner: false,
        theme: YouTubeTheme.darkTheme,
        home: const MainNavScreen(),
      ),
    );
  }
}
