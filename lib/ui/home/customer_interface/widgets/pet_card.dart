//widget para mostrar la informacion de cada mascota en una tarjeta

import 'package:flutter/material.dart';

class PetCard extends StatelessWidget {
  final String nombre;
  final String raza;
  final String edad;
  final String tipo;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const PetCard({
    super.key,
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tipo,
    required this.onEditar,
    required this.onEliminar,
  });

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
            // Icono redondo
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.pets, color: Colors.green),
            ),
            const SizedBox(width: 14),

            // Datos de la mascota
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          tipo,
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  Text(raza, style: const TextStyle(color: Colors.black54)),
                  Text(edad, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEditar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: BorderSide(color: Colors.green.shade400),
                          ),
                          child: const Text("Editar"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEliminar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text("Eliminar"),
                        ),
                      ),
                    ],
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
