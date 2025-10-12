import 'package:flutter/material.dart';

class VeterinaryInfoPopup extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onLogout;

  const VeterinaryInfoPopup({
    super.key,
    required this.data,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_hospital, size: 60, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              data['nombre'] ?? "Veterinaria",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.green.shade300),
            const SizedBox(height: 10),
            _buildInfo(Icons.phone, "Teléfono", data['telefono']),
            _buildInfo(Icons.location_on, "Dirección", data['direccion']),
            _buildInfo(Icons.email, "Correo", data['correo']),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar Sesión"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cerrar",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: ${value ?? 'N/A'}",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
