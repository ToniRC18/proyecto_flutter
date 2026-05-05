// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedAccountAdapter extends TypeAdapter<CachedAccount> {
  @override
  final int typeId = 12;

  @override
  CachedAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAccount()
      ..id = fields[0] as String
      ..tenantId = fields[1] as String
      ..name = fields[2] as String
      ..type = fields[3] as String
      ..balance = fields[4] as double
      ..cachedAt = fields[5] as DateTime
      ..creditLimit = fields[6] as double?
      ..billingCloseDay = fields[7] as int?
      ..paymentDueDay = fields[8] as int?;
  }

  @override
  void write(BinaryWriter writer, CachedAccount obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tenantId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.balance)
      ..writeByte(5)
      ..write(obj.cachedAt)
      ..writeByte(6)
      ..write(obj.creditLimit)
      ..writeByte(7)
      ..write(obj.billingCloseDay)
      ..writeByte(8)
      ..write(obj.paymentDueDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
