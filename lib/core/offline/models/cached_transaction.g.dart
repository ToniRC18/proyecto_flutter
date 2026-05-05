// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedTransactionAdapter extends TypeAdapter<CachedTransaction> {
  @override
  final int typeId = 11;

  @override
  CachedTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedTransaction()
      ..id = fields[0] as String
      ..accountId = fields[1] as String
      ..tenantId = fields[2] as String
      ..amount = fields[3] as double
      ..type = fields[4] as String
      ..category = fields[5] as String
      ..date = fields[6] as DateTime
      ..notes = fields[7] as String?
      ..cachedAt = fields[8] as DateTime
      ..isPendingSync = fields[9] as bool
      ..transferId = fields[10] as String?;
  }

  @override
  void write(BinaryWriter writer, CachedTransaction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.tenantId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.cachedAt)
      ..writeByte(9)
      ..write(obj.isPendingSync)
      ..writeByte(10)
      ..write(obj.transferId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
