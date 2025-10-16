import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/moldes/veterinarian_models.dart';

class VeterinarianController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🟢 Obtener veterinarios SOLO de la veterinaria logueada
  Stream<List<VeterinarianModel>> getVeterinariansStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _db
        .collection('veterinarians')
        .where('veterinaryId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VeterinarianModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // 🟢 Agregar veterinario
  Future<void> addVeterinarian(VeterinarianModel veterinarian) async {
    try {
      if (veterinarian.id != null && veterinarian.id!.isNotEmpty) {
        await _db.collection('veterinarians').doc(veterinarian.id).set(veterinarian.toMap());
      } else {
        await _db.collection('veterinarians').add(veterinarian.toMap());
      }
      Get.snackbar('Éxito', 'Veterinario registrado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar el veterinario: $e');
    }
  }

  // 🟡 Actualizar veterinario
  Future<void> updateVeterinarian(
      String id, VeterinarianModel veterinarian) async {
    try {
      await _db.collection('veterinarians').doc(id).update(veterinarian.toMap());
      Get.snackbar('Éxito', 'Veterinario actualizado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar: $e');
    }
  }

  // 🔴 Eliminar veterinario
  Future<void> deleteVeterinarian(String id) async {
    try {
      await _db.collection('veterinarians').doc(id).delete();
      Get.snackbar('Éxito', 'Veterinario eliminado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar: $e');
    }
  }

  // 🔍 Obtener veterinario por ID
  Future<VeterinarianModel?> getVeterinarianById(String id) async {
    try {
      final doc = await _db.collection('veterinarians').doc(id).get();
      if (doc.exists) {
        return VeterinarianModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener el veterinario: $e');
      return null;
    }
  }
}
