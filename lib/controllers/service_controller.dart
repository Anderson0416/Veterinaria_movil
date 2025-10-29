import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/moldes/service_model.dart';

class ServiceController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //  Stream para listar los servicios de la veterinaria logueada
  Stream<List<ServiceModel>> getServicesStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _db
        .collection('types_services')
        .where('veterinaryId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data(), doc.id)).toList());
  }

  //  Agregar servicio
  Future<bool> addService(ServiceModel service) async {
    try {
      await _db.collection('types_services').add(service.toMap());
      Get.snackbar('Éxito', 'Servicio agregado correctamente');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar el servicio: $e');
      return false;
    }
  }

  //  Actualizar servicio
  Future<bool> updateService(String id, ServiceModel service) async {
    try {
      await _db.collection('types_services').doc(id).update(service.toMap());
      Get.snackbar('Éxito', 'Servicio actualizado correctamente');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el servicio: $e');
      return false;
    }
  }

  //  Eliminar servicio
  Future<void> deleteService(String id) async {
    try {
      await _db.collection('types_services').doc(id).delete();
      Get.snackbar('Éxito', 'Servicio eliminado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el servicio: $e');
    }
  }
}
