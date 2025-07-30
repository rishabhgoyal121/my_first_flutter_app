import 'package:hive/hive.dart';

class DBHelper {
  static Future<void> insertUser(String email, String password) async {
    final box = Hive.box('users');
    await box.put(email, password);
  }

  static Future<String?> getUserPassword(String email) async {
    final box = Hive.box('users');
    return box.get(email);
  }
}
