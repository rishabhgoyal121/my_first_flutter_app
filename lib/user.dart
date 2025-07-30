import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String firstName;
  @HiveField(1)
  String lastName;
  @HiveField(2)
  String email;
  @HiveField(3)
  String phone;
  @HiveField(4)
  String city;
  @HiveField(5)
  String street;
  @HiveField(6)
  String houseNumber;
  @HiveField(7)
  String zipcode;
  @HiveField(8)
  String password;
  @HiveField(9)
  double? lat;
  @HiveField(10)
  double? long;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.city,
    required this.street,
    required this.houseNumber,
    required this.zipcode,
    required this.password,
    this.lat,
    this.long,
  });
}
