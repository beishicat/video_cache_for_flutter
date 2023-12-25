import 'dart:convert';
import 'package:crypto/crypto.dart';

extension StringMD5 on String {
  String toMD5() {
    final content = const Utf8Encoder().convert(this);
    return md5.convert(content).toString();
  }
}
