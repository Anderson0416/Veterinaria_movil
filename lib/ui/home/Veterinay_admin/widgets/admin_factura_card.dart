import 'package:flutter/material.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/widgets/factura_detail_sheet_admin.dart';

class AdminFacturaCard extends StatelessWidget {
  const AdminFacturaCard({super.key, required this.factura});

  final Map<String, dynamic> factura;
  final Color green = const Color(0xFF388E3C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AdminFacturaDetailSheet.show(
          context: context,
          numeroFactura: factura['id'],
          cliente: factura['cliente'],
          servicio: factura['servicio'],
          fecha: factura['fecha'],
          total: factura['total'],
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
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  factura['id'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                Icon(Icons.picture_as_pdf, color: Colors.red.shade400),
              ],
            ),

            const SizedBox(height: 4),
            Text("Cliente: ${factura['cliente']}"),
            const SizedBox(height: 4),
            Text("Servicio: ${factura['servicio']}"),
            const SizedBox(height: 4),
            Text("Fecha: ${factura['fecha']}"),
            const SizedBox(height: 6),

            Text(
              "Total: \$${factura['total']}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
