//Widget personalizado para mostrar las próximas citas del cliente en un Card.

import 'package:flutter/material.dart';

class CustomerAppointmentsCard extends StatelessWidget {
  const CustomerAppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final citas = [
      {"mascota": "Max", "tipo": "Consulta general", "fecha": "2025-01-15", "hora": "10:00"},
      {"mascota": "Luna", "tipo": "Vacunación", "fecha": "2025-01-20", "hora": "14:30"},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🗓️ Próximas Citas",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...citas.map((cita) => _buildCitaItem(cita)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCitaItem(Map<String, String> cita) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cita["mascota"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(cita["tipo"]!, style: const TextStyle(color: Colors.green)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(cita["fecha"]!, style: const TextStyle(color: Colors.black54)),
              Text(cita["hora"]!, style: const TextStyle(color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
