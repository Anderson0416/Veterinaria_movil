import 'package:flutter/material.dart';

class CustomerPetsCard extends StatelessWidget {
  const CustomerPetsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final mascotas = [
      {"nombre": "Max", "tipo": "Perro"},
      {"nombre": "Luna", "tipo": "Gato"},

    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🐾 Mis Mascotas",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: mascotas.map((m) => _buildMascota(m)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascota(Map<String, String> m) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.pets, color: Colors.green),
        ),
        const SizedBox(height: 6),
        Text(m["nombre"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(m["tipo"]!, style: const TextStyle(color: Colors.green)),
      ],
    );
  }
}
