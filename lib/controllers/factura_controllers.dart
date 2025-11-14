import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';

class FacturaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear factura
  Future<String> crearFactura(FacturaModel factura) async {
    final ref = await _db.collection("facturas").add(factura.toJson());
    return ref.id;
  }

  // Obtener factura por ID
  Future<FacturaModel?> getFactura(String id) async {
    final doc = await _db.collection("facturas").doc(id).get();
    if (!doc.exists) return null;

    return FacturaModel.fromJson(doc.data()!, doc.id);
  }

  // Facturas por dueño
  Stream<List<FacturaModel>> getFacturasPorDueno(String duenoId) {
    return _db
        .collection("facturas")
        .where("duenoId", isEqualTo: duenoId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FacturaModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Facturas por veterinaria
  Stream<List<FacturaModel>> getFacturasPorVeterinaria(String veterinariaId) {
    return _db
        .collection("facturas")
        .where("veterinariaId", isEqualTo: veterinariaId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FacturaModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Obtener factura asociada a una cita
  Future<FacturaModel?> getFacturaPorCita(String citaId) async {
    final query = await _db
        .collection("facturas")
        .where("citaId", isEqualTo: citaId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return FacturaModel.fromJson(query.docs.first.data(), query.docs.first.id);
  }

  //Todas las facturas en stream
  Stream<List<FacturaModel>> getFacturasStream() {
    return _db.collection("facturas").snapshots().map((snap) => snap.docs
        .map((doc) => FacturaModel.fromJson(doc.data(), doc.id))
        .toList());
  }
}
