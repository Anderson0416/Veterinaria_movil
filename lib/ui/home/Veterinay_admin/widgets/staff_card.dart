import 'package:flutter/material.dart';

class StaffCard extends StatelessWidget {
  final String nombre;
  final String rol;
  final String email;
  final String telefono;
  final bool activo;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const StaffCard({
    super.key,
    required this.nombre,
    required this.rol,
    required this.email,
    required this.telefono,
    required this.activo,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(rol, style: TextStyle(color: Colors.green.shade800)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.black54)),
                  Text(telefono, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onEditar,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Editar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onEliminar,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text("Eliminar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: activo ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                activo ? "Activo" : "Inactivo",
                style: TextStyle(
                  color: activo ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}