//Widget personalizado que muestra tres botones de acción para el cliente:

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/agendarcita_screen.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/historial_screen.dart';


import '../screens/mis_mascotas_screen.dart';

class CustomerActionButtons extends StatelessWidget {
  const CustomerActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAction(Icons.calendar_month, "Agendar Cita", () {
          Get.to(() => const AgendarCitaScreen());
        }),
        _buildAction(Icons.history, "Historial", () {
          Get.to(() => const HistorialScreen());
        }),
        _buildAction(Icons.pets, "Mis Mascotas", () {
          Get.to(() => const MisMascotasScreen());
        }),
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.green.shade700, size: 28),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: Colors.green.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}
