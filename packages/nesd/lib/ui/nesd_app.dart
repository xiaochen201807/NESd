import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/router/router.dart';
import 'package:nesd/ui/router/router_observer.dart';
import 'package:nesd/ui/settings/settings.dart';
import 'package:nesd/ui/theme/dark.dart';
import 'package:nesd/ui/theme/light.dart';

class NesdApp extends HookConsumerWidget {
  const NesdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observer = ref.watch(routerObserverProvider.notifier);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );

    return MaterialApp.router(
      title: '像素电玩城',
      theme: nesdThemeLight,
      darkTheme: nesdThemeDark,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      routerConfig: router.config(navigatorObservers: () => [observer]),
    );
  }
}
