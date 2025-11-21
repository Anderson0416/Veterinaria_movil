import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/admin_factura_card.dart';
import 'admin_facturas_all_screen.dart';

class AdminFacturasPreviewScreen extends StatelessWidget {
  AdminFacturasPreviewScreen({super.key});

  final Color green = const Color(0xFF388E3C);

  /// Facturas estáticas de ejemplo
  final List<Map<String, dynamic>> facturas = [
    {
      'id': 'FAC-10001',
      'cliente': 'Carlos Gómez',
      'servicio': 'Vacunación',
      'fecha': '22/01/2025',
      'total': 65000,
    },
    {
      'id': 'FAC-10002',
      'cliente': 'Ana Torres',
      'servicio': 'Consulta General',
      'fecha': '20/01/2025',
      'total': 45000,
    },
    {
      'id': 'FAC-10003',
      'cliente': 'Luis Pérez',
      'servicio': 'Baño y Peluquería',
      'fecha': '19/01/2025',
      'total': 80000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        title: const Text("Facturas Generales"),
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

            /// Cards estáticos
            ...facturas.map((f) => AdminFacturaCard(factura: f)),

            const SizedBox(height: 20),

            /// Botón para ver todas las facturas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const AdminFacturasAllScreen()),
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
}
