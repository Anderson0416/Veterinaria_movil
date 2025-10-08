import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';

class VeterinaryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream reactivo de la lista (se actualiza en tiempo real)
  Stream<List<VeterinaryModel>> getVeterinariesStream() {
    return _db.collection('veterinarias').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VeterinaryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Agregar veterinaria (si pasas docId lo guarda con ese id; si no, genera uno)
  Future<void> addVeterinary(VeterinaryModel veterinary) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'No hay sesión activa');
        return;
      }

      final docId = veterinary.id ?? currentUser.uid;

      await _db.collection('veterinarias').doc(docId).set(veterinary.toMap());
      Get.snackbar('Éxito', 'Veterinaria registrada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar la veterinaria: $e');
    }
  }

  // Actualizar veterinaria por id
  Future<void> updateVeterinary(String id, VeterinaryModel veterinary) async {
    try {
      await _db.collection('veterinarias').doc(id).update(veterinary.toMap());
      Get.snackbar('Éxito', 'Veterinaria actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar: $e');
    }
  }

  // Eliminar por id
  Future<void> deleteVeterinary(String id) async {
    try {
      await _db.collection('veterinarias').doc(id).delete();
      Get.snackbar('Éxito', 'Veterinaria eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar: $e');
    }
  }

  // Consultar 1 veterinaria por id
  Future<VeterinaryModel?> getVeterinaryById(String id) async {
    try {
      final doc = await _db.collection('veterinarias').doc(id).get();
      if (doc.exists) {
        return VeterinaryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la veterinaria: $e');
      return null;
    }
  }

  // Búsqueda simple por nombre (trae resultados que empiecen con 'prefix')
  Future<List<VeterinaryModel>> searchVeterinaries(String prefix) async {
    try {
      final snapshot = await _db
          .collection('veterinarias')
          .where('nombre', isGreaterThanOrEqualTo: prefix)
          .where('nombre', isLessThanOrEqualTo: '$prefix\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => VeterinaryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo realizar la búsqueda: $e');
      return [];
    }
  }
}
