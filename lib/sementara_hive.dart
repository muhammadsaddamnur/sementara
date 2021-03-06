import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class SementaraModel {
  final String md5;
  final DateTime timeStamp;
  final dynamic response;

  SementaraModel({this.md5, this.timeStamp, this.response});
}

abstract class SementaraFunction {
  void init();
  void create();
  void read();
  void update();
  void delete();
}

class SementaraHive extends SementaraFunction {
  final String _box = 'sementara';

  @override
  void create() async {
    var box = await Hive.openBox(_box);
    box.put('', '');
  }

  @override
  void delete() {}

  @override
  void init() {
    if (!kIsWeb) {
      var path = Directory.current.path;
      Hive.init(path);
    }
  }

  @override
  void read() {}

  @override
  void update() {}
}
