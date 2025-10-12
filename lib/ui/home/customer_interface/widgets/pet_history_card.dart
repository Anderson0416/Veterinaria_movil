//widget para mostrar el historial de una mascota

import 'package:flutter/material.dart';

class PetHistoryCard extends StatelessWidget {
  final String fecha;
  final String tipo;
  final String veterinario;
  final String descripcion;

  const PetHistoryCard({
    super.key,
    required this.fecha,
    required this.tipo,
    required this.veterinario,
    required this.descripcion,
  });

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case "vacunación":
        return Icons.vaccines;
      case "control dental":
        return Icons.medical_services_outlined;
      case "tratamiento":
        return Icons.healing;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.shade50,
              child: Icon(_iconForType(tipo), color: Colors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text("Veterinario: $veterinario",
                      style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text("Fecha: $fecha",
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
