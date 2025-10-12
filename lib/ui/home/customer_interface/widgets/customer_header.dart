//Widget personalizado para mostrar el encabezado de la pantalla principal del cliente,

import 'package:flutter/material.dart';

class CustomerHeader extends StatelessWidget {
  final VoidCallback onProfileTap;
  final String userName;

  const CustomerHeader({
    super.key,
    required this.onProfileTap,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isNotEmpty ? "¡Hola, $userName!" : "¡Hola!",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text("Bienvenido a VetCare",
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
