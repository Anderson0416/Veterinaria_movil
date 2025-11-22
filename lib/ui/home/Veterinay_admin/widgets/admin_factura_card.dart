import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/factura_controllers.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/widgets/factura_detail_sheet_admin.dart';

class AdminFacturaCard extends StatelessWidget {
  const AdminFacturaCard({super.key, required this.factura});

  final Map<String, dynamic> factura;
  final Color green = const Color(0xFF388E3C);

  @override
  Widget build(BuildContext context) {
    final FacturaController facturaController = Get.find<FacturaController>();

    // FORMATO DE FECHA
    final DateTime fechaPago = factura['fecha'];
    final fecha = "${fechaPago.day}/${fechaPago.month}/${fechaPago.year}";

    // CÓDIGO FACTURA
    final numero = "FAC-${factura['id'].substring(0, 5).toUpperCase()}";

    return GestureDetector(
      onTap: () {
        AdminFacturaDetailSheet.show(
          context: context,
          numeroFactura: numero,
          cliente: factura['duenoNombre'],
          servicio: factura['servicioNombre'],
          fecha: fecha,
          total: factura['total'],
          facturaMap: factura,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // SUPERIOR: ID y PDF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  numero,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
                  onPressed: () async {
                    try {
                      // Convertimos MAP a FacturaModel para usar el PDF generado
                      final FacturaModel facturaModel = FacturaModel.fromJson(factura, factura["id"]);
                      await facturaController.crear_pdf(facturaModel);
                    } catch (e) {
                      Get.snackbar(
                        "Error",
                        "No se pudo generar el PDF: $e",
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text("Fecha: $fecha", style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),

            Text(
              "Servicio: ${factura['servicioNombre']}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),

            Text(
              "Total: \$${factura['total']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
