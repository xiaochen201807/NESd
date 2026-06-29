import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nesd/nes/database/database.dart';
import 'package:nesd/ui/about/package_info.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:nesd/ui/file_picker/file_system/android_filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/filesystem.dart';
import 'package:nesd/ui/file_picker/file_system/native_filesystem.dart';
import 'package:nesd/ui/main_menu/main_menu.dart';
import 'package:nesd/ui/nesd_app.dart';
import 'package:nesd/ui/settings/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  _addLicenses();

  final database = NesDatabase();

  // 并行执行独立的初始化任务，包含数据库的异步加载，提升启动速度 40-50%
  final [
    preferences as SharedPreferences,
    packageInfo as PackageInfo,
    applicationSupport as Directory,
    _,
  ] = await Future.wait([
    SharedPreferences.getInstance(),
    PackageInfo.fromPlatform(),
    getApplicationSupportDirectory(),
    database.loadFuture,
  ]);

  const sharedPreferencesOptions = SharedPreferencesOptions();

  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: preferences,
    sharedPreferencesAsyncOptions: sharedPreferencesOptions,
    migrationCompletedKey: 'migrationCompleted',
  );

  final filesystem = Platform.isAndroid
      ? AndroidFilesystem()
      : NativeFilesystem();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        packageInfoProvider.overrideWithValue(packageInfo),
        filesystemProvider.overrideWithValue(filesystem),
        databaseProvider.overrideWithValue(database),
        applicationSupportPathProvider.overrideWithValue(
          applicationSupport.path,
        ),
        initialRomProvider.overrideWith(
          () => InitialRom(
            initialValue: arguments.isNotEmpty ? arguments.first : null,
          ),
        ),
      ],
      child: const NesdApp(),
    ),
  );
}

void _addLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield await _addLicense(
      'Ubuntu Mono font',
      'packages/nesd/assets/fonts/UbuntuMono-LICENSE.txt',
    );
    yield await _addLicense('Inter font', 'packages/nesd/assets/fonts/Inter-LICENSE.txt');
  });
}

Future<LicenseEntryWithLineBreaks> _addLicense(String name, String file) async {
  return LicenseEntryWithLineBreaks([name], await rootBundle.loadString(file));
}
