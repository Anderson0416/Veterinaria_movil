import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

  // === OBTENER UBICACIÓN ACTUAL DEL USUARIO ===
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

      // Si todo está bien, obtener posición actual
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la ubicación: $e');
      return null;
    }
  }

  // === OBTENER NOMBRE DE LA DIRECCIÓN ===
  Future<String?> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo obtener la dirección: $e');
      return null;
    }
  }

  // === AGREGAR VETERINARIA ===
  Future<void> addVeterinary(VeterinaryModel veterinary) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'No hay sesión activa');
        return;
      }

      // Obtener ubicación actual
      final position = await _getCurrentLocation();
      String? direccion;
      if (position != null) {
        direccion = await _getAddressFromPosition(position);
      }

      // Actualizar datos del modelo con la ubicación
      final veterinaryWithLocation = veterinary.copyWith(
        latitud: position?.latitude,
        longitud: position?.longitude,
        direccion: direccion,
      );

      final docId = veterinary.id ?? currentUser.uid;
      await _db.collection('veterinarias').doc(docId).set(veterinaryWithLocation.toMap());

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

  // === ELIMINAR VETERINARIA ===
  Future<void> deleteVeterinary(String id) async {
    try {
      await _db.collection('veterinarias').doc(id).delete();
      Get.snackbar('Éxito', 'Veterinaria eliminada correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar: $e');
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
