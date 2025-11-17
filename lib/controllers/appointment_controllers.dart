import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/moldes/appointment_model.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';

class AppointmentController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear cita
  Future<String> crearCita(CitaModel cita) async {
    final ref = await _db.collection("appointments").add(cita.toJson());
    return ref.id;
  }

  // Actualizar cita
  Future<void> actualizarCita(String citaId, Map<String, dynamic> data) async {
    await _db.collection("appointments").doc(citaId).update(data);
  }

  // Eliminar cita
  Future<void> eliminarCita(String citaId) async {
    await _db.collection("appointments").doc(citaId).delete();
  }

  // Obtener cita por ID
  Future<CitaModel?> getCitaById(String id) async {
    final doc = await _db.collection("appointments").doc(id).get();
    if (!doc.exists) return null;

    return CitaModel.fromJson(doc.data()!, doc.id);
  }

  // Stream todas las citas
  Stream<List<CitaModel>> getCitasStream() {
    return _db.collection("appointments").snapshots().map(
        (snap) => snap.docs
            .map((doc) => CitaModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Citas por dueño
  Stream<List<CitaModel>> getCitasPorDueno(String duenoId) {
    return _db
        .collection("appointments")
        .where("duenoId", isEqualTo: duenoId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CitaModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Cambiar estado
  Future<void> actualizarEstado(String citaId, String nuevoEstado) async {
    await _db.collection("appointments").doc(citaId).update({
      'estado': nuevoEstado,
    });
  }

  // Marcar como pagada + generar factura
  Future<void> marcarComoPagada(CitaModel cita) async {
    await _db.collection("appointments").doc(cita.id).update({
      'pagado': true,
    });

    final factura = FacturaModel(
      citaId: cita.id!,
      duenoId: cita.duenoId,
      veterinariaId: cita.veterinariaId,
      servicioId: cita.servicioId,
      servicioNombre: "", 
      total: cita.precioServicio,
      fechaPago: DateTime.now(),
    );

    await _db.collection("facturas").add(factura.toJson());
  }
}
