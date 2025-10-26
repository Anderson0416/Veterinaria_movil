import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/moldes/animal_type_model.dart';

class AnimalTypeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Obtiene todos los tipos de animales en tiempo real
  Stream<List<AnimalTypeModel>> getAnimalTypesStream() {
    return _db.collection('animal_types').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AnimalTypeModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

   /// 🔹 Obtiene todos los tipos de animales una sola vez (para formularios, etc.)
  Future<List<AnimalTypeModel>> getAnimalTypes() async {
    final snapshot = await _db.collection('animal_types').get();
    return snapshot.docs
        .map((doc) => AnimalTypeModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Agrega los tipos de animales por defecto (solo una vez)
  Future<void> populateAnimalTypes() async {
    final tipos = [
      'Perro',
      'Gato',
      'Ave',
      'Vaca',
      'Caballo',
      'Conejo',
      'Cerdo',
      'Reptil',
      'Pez',
      'Otro'
    ];

    for (var tipo in tipos) {
      final existe = await _db
          .collection('animal_types')
          .where('nombre', isEqualTo: tipo)
          .get();

      if (existe.docs.isEmpty) {
        await _db.collection('animal_types').add({'nombre': tipo});
      }
    }

    Get.snackbar('Éxito', 'Tipos de animales agregados correctamente');
  }
}
