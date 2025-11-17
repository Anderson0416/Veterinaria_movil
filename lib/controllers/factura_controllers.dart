import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// Modelos
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';
import 'package:veterinaria_movil/moldes/service_model.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';

// PDF
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

// Email
import 'package:flutter_email_sender/flutter_email_sender.dart';

class FacturaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> crearFactura(FacturaModel factura) async {
    final ref = await _db.collection("facturas").add(factura.toJson());
    return ref.id;
  }

  Future<FacturaModel?> getFactura(String id) async {
    final doc = await _db.collection("facturas").doc(id).get();
    if (!doc.exists) return null;

    return FacturaModel.fromJson(doc.data()!, doc.id);
  }

  Future<FacturaModel?> getFacturaPorCita(String citaId) async {
    final query = await _db
        .collection("facturas")
        .where("citaId", isEqualTo: citaId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return FacturaModel.fromJson(query.docs.first.data(), query.docs.first.id);
  }

  // ==========================================================
  // 🔥 YA NO DUPLICA PDFs — Solo crea SI NO existe 🔥
  // ==========================================================
  Future<void> enviarFacturaPorCorreo({
    required FacturaModel factura,
    required String correoCliente,
    required Customer dueno,
    required VeterinaryModel veterinaria,
    required ServiceModel servicio,
  }) async {
    try {
      // Ruta del PDF
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/factura_${factura.id}.pdf';
      final pdfFile = File(path);

      // Crear PDF SOLO si NO existe
      if (!await pdfFile.exists()) {
        print("📄 Generando PDF por primera vez...");

        final pdf = pw.Document();

        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Factura Veterinaria",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 15),

                // Cliente
                pw.Text("Cliente: ${dueno.nombre}"),
                pw.Text("Documento: ${dueno.numeroDocumento}"),
                pw.SizedBox(height: 10),

                // Veterinaria
                pw.Text("Veterinaria: ${veterinaria.nombre}"),
                pw.Text("Dirección: ${veterinaria.direccion}"),
                pw.SizedBox(height: 10),

                // Servicio
                pw.Text("Servicio: ${servicio.nombre}"),
                pw.Text("Precio: \$${servicio.precio.toStringAsFixed(2)}"),
              ],
            ),
          ),
        );

        await pdfFile.writeAsBytes(await pdf.save());
      } else {
        print("✔ PDF ya existe, no se vuelve a generar.");
      }

      // Enviar correo
      final email = Email(
        body:
            "Adjunto se encuentra la factura correspondiente a tu cita veterinaria.",
        subject: "Factura Veterinaria",
        recipients: [correoCliente],
        attachmentPaths: [path],
      );

      await FlutterEmailSender.send(email);

      Get.snackbar("Éxito", "Factura enviada al correo.");
    } catch (e) {
      print("❌ ERROR enviando factura: $e");
      Get.snackbar("Error", "No se pudo enviar la factura al correo.");
    }
  }
}
