import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nesd/extension/string_extension.dart';
import 'package:nesd/nes/region.dart';
import 'package:nesd/ui/emulator/rom_manager.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml.dart';

part 'database.g.dart';

@Riverpod(keepAlive: true)
NesDatabase database(Ref ref) => NesDatabase();

class NesDatabase {
  NesDatabase() {
    _loadFuture = _load();
  }

  late final Future<void> _loadFuture;
  Future<void> get loadFuture => _loadFuture;

  final Map<String, NesDatabaseEntry> _database = {};

  NesDatabaseEntry? find(RomInfo info) {
    NesDatabaseEntry? result;

    if (info.romHash case final romHash?) {
      result ??= _database[romHash];
    }

    if (info.prgHash case final prgHash?) {
      result ??= _database.values.firstWhereOrNull(
        (entry) => entry.prgHash == prgHash,
      );
    }

    return result;
  }

  Future<void> _load() async {
    // 从 gzip 压缩的数据库文件加载（比原始 XML 小 ~78%）
    final bytes = await rootBundle.load('packages/nesd/assets/nes20db.xml.gz');
    // 在独立 isolate 中解压 + 解析，避免阻塞主线程
    final entries = await compute(
      _parseDatabase,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    _database.addAll(entries);
  }
}

// 顶层函数，在 compute isolate 中执行解压和 XML 解析
Map<String, NesDatabaseEntry> _parseDatabase(Uint8List gzBytes) {
  final xmlBytes = const GZipDecoder().decodeBytes(gzBytes);
  final xmlString = utf8.decode(xmlBytes);
  final data = XmlDocument.parse(xmlString);
  final result = <String, NesDatabaseEntry>{};

  for (final game in data.findAllElements('game')) {
    final romHash = _getHash(game, 'rom');

    if (romHash == null) {
      continue;
    }

    final name = p.basenameWithoutExtension(
      game.children.whereType<XmlComment>().single.value.trim().replaceAll(
        '\\',
        '/',
      ),
    );

    final chrHash = _getHash(game, 'chrrom');
    final prgHash = _getHash(game, 'prgrom')!;
    final mapper = _getAttribute(game, 'pcb', 'mapper').toIntOrZero();
    final region = _getAttribute(game, 'console', 'region').toIntOrZero();
    final chrRamSize = _getAttribute(game, 'chrram', 'size').toIntOrZero();
    final prgRamSize = _getAttribute(game, 'prgram', 'size').toIntOrZero();
    final prgSaveRamSize = _getAttribute(
      game,
      'prgnvram',
      'size',
    ).toIntOrZero();
    final hasBattery = _getAttribute(game, 'pcb', 'battery') == '1';

    result[romHash] = NesDatabaseEntry(
      name: name,
      romHash: romHash,
      chrHash: chrHash,
      prgHash: prgHash,
      chrRamSize: chrRamSize,
      prgRamSize: prgRamSize,
      prgSaveRamSize: prgSaveRamSize,
      hasBattery: hasBattery,
      mapper: mapper,
      region: switch (region) {
        0 => Region.ntsc,
        1 => Region.pal,
        _ => null,
      },
      expansion: int.parse(_getAttribute(game, 'expansion', 'type')!),
    );
  }

  return result;
}

String? _getAttribute(XmlElement child, String tag, String attribute) {
  return child.findElements(tag).singleOrNull?.getAttribute(attribute);
}

String? _getHash(XmlElement child, String tag) {
  return child
      .findElements(tag)
      .singleOrNull
      ?.getAttribute('sha1')
      ?.toLowerCase();
}

class NesDatabaseEntry {
  const NesDatabaseEntry({
    required this.name,
    required this.romHash,
    required this.chrHash,
    required this.prgHash,
    required this.chrRamSize,
    required this.prgRamSize,
    required this.prgSaveRamSize,
    required this.hasBattery,
    required this.mapper,
    required this.expansion,
    this.region,
  });

  final String name;
  final String romHash;
  final String? chrHash;
  final String prgHash;
  final int chrRamSize;
  final int prgRamSize;
  final int prgSaveRamSize;
  final bool hasBattery;
  final int mapper;
  final int expansion;
  final Region? region;

  bool get hasZapper => expansion == 0x08 || expansion == 0x09;
}
