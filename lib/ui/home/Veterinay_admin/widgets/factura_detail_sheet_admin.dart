import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/factura_controllers.dart';
import 'package:veterinaria_movil/moldes/factura_model.dart';

class AdminFacturaDetailSheet {
  static void show({
    required BuildContext context,
    required String numeroFactura,
    required String cliente,
    required String servicio,
    required String fecha,
    required double total,
    required Map<String, dynamic> facturaMap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  "Detalles de la Factura",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                const SizedBox(height: 16),

                _item("Número de factura:", numeroFactura),
                _item("Cliente:", cliente),
                _item("Servicio:", servicio),
                _item("Fecha:", fecha),
                _item("Total:", "\$$total"),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final facturaController = Get.find<FacturaController>();

                        // Convertir MAP → FacturaModel para el PDF
                        final facturaModel =
                            FacturaModel.fromJson(facturaMap, facturaMap["id"]);

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
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text("Descargar PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _item(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
