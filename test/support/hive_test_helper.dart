import 'dart:io';

import 'package:hive/hive.dart';

class HiveTestHelper {
  static Future<void> initialize() async {
    if (Hive.isBoxOpen('master_products')) return;
    final directory = await Directory.systemTemp.createTemp('salesgo_test_');
    Hive.init(directory.path);
  }

  static Future<void> clearBoxes(Iterable<String> names) async {
    for (final name in names) {
      final box = Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
      await box.clear();
    }
  }
}
