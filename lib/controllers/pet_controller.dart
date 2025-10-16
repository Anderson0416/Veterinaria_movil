import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';

class PetController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Obtener flujo de mascotas (para mostrar en tiempo real)
  Stream<List<PetModel>> getPetsStream(String duenoId) {
    return _db
        .collection('pets')
        .where('duenoId', isEqualTo: duenoId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PetModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // 🔹 Agregar nueva mascota
  Future<void> addPet(PetModel pet) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'No hay sesión activa');
        return;
      }

  await _db.collection('pets').add(pet.toMap());
      Get.snackbar('Éxito', 'Mascota registrada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar la mascota: $e');
    }
  }

  // 🔹 Actualizar mascota
  Future<void> updatePet(String id, PetModel pet) async {
    try {
  await _db.collection('pets').doc(id).update(pet.toMap());
      Get.snackbar('Éxito', 'Mascota actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar la mascota: $e');
    }
  }

  // 🔹 Eliminar mascota
  Future<void> deletePet(String id) async {
    try {
  await _db.collection('pets').doc(id).delete();
      Get.snackbar('Éxito', 'Mascota eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar la mascota: $e');
    }
  }

  // 🔹 Obtener una mascota por ID
  Future<PetModel?> getPetById(String id) async {
    try {
  final doc = await _db.collection('pets').doc(id).get();
      if (doc.exists) {
        return PetModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la mascota: $e');
      return null;
    }
  }
}
