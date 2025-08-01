import 'package:hive/hive.dart';
import 'user.dart';

class DBHelper {
  static Future<bool> getUser(String email, String password) async {
    final box = Hive.box<User>('users');
    final user = box.get(email);
    if (user != null && user.password == password) {
      return true;
    }
    return false;
  }
}
