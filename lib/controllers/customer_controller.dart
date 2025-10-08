// lib/controllers/customer_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';

class CustomerController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionName = "customers";

  // Stream reactivo de la lista (se actualiza en tiempo real)
  Stream<List<Customer>> customersStream() {
    return _db.collection(collectionName).orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Customer.fromMap(d.data(), id: d.id)).toList());
  }

  // Agregar customer (si pasas docId lo guarda con ese id; si no, genera uno)
  Future<String?> addCustomer(Customer customer, {String? docId}) async {
    try {
      if (docId != null) {
        await _db.collection(collectionName).doc(docId).set(customer.toMap());
        return docId;
      } else {
        final docRef = await _db.collection(collectionName).add(customer.toMap());
        return docRef.id;
      }
    } catch (e) {
      Get.snackbar("Error", "No se pudo crear cliente: ${e.toString()}");
      return null;
    }
  }

  // Actualizar customer por id
  Future<bool> updateCustomer(String id, Customer customer) async {
    try {
      await _db.collection(collectionName).doc(id).update(customer.toMap());
      return true;
    } catch (e) {
      Get.snackbar("Error", "No se pudo actualizar: ${e.toString()}");
      return false;
    }
  }

  // Eliminar por id
  Future<bool> deleteCustomer(String id) async {
    try {
      await _db.collection(collectionName).doc(id).delete();
      return true;
    } catch (e) {
      Get.snackbar("Error", "No se pudo eliminar: ${e.toString()}");
      return false;
    }
  }

  // Consultar 1 customer por id
  Future<Customer?> getCustomerById(String id) async {
    try {
      final doc = await _db.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return Customer.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      Get.snackbar("Error", "No se pudo obtener cliente: ${e.toString()}");
      return null;
    }
  }

  // Búsqueda simple por nombre (trae resultados que empiecen con 'prefix')
  Future<List<Customer>> searchByNamePrefix(String prefix) async {
    try {
      final snap = await _db.collection(collectionName)
        .where('nombre', isGreaterThanOrEqualTo: prefix)
        .where('nombre', isLessThanOrEqualTo: prefix + '\uf8ff')
        .get();
      return snap.docs.map((d) => Customer.fromMap(d.data(), id: d.id)).toList();
    } catch (e) {
      Get.snackbar("Error", "Búsqueda fallida: ${e.toString()}");
      return [];
    }
  }
}
