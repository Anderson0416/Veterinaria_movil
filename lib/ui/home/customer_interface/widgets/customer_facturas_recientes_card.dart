import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/factura_controllers.dart';

import '../../../../moldes/factura_model.dart';
import '../screens/mis_facturas_screen.dart';

class CustomerRecentInvoicesCard extends StatelessWidget {
  CustomerRecentInvoicesCard({super.key});

  final Color green = const Color(0xFF388E3C);
  final Color greenLight = const Color(0xFFE8F5E9);
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FacturaModel>> _getRecentInvoices() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection("facturas")
        .where("duenoId", isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        // Convertir documentos a modelos
        final facturas = snapshot.docs
            .map((d) {
              try {
                return FacturaModel.fromJson(d.data(), d.id);
              } catch (e) {
                print('Error parsing factura: $e');
                return null;
              }
            })
            .whereType<FacturaModel>()
            .toList();

        // Ordenar por fecha descendente (más recientes primero)
        facturas.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));

        // Limitar a 3
        return facturas.take(3).toList();
      } catch (e) {
        print('Error in _getRecentInvoices: $e');
        return [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: greenLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long, color: green, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                "Facturas Recientes",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // STREAM DE 3 FACTURAS RECIENTES
          StreamBuilder<List<FacturaModel>>(
            stream: _getRecentInvoices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                print('StreamBuilder error: ${snapshot.error}');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          "Error al cargar facturas",
                          style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // Fuerza un rebuild del StreamBuilder
                          },
                          child: const Text("Reintentar"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final facturas = snapshot.data ?? [];

              if (facturas.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Aún no tienes facturas generadas",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(
                  facturas.length,
                  (index) => Column(
                    children: [
                      _buildInvoiceItem(context, facturas[index]),
                      if (index < facturas.length - 1)
                        Divider(color: Colors.grey.shade200, height: 16),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Get.to(() => const MisFacturasScreen()),
              child: Text(
                "Ver todas las facturas",
                style: TextStyle(color: green, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showFacturaDetailSheet(BuildContext context, FacturaModel factura) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "FAC-${factura.id!.substring(0, 5).toUpperCase()}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow("Servicio", factura.servicioNombre),
            _buildDetailRow("Total", "\$${factura.total.toStringAsFixed(2)}"),
            _buildDetailRow(
              "Fecha",
              "${factura.fechaPago.day}/${factura.fechaPago.month}/${factura.fechaPago.year}",
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Get.back();
                  await Future.delayed(const Duration(milliseconds: 200));
                  final facturaController = Get.find<FacturaController>();
                  await facturaController.crear_pdf(factura);
                },
                icon: const Icon(Icons.download),
                label: const Text("Descargar PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(BuildContext context, FacturaModel factura) {
    final fecha =
        "${factura.fechaPago.day}/${factura.fechaPago.month}/${factura.fechaPago.year}";
    final numero = "FAC-${factura.id!.substring(0, 5).toUpperCase()}";

    return GestureDetector(
      onTap: () => showFacturaDetailSheet(context, factura),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: greenLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // IZQUIERDA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    numero,
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Fecha: $fecha",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Servicio: ${factura.servicioNombre}",
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // DERECHA
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$${factura.total.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, color: green, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
