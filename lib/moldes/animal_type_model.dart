import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalTypeModel {
  String? id;
  String nombre;

  AnimalTypeModel({
    this.id,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
    };
  }

  factory AnimalTypeModel.fromMap(Map<String, dynamic> map, String id) {
    return AnimalTypeModel(
      id: id,
      nombre: map['nombre'] ?? '',
    );
  }

  factory AnimalTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnimalTypeModel.fromMap(data, doc.id);
  }
}
