// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MomentAdapter extends TypeAdapter<Moment> {
  @override
  final int typeId = 0;

  @override
  Moment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Moment(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: (fields[3] as DateTime?) ?? DateTime.now(),
      materials: (fields[4] as List).cast<MaterialItem>(),
      imagePath: fields[7] as String?,
    )
      ..description = fields[2] as String?
      ..tags = (fields[5] as List?)?.cast<String>()
      ..isSynced = fields[6] as bool?
      ..updatedAt = (fields[8] as DateTime?) ?? DateTime.now()
      ..isDeleted = fields[9] as bool?;
  }

  @override
  void write(BinaryWriter writer, Moment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.materials)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.isSynced)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MomentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialItemAdapter extends TypeAdapter<MaterialItem> {
  @override
  final int typeId = 1;

  @override
  MaterialItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialItem(
      title: fields[0] as String,
      type: fields[1] as MomentMaterialType,
      content: fields[2] as String,
      transcript: fields[3] as String?,
      id: fields[4] as String?,
      updatedAt: (fields[5] as DateTime?) ?? DateTime.now(),
      isDeleted: fields[6] as bool?,
      isSynced: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.transcript)
      ..writeByte(4)
      ..write(obj.id)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isDeleted)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MomentMaterialTypeAdapter extends TypeAdapter<MomentMaterialType> {
  @override
  final int typeId = 2;

  @override
  MomentMaterialType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MomentMaterialType.text;
      case 1:
        return MomentMaterialType.image;
      case 2:
        return MomentMaterialType.video;
      case 3:
        return MomentMaterialType.voice;
      default:
        return MomentMaterialType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MomentMaterialType obj) {
    switch (obj) {
      case MomentMaterialType.text:
        writer.writeByte(0);
        break;
      case MomentMaterialType.image:
        writer.writeByte(1);
        break;
      case MomentMaterialType.video:
        writer.writeByte(2);
        break;
      case MomentMaterialType.voice:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MomentMaterialTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
