import 'package:flutter/material.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/pet_history_card.dart';


class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista simulada con varias mascotas (datos de prueba)
    final historialMascotas = [
      {
        "nombreMascota": "Max",
        "fecha": "2025-10-03",
        "tipo": "Consulta general",
        "veterinario": "Dr. García",
        "descripcion": "Revisión general. Todo en orden.",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Historial de Mascotas"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: historialMascotas.length,
          itemBuilder: (context, index) {
            final item = historialMascotas[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["nombreMascota"] ?? "Mascota",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                PetHistoryCard(
                  fecha: item["fecha"]!,
                  tipo: item["tipo"]!,
                  veterinario: item["veterinario"]!,
                  descripcion: item["descripcion"]!,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
