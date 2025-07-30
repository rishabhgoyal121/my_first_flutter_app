// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      firstName: fields[0] as String,
      lastName: fields[1] as String,
      email: fields[2] as String,
      phone: fields[3] as String,
      city: fields[4] as String,
      street: fields[5] as String,
      houseNumber: fields[6] as String,
      zipcode: fields[7] as String,
      password: fields[8] as String,
      lat: fields[9] as double?,
      long: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.street)
      ..writeByte(6)
      ..write(obj.houseNumber)
      ..writeByte(7)
      ..write(obj.zipcode)
      ..writeByte(8)
      ..write(obj.password)
      ..writeByte(9)
      ..write(obj.lat)
      ..writeByte(10)
      ..write(obj.long);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
