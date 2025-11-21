import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'mis_facturas_screen.dart';
import '../widgets/factura_detail_sheet.dart';

class MisFacturasPreviewScreen extends StatelessWidget {
  MisFacturasPreviewScreen({super.key});

  final Color green = const Color(0xFF388E3C);

  final List<Map<String, dynamic>> facturasEjemplo = [
    {
      'id': 'FAC-00123',
      'fecha': '15/01/2025',
      'servicio': 'Consulta General',
      'total': 45000,
    },
    {
      'id': 'FAC-00456',
      'fecha': '10/01/2025',
      'servicio': 'Vacunación Canina',
      'total': 70000,
    },
    {
      'id': 'FAC-00789',
      'fecha': '05/01/2025',
      'servicio': 'Desparasitación',
      'total': 30000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        title: const Text("Mis Facturas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Facturas Recientes",
              style: TextStyle(
                color: green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            /// Lista estática con bottom sheet
            ...facturasEjemplo.map((f) {
              return GestureDetector(
                onTap: () {
                  FacturaDetailSheet.show(
                    context: context,
                    numeroFactura: f['id'],
                    fecha: f['fecha'],
                    servicio: f['servicio'],
                    total: f['total'].toDouble(),
                  );
                },
                child: _buildFacturaCard(f),
              );
            }).toList(),

            const SizedBox(height: 25),

            /// Botón para ver todas las facturas dinámicas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const MisFacturasScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Ver todas las facturas",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// CARD ESTÁTICO
  Widget _buildFacturaCard(Map<String, dynamic> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número de factura + PDF
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f['id'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: green,
                ),
              ),
              Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
            ],
          ),
          const SizedBox(height: 4),
          Text("Fecha: ${f['fecha']}", style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text("Servicio: ${f['servicio']}", style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            "Valor: \$${f['total']}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ],
      ),
    );
  }
}
