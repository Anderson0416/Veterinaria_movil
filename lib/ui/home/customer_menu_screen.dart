import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CustomerMenuScreen extends StatelessWidget {
  const CustomerMenuScreen({super.key});

  Future<void> _showCustomerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No hay sesión iniciada");
        return;
      }

      // ✅ Aquí debe ir el nombre correcto de la colección: "customers"
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        Get.snackbar("Sin datos", "No se encontró información de este cliente");
        return;
      }

      final data = doc.data()!;
      Get.defaultDialog(
        title: "Datos del Cliente",
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nombre: ${data['nombre'] ?? 'N/A'}"),
            Text("Apellido: ${data['apellido'] ?? 'N/A'}"),
            Text("Email: ${data['email'] ?? 'N/A'}"),
            Text("Teléfono: ${data['telefono'] ?? 'N/A'}"),
            Text("Fecha Nacimiento: ${data['fechaNacimiento'] ?? 'N/A'}"),
            Text("Tipo Documento: ${data['tipoDocumento'] ?? 'N/A'}"),
            Text("Número Documento: ${data['numeroDocumento'] ?? 'N/A'}"),
            Text("Departamento: ${data['departamento'] ?? 'N/A'}"),
            Text("Ciudad: ${data['ciudad'] ?? 'N/A'}"),
            Text("Dirección: ${data['direccion'] ?? 'N/A'}"),
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
        title: const Text("Menú Cliente"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.person, color: Colors.white),
          label: const Text("Ver mis datos"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          ),
          onPressed: _showCustomerData,
        ),
      ),
    );
  }
}
