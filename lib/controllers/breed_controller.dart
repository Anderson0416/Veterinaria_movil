import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/moldes/breed_model.dart';

class BreedController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Obtiene todas las razas
  Stream<List<BreedModel>> getBreedsStream() {
    return _db.collection('breeds').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BreedModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

   /// 🔹 Obtiene todas las razas asociadas a un tipo de animal específico
  Future<List<BreedModel>> getBreedsByAnimalType(String animalTypeId) async {
    try {
      final snapshot = await _db
          .collection('breeds')
          .where('animalTypeId', isEqualTo: animalTypeId)
          .get();

      return snapshot.docs
          .map((doc) => BreedModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron obtener las razas: $e');
      return [];
    }
  }

  /// 🔹 Carga las razas por defecto para todos los tipos
  Future<void> populateBreeds() async {
    final tiposSnapshot = await _db.collection('animal_types').get();

    if (tiposSnapshot.docs.isEmpty) {
      Get.snackbar('Error', 'Primero ejecuta populateAnimalTypes()');
      return;
    }

    for (var tipoDoc in tiposSnapshot.docs) {
      final tipo = tipoDoc['nombre'];
      final tipoId = tipoDoc.id;

      List<String> razas = [];

      switch (tipo) {
        case 'Perro':
          razas = [
            'Labrador Retriever',
            'Pastor Alemán',
            'Bulldog',
            'Beagle',
            'Poodle',
            'Chihuahua',
            'Rottweiler',
            'Golden Retriever',
            'Doberman',
            'Husky Siberiano',
            'Desconocido',
          ];
          break;

        case 'Gato':
          razas = [
            'Persa',
            'Siames',
            'Bengala',
            'Maine Coon',
            'Angora',
            'Esfinge',
            'British Shorthair',
            'Azul Ruso',
            'Bombay',
            'Abisinio',
            'Desconocido',
          ];
          break;

        case 'Ave':
          razas = ['Canario', 'Perico Australiano', 'Cacatúa', 'Desconocido'];
          break;

        case 'Vaca':
          razas = ['Holstein', 'Jersey', 'Angus', 'Desconocido'];
          break;

        case 'Caballo':
          razas = ['Andaluz', 'Pura Sangre', 'Árabe', 'Desconocido'];
          break;

        case 'Conejo':
          razas = ['Rex', 'Cabeza de León', 'Belier', 'Desconocido'];
          break;

        case 'Cerdo':
          razas = ['Yorkshire', 'Duroc', 'Landrace', 'Desconocido'];
          break;

        case 'Reptil':
          razas = ['Iguana Verde', 'Gecko Leopardo', 'Pitón', 'Desconocido'];
          break;

        case 'Pez':
          razas = ['Goldfish', 'Betta', 'Guppy', 'Desconocido'];
          break;

        case 'Otro':
          razas = ['Sin clasificación 1', 'Sin clasificación 2', 'Sin clasificación 3', 'Desconocido'];
          break;

        default:
          razas = ['Desconocido'];
      }

      // 🔹 Insertar las razas correspondientes si no existen
      for (var raza in razas) {
        final existe = await _db
            .collection('breeds')
            .where('nombre', isEqualTo: raza)
            .where('animalTypeId', isEqualTo: tipoId)
            .get();

        if (existe.docs.isEmpty) {
          await _db.collection('breeds').add({
            'nombre': raza,
            'animalTypeId': tipoId,
          });
        }
      }
    }

    Get.snackbar('Éxito', 'Razas de todos los animales agregadas correctamente');
  }
}
