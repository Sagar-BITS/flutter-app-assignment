import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class User extends ParseUser {
  User({String? username, String? password, String? emailAddress})
    : super(username, password, emailAddress);

  User.clone() : this();

  @override
  clone(Map<String, dynamic> map) => User.clone()..fromJson(map);

  String getHashedPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
