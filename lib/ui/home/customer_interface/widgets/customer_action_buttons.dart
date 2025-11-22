import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/agendarcita_screen.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/historial_screen.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/mis_facturas_screen.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/mis_mascotas_screen.dart';

class CustomerActionButtons extends StatelessWidget {
  const CustomerActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildAction(
          Icons.calendar_month,
          "Agendar Cita",
          () => Get.to(() => const AgendarCitaScreen()),
        ),
        _buildAction(
          Icons.history,
          "Historial",
          () => Get.to(() => const HistorialScreen()),
        ),
        _buildAction(
          Icons.pets,
          "Mis Mascotas",
          () => Get.to(() => const MisMascotasScreen()),
        ),
        _buildAction(
          Icons.receipt_long,
          "Mis Facturas",
          () => Get.to(() => const MisFacturasScreen()),
        ),
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green.shade700, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
}