import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';
import 'package:veterinaria_movil/controllers/factura_controllers.dart';
import 'factura_detail_sheet.dart';

class FacturaCard extends StatelessWidget {
  const FacturaCard({super.key, required this.factura});

  final FacturaModel factura;
  final Color green = const Color(0xFF388E3C);

  @override
  Widget build(BuildContext context) {
    final FacturaController facturaController = Get.find<FacturaController>();

    final fecha =
        "${factura.fechaPago.day}/${factura.fechaPago.month}/${factura.fechaPago.year}";
    final numero = "FAC-${factura.id!.substring(0, 5).toUpperCase()}";

    return GestureDetector(
      onTap: () {
        FacturaDetailSheet.show(
          context: context,
          numeroFactura: numero,
          fecha: fecha,
          servicio: factura.servicioNombre,
          total: factura.total,
          factura: factura,
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
                      await facturaController.crear_pdf(factura);
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
              "Servicio: ${factura.servicioNombre}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),

            Text(
              "Total: \$${factura.total}",
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
