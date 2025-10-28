// lib/controllers/veterinary_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';

class VeterinaryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // === STREAM EN TIEMPO REAL ===
  Stream<List<VeterinaryModel>> getVeterinariesStream() {
    return _db.collection('veterinarias').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => VeterinaryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // === MÉTODO PRIVADO: OBTENER UBICACIÓN ACTUAL (COORDENADAS) ===
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Ubicación desactivada', 'Activa el GPS para continuar');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Permiso denegado', 'No se concedió acceso a la ubicación');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Permiso permanente denegado', 'Ve a configuración para habilitar la ubicación');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la ubicación: $e');
      return null;
    }
  }

  /// Método público para obtener **solo** latitud/longitud (no altera dirección)
  Future<Map<String, double>?> getCurrentCoordinates() async {
    final position = await _getCurrentLocation();
    if (position == null) return null;
    return {
      'latitud': position.latitude,
      'longitud': position.longitude,
    };
  }

  // === AGREGAR VETERINARIA ===
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

  // === ACTUALIZAR VETERINARIA ===
  Future<void> updateVeterinary(String id, VeterinaryModel veterinary) async {
    try {
      await _db.collection('veterinarias').doc(id).update(veterinary.toMap());
      Get.snackbar('Éxito', 'Veterinaria actualizada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar: $e');
    }
  }

  // === ELIMINAR SOLO COORDENADAS (latitud y longitud) ===
  Future<void> removeVeterinaryCoordinates(String id) async {
    try {
      await _db.collection('veterinarias').doc(id).update({
        'latitud': FieldValue.delete(),
        'longitud': FieldValue.delete(),
      });
      Get.snackbar('Coordenadas eliminadas', 'Latitud y longitud borradas correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron eliminar las coordenadas: $e');
    }
  }

  // === OBTENER VETERINARIA POR ID ===
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

  // === BÚSQUEDA POR NOMBRE ===
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
