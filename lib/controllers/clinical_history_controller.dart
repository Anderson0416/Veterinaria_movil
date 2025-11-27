import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/moldes/clinical_history_model.dart';

class ClinicalHistoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear registro de historial clínico
  Future<String> createClinicalHistory(ClinicalHistoryModel history) async {
    try {
      final ref = await _db.collection('clinical_history').add(history.toJson());
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener historial clínico por ID
  Future<ClinicalHistoryModel?> getClinicalHistoryById(String id) async {
    try {
      final doc = await _db.collection('clinical_history').doc(id).get();
      if (!doc.exists) return null;
      
      return ClinicalHistoryModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener el historial: $e');
      return null;
    }
  }

  //  Obtener TODO el historial de UNA mascota (de todas las veterinarias)
  Stream<List<ClinicalHistoryModel>> getClinicalHistoryByPetId(String mascotaId) {
    return _db
        .collection('clinical_history')
        .where('mascotaId', isEqualTo: mascotaId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClinicalHistoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  //  Obtener historial de TODAS las mascotas de UNA veterinaria
  Stream<List<ClinicalHistoryModel>> getClinicalHistoryByVeterinaryId(String veterinariaId) {
    return _db
        .collection('clinical_history')
        .where('veterinariaId', isEqualTo: veterinariaId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClinicalHistoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Obtener TODOS los historiales (para admin o búsqueda global)
  Stream<List<ClinicalHistoryModel>> getAllClinicalHistories() {
    return _db
        .collection('clinical_history')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClinicalHistoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Obtener historial por veterinario (lo dejé por si lo necesitas)
  Stream<List<ClinicalHistoryModel>> getClinicalHistoryByVet(String veterinarioId) {
    return _db
        .collection('clinical_history')
        .where('veterinarioId', isEqualTo: veterinarioId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClinicalHistoryModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Actualizar historial clínico
  Future<void> updateClinicalHistory(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('clinical_history').doc(id).update(data);
      Get.snackbar('Éxito', 'Historial actualizado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar: $e');
    }
  }

  // Eliminar historial clínico
  Future<void> deleteClinicalHistory(String id) async {
    try {
      await _db.collection('clinical_history').doc(id).delete();
      Get.snackbar('Éxito', 'Historial eliminado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar: $e');
    }
  }
}