//Widget personalizado para mostrar la información de la clínica veterinaria


import 'package:flutter/material.dart';

class ClinicInfoCard extends StatelessWidget {
  final String nombre;
  final String direccion;
  final String telefono;

  const ClinicInfoCard({
    super.key,
    required this.nombre,
    required this.direccion,
    required this.telefono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(direccion,
                            style: const TextStyle(color: Colors.black54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Text(telefono,
                          style: const TextStyle(color: Colors.black54)),
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
