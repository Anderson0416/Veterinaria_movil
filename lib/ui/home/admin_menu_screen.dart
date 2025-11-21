import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';

class AdminMenuScreen extends StatelessWidget {
  AdminMenuScreen({super.key});

  final VeterinaryController veterinaryController = Get.find<VeterinaryController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _cerrarSesion() async {
    await _auth.signOut();
    Get.offAll(() => const LoginScreens());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text(
          "Panel de Administración",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Cerrar sesión",
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: StreamBuilder<List<VeterinaryModel>>(
        stream: veterinaryController.getVeterinariesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No hay veterinarias registradas",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final veterinarias = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Veterinarias Registradas",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: veterinarias.length,
                    itemBuilder: (context, index) {
                      final vet = veterinarias[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vet.nombre,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF388E3C),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.place,
                                                color: Colors.grey, size: 18),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                vet.direccion,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone,
                                                color: Colors.grey, size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              vet.telefono,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Text(
                                              "Estado: ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: vet.activo == true
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                vet.activo == true
                                                    ? "Activa"
                                                    : "Inactiva",
                                                style: TextStyle(
                                                  color: vet.activo == true
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.pets,
                                    color: Colors.green.shade300,
                                    size: 32,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      vet.activo == true
                                          ? Icons.block
                                          : Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      vet.activo == true
                                          ? "Desactivar"
                                          : "Activar",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: vet.activo == true
                                          ? Colors.redAccent
                                          : const Color(0xFF388E3C),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await veterinaryController.updateVeterinary(
                                          vet.id!,
                                          vet.copyWith(
                                            activo: !vet.activo,
                                          ),
                                        );
                                        Get.snackbar(
                                          "Actualizado",
                                          "Estado actualizado correctamente",
                                          backgroundColor:
                                              Colors.green.shade50,
                                        );
                                      } catch (e) {
                                        Get.snackbar("Error",
                                            "No se pudo cambiar el estado: $e");
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
