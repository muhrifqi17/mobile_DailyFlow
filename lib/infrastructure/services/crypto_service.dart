import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _algorithm = AesGcm.with256bits();

  Future<String> getOrGenerateKey() async {
    String? base64Key = await _secureStorage.read(key: 'master_key');
    if (base64Key == null) {
      final secretKey = await _algorithm.newSecretKey();
      final keyBytes = await secretKey.extractBytes();
      base64Key = base64Encode(keyBytes);
      await _secureStorage.write(key: 'master_key', value: base64Key);
    }
    return base64Key;
  }

  Future<Map<String, String>> encrypt(String plainText) async {
    final base64Key = await getOrGenerateKey();
    final secretKey = SecretKey(base64Decode(base64Key));
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
    );
    return {
      'cipherText': base64Encode(secretBox.cipherText),
      'iv': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<String> decrypt(String cipherTextBase64, String ivBase64, String macBase64) async {
    final base64Key = await getOrGenerateKey();
    final secretKey = SecretKey(base64Decode(base64Key));
    final secretBox = SecretBox(
      base64Decode(cipherTextBase64),
      nonce: base64Decode(ivBase64),
      mac: Mac(base64Decode(macBase64)),
    );
    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return utf8.decode(decrypted);
  }
}
