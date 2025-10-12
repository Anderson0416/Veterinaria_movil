import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/staff_card.dart';
import '../widgets/staff_form.dart';

class StaffRegisterScreen extends StatefulWidget {
  const StaffRegisterScreen({super.key});

  @override
  State<StaffRegisterScreen> createState() => _StaffRegisterScreenState();
}

class _StaffRegisterScreenState extends State<StaffRegisterScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Registro de Personal"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("personal").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  SizedBox(height: 20),
                  Text("No hay personal registrado aún.",
                      style: TextStyle(color: Colors.black54)),
                  SizedBox(height: 30),
                  StaffForm(),
                ],
              ),
            );
          }

          final personalList = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text("Agregar Nuevo Personal",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Listado del personal
                ...personalList.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return StaffCard(
                    nombre: "${data['nombre']} ${data['apellido'] ?? ''}",
                    rol: data['rol'] ?? 'Sin rol',
                    email: data['email'] ?? '',
                    telefono: data['telefono'] ?? '',
                    activo: true,
                    onEditar: () {
                      Get.snackbar("Editar", "Función en desarrollo");
                    },
                    onPermisos: () {
                      Get.snackbar("Permisos", "Función en desarrollo");
                    },
                  );
                }).toList(),

                const SizedBox(height: 20),
                const StaffForm(),
              ],
            ),
          );
        },
      ),
    );
  }
}
