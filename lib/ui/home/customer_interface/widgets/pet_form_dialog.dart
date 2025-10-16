// widget para el formulario de registro y edición de mascotas

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';

class PetFormDialog extends StatelessWidget {
  final Map<String, dynamic>? mascota;
  final bool modoEditar;

  const PetFormDialog({super.key, this.mascota, this.modoEditar = false});

  @override
  Widget build(BuildContext context) {
    final nombreCtrl = TextEditingController(text: mascota?['nombre'] ?? '');
    final razaCtrl = TextEditingController(text: mascota?['raza'] ?? '');
    final edadCtrl = TextEditingController(text: mascota?['edad'] ?? '');
    final tipoCtrl = TextEditingController(text: mascota?['tipo'] ?? '');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                modoEditar ? "Editar Mascota" : "Registrar Nueva Mascota",
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: razaCtrl,
                decoration: const InputDecoration(
                  labelText: "Raza / Especie",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: edadCtrl,
                decoration: const InputDecoration(
                  labelText: "Edad (ej. 2 años)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: tipoCtrl,
                decoration: const InputDecoration(
                  labelText: "Tipo (Perro, Gato, etc.)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final petController = Get.find<PetController>();
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            Get.snackbar('Error', 'No hay sesión activa');
                            return;
                          }

                          final duenoId = user.uid;

                          if (modoEditar && mascota?['id'] != null) {
                            final id = mascota!['id'] as String;
                            final updatedPet = PetModel(
                              id: id,
                              nombre: nombreCtrl.text.trim(),
                              raza: razaCtrl.text.trim(),
                              edad: edadCtrl.text.trim(),
                              tipo: tipoCtrl.text.trim(),
                              duenoId: duenoId,
                            );

                            await petController.updatePet(id, updatedPet);
                            Get.back();
                            Get.snackbar(
                              "Actualizado",
                              "Los datos de la mascota fueron actualizados correctamente.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.shade100,
                            );
                          } else {
                            final newPet = PetModel(
                              nombre: nombreCtrl.text.trim(),
                              raza: razaCtrl.text.trim(),
                              edad: edadCtrl.text.trim(),
                              tipo: tipoCtrl.text.trim(),
                              duenoId: duenoId,
                            );

                            await petController.addPet(newPet);
                            Get.back();
                            Get.snackbar(
                              "Registrado",
                              "La mascota fue registrada correctamente.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.shade100,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "No se pudo guardar la información: $e",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(modoEditar ? "Guardar Cambios" : "Registrar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade400),
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancelar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
