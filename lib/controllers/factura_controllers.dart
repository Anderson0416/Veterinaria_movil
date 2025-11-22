import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:veterinaria_movil/moldes/factura_model.dart';
import 'package:veterinaria_movil/moldes/customer_model.dart';
import 'package:veterinaria_movil/moldes/service_model.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';
import 'package:veterinaria_movil/moldes/appointment_model.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';

import 'package:veterinaria_movil/controllers/appointment_controllers.dart';
import 'package:veterinaria_movil/controllers/customer_controller.dart';
import 'package:veterinaria_movil/controllers/service_controller.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';

class FacturaController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> crear_pdf(FacturaModel factura) async {
  try {
    final appointmentController = Get.find<AppointmentController>();
    final customerController = Get.find<CustomerController>();
    final serviceController = Get.find<ServiceController>();
    final veterinaryController = Get.find<VeterinaryController>();
    final petController = Get.find<PetController>();

    final CitaModel? cita = await appointmentController.getCitaById(factura.citaId);
    if (cita == null) {
      Get.snackbar('Error', 'No se encontró la cita asociada a la factura');
      return;
    }

    final PetModel? mascota = await petController.getPetById(cita.mascotaId);
    final Customer? dueno = await customerController.getCustomerById(factura.duenoId);
    final ServiceModel? servicio = await serviceController.getServiceById(factura.servicioId);
    final VeterinaryModel? veterinaria = await veterinaryController.getVeterinaryById(factura.veterinariaId);

    if (veterinaria == null || servicio == null || dueno == null) {
      Get.snackbar("Error", "Datos faltantes para generar el PDF");
      return;
    }

    final fechaFactura = factura.fechaPago;
    final fechaStr =
        "${fechaFactura.day.toString().padLeft(2, '0')}/${fechaFactura.month.toString().padLeft(2, '0')}/${fechaFactura.year} ${fechaFactura.hour.toString().padLeft(2, '0')}:${fechaFactura.minute.toString().padLeft(2, '0')}";

    final pdf = pw.Document();

    final baseTextStyle = pw.TextStyle(fontSize: 10);
    final titleStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(veterinaria.nombre, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text("NIT: ${veterinaria.nit}", style: baseTextStyle),
                  pw.Text(veterinaria.direccion, style: baseTextStyle),
                  pw.Text("${veterinaria.departamento ?? ''} - ${veterinaria.ciudad ?? ''}", style: baseTextStyle),
                  pw.Text("Correo: ${veterinaria.correo}", style: baseTextStyle),
                  pw.Text("Tel: ${veterinaria.telefono}", style: baseTextStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("FACTURA", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Código: ${factura.citaId}", style: baseTextStyle),
                        pw.Text("Fecha: $fechaStr", style: baseTextStyle),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 14),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Cliente", style: titleStyle),
                    pw.Text("${dueno.nombre} ${dueno.apellido}", style: baseTextStyle),
                    pw.Text("${dueno.tipoDocumento} ${dueno.numeroDocumento}", style: baseTextStyle),
                    pw.Text("Tel: ${dueno.telefono}", style: baseTextStyle),
                    pw.Text("Dir: ${dueno.direccion}", style: baseTextStyle),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Mascota", style: titleStyle),
                    pw.Text(mascota?.nombre ?? "Sin registro", style: baseTextStyle),
                    pw.Text(mascota?.raza ?? "Raza no disponible", style: baseTextStyle),
                    pw.Text(mascota?.tipo ?? "Tipo no disponible", style: baseTextStyle),
                  ],
                ),
              )
            ],
          ),

          pw.SizedBox(height: 18),

          pw.Text("Detalle del Servicio", style: titleStyle),
          pw.SizedBox(height: 8),

          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(6),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Servicio", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Precio", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Subtotal", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(servicio.nombre, style: baseTextStyle),
                        pw.Text(servicio.descripcion, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("\$${servicio.precio}", style: baseTextStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("\$${factura.total}", style: baseTextStyle)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text("Total: \$${factura.total.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            ],
          )
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
    );
  } catch (e) {
    Get.snackbar("Error", "No se pudo generar el PDF: $e");
  }
}
}
