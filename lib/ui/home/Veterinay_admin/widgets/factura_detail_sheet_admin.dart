import 'package:flutter/material.dart';

class AdminFacturaDetailSheet {
  static void show({
    required BuildContext context,
    required String numeroFactura,
    required String cliente,
    required String servicio,
    required String fecha,
    required double total,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                "Detalles de Factura",
                style: TextStyle(
                  color: const Color(0xFF388E3C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              _info("Número:", numeroFactura),
              _info("Cliente:", cliente),
              _info("Servicio:", servicio),
              _info("Fecha:", fecha),
              _info("Total:", "\$$total"),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
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
        );
      },
    );
  }

  static Widget _info(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
