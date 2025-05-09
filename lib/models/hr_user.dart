import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class HRUser extends ParseUser {
  HRUser({String? username, String? password, String? emailAddress})
      : super(username, password, emailAddress);

  HRUser.clone() : this();

  @override
  clone(Map<String, dynamic> map) => HRUser.clone()..fromJson(map);

  String getHashedPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
