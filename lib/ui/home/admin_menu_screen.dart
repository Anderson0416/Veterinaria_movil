import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';

class AdminMenuScreen extends StatelessWidget {
  AdminMenuScreen({super.key});

  final VeterinaryController veterinaryController = Get.find<VeterinaryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<List<VeterinaryModel>>(
        stream: veterinaryController.getVeterinariesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay veterinarias registradas"));
          }

          final veterinarias = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: veterinarias.length,
            itemBuilder: (context, index) {
              final vet = veterinarias[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    vet.nombre ?? 'Sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        vet.direccion ?? 'Sin dirección',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            "Estado: ",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            vet.activo == true ? "Activa" : "Inactiva",
                            style: TextStyle(
                              color: vet.activo == true
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          vet.activo == true ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await veterinaryController.updateVeterinary(
                          vet.id!,
                          vet.copyWith(activo: !(vet.activo ?? false)),
                        );
                      } catch (e) {
                        Get.snackbar("Error", "No se pudo cambiar el estado: $e");
                      }
                    },
                    child: Text(
                      vet.activo == true ? "Desactivar" : "Activar",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
