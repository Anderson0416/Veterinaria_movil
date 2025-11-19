import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';
import 'package:veterinaria_movil/moldes/service_model.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class FacturaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 NO CREA FACTURAS DUPLICADAS
  Future<String> crearFactura(FacturaModel factura) async {
    final ref = _db.collection("facturas").doc(factura.citaId);
    await ref.set(factura.toJson());
    return ref.id;
  }

  Future<FacturaModel?> getFactura(String id) async {
    final doc = await _db.collection("facturas").doc(id).get();
    if (!doc.exists) return null;
    return FacturaModel.fromJson(doc.data()!, doc.id);
  }

  Future<FacturaModel?> getFacturaPorCita(String citaId) async {
    final doc = await _db.collection("facturas").doc(citaId).get();
    if (!doc.exists) return null;
    return FacturaModel.fromJson(doc.data()!, doc.id);
  }

  Future<File> crear_pdf({
  required FacturaModel factura,
  required Customer dueno,
  required VeterinaryModel veterinaria,
  required ServiceModel servicio,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(25),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            /// ENCABEZADO
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      veterinaria.nombre,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(veterinaria.direccion),
                    pw.SizedBox(height: 5),
                  ],
                ),
                pw.Text(
                  "FACTURA",
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            pw.Divider(),

            pw.SizedBox(height: 10),

            /// INFO DEL CLIENTE
            pw.Text("Datos del Cliente",
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),

            pw.Text("Nombre: ${dueno.nombre}"),
            pw.Text("Documento: ${dueno.numeroDocumento}"),

            pw.SizedBox(height: 15),

            /// INFO DE LA FACTURA
            pw.Text("Información de la Factura",
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text("Código de la cita: ${factura.citaId}"),
            pw.Text("Fecha de pago: ${factura.fechaPago.toString().split('.')[0]}"),

            pw.SizedBox(height: 20),

            /// TABLA DE SERVICIO FACTURADO
            pw.Table(
              border: pw.TableBorder.all(width: 1),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor(0.9, 0.9, 0.9)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Servicio",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Precio",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(servicio.nombre),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("\$${servicio.precio.toStringAsFixed(2)}"),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 15),

            /// TOTAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  "TOTAL: ",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "\$${factura.total.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 18),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            pw.Center(
              child: pw.Text(
                "¡Gracias por confiar en nosotros!",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            )
          ],
        );
      },
    ),
  );

  /// GUARDAR PDF
  final dir = await getApplicationDocumentsDirectory();
  final file = File("${dir.path}/factura_${factura.citaId}.pdf");

  await file.writeAsBytes(await pdf.save());

  Get.snackbar("Factura generada", "El PDF fue creado correctamente.");

  return file;
}

}
