import 'package:hive/hive.dart';
import 'package:flutter/material.dart' show IconData, Icons;

part 'moment.g.dart';

@HiveType(typeId: 0)
class Moment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;
  
  @HiveField(2)
  String? description;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  List<MaterialItem> materials;
  
  @HiveField(5)
  List<String>? tags;
  
  @HiveField(6)
  bool isSynced = false;

  @HiveField(7)
  String? imagePath;
  
  // Constructors
  Moment({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.materials,
    this.imagePath,
  });
  
  Moment.create({
    String? title,
    List<MaterialItem>? materials,
    String? imagePath,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       title = title ?? 'Untitled Moment',
       createdAt = DateTime.now(),
       materials = materials ?? [],
       imagePath = imagePath;

  // Helper getters for backward compatibility
  String? get audioPath => materials.isNotEmpty && materials.first.type == MomentMaterialType.voice 
      ? materials.first.content 
      : null;
      
  String? get transcript => materials.isNotEmpty && materials.first.type == MomentMaterialType.voice 
      ? materials.first.transcript 
      : null;
}

@HiveType(typeId: 1)
class MaterialItem {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final MomentMaterialType type;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String? transcript;

  MaterialItem({
    required this.title,
    required this.type,
    required this.content,
    this.transcript,
  });
}

@HiveType(typeId: 2)
enum MomentMaterialType {
  @HiveField(0)
  text(Icons.text_fields, 'Text'),
  @HiveField(1)
  image(Icons.image, 'Image'),
  @HiveField(2)
  video(Icons.videocam, 'Video'),
  @HiveField(3)
  voice(Icons.mic, 'Voice');

  final IconData icon;
  final String label;
  const MomentMaterialType(this.icon, this.label);
} 