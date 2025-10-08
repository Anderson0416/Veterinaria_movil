import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class VeterinaryMenuScreen extends StatelessWidget {
  const VeterinaryMenuScreen({super.key});

  Future<void> _showVeterinaryData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No hay sesión iniciada");
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('veterinarias')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        Get.snackbar("Sin datos", "No se encontró información de esta veterinaria");
        return;
      }

      final data = doc.data()!;
      Get.defaultDialog(
        title: "Datos de la Veterinaria",
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nombre: ${data['nombre'] ?? 'N/A'}"),
            Text("Teléfono: ${data['telefono'] ?? 'N/A'}"),
            Text("Dirección: ${data['direccion'] ?? 'N/A'}"),
            Text("Correo: ${data['correo'] ?? 'N/A'}"),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar("Error", "Ocurrió un problema: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú Veterinaria"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.info, color: Colors.white),
          label: const Text("Ver mis datos"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          ),
          onPressed: _showVeterinaryData,
        ),
      ),
    );
  }
}
