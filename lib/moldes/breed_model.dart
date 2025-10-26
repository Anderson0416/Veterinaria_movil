import 'package:cloud_firestore/cloud_firestore.dart';

class BreedModel {
  String? id;
  String nombre;
  String animalTypeId; // Relación con animal_types

  BreedModel({
    this.id,
    required this.nombre,
    required this.animalTypeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'animalTypeId': animalTypeId,
    };
  }

  factory BreedModel.fromMap(Map<String, dynamic> map, String id) {
    return BreedModel(
      id: id,
      nombre: map['nombre'] ?? '',
      animalTypeId: map['animalTypeId'] ?? '',
    );
  }

  factory BreedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BreedModel.fromMap(data, doc.id);
  }
}
