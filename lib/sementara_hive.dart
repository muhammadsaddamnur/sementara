import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart' as crypto;

SementaraModel sementaraModelFromJson(dynamic str) =>
    SementaraModel.fromJson(json.decode(str));

String sementaraModelToJson(SementaraModel data) => json.encode(data.toJson());

class SementaraModel {
  final DateTime? startDate;
  final DateTime? endDate;
  final dynamic response;

  SementaraModel({this.startDate, this.endDate, this.response});

  factory SementaraModel.fromJson(Map<String, dynamic> json) => SementaraModel(
      startDate: json['startDate'] ?? null,
      endDate: json['endDate'] ?? null,
      response: json['response'] ?? null);

  Map<String, dynamic> toJson() => {
        'startDate': startDate ?? null,
        'endDate': endDate ?? null,
        'response': response ?? null
      };
}

abstract class SementaraFunction {
  init();
  local();
  apiLocal();
  create();
  read();
  update();
  delete();
}

String generateMd5(String input) {
  return crypto.md5.convert(utf8.encode(input)).toString();
}

class SementaraHive extends SementaraFunction {
  final String _box = 'sementara';

  //This function only read local data, attention! for sensitive data such as price,
  //discount, or any data is always update dont should using this function
  //
  @override
  Future<SementaraModel?> local(
      {String? url,
      Map<String, dynamic>? body,
      Map<String, dynamic>? function}) async {
    SementaraModel? value = (await read(url: url, body: body));

    if (value == null) {
      await create(url: url, body: body, response: function);
      SementaraModel? response = (await read(url: url, body: body));
      return response;
    } else {
      if (value.endDate!.isAfter(DateTime.now())) {
        await create(url: url, body: body, response: function);
        SementaraModel? response = (await read(url: url, body: body));
        return response;
      } else {
        return value;
      }
    }
  }

  //This function get data from API, and then data the data is saved to local storage.
  //So, data in the local storage have renew when your call the API
  //
  @override
  Future<SementaraModel?> apiLocal(
      {String? url,
      Map<String, dynamic>? body,
      Map<String, dynamic>? function,
      //change [update = true] if you want to reload cache every hit API
      bool isUpdate = true}) async {
    if (isUpdate) {
      await create(url: url, body: body, response: function);
      SementaraModel? response = (await read(url: url, body: body));
      return response;
    } else {
      SementaraModel? response = (await read(url: url, body: body));
      // if()
      return response;
    }
  }

  //onSuccess() is a method for save response data to cache, and return the data from there
  //if you want only return the data from cahce you can change cachePriority = [true]
  //
  @override
  Future create(
      {String? url,
      Map<String, dynamic>? body,
      DateTime? startDate,
      DateTime? endDate,
      dynamic response,
      bool cachePriority = false}) async {
    var box = await Hive.openBox(_box);
    String md5 = generateMd5(url! + body.toString());

    SementaraModel value = SementaraModel(
        startDate: DateTime.now(),
        endDate: endDate ?? DateTime.now().add(Duration(days: 7)),
        response: response);
    box.put(md5, value);
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
  Future<SementaraModel?> read({
    String? url,
    Map<String, dynamic>? body,
  }) async {
    var box = await Hive.openBox(_box);
    String md5 = generateMd5(url! + body.toString());

    SementaraModel res =
        await compute(sementaraModelFromJson, await box.get(md5));

    return res;
  }

  @override
  void update() {}
}
