import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/pet_card.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/pet_form_dialog.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisMascotasScreen extends StatefulWidget {
  const MisMascotasScreen({super.key});

  @override
  State<MisMascotasScreen> createState() => _MisMascotasScreenState();
}

class _MisMascotasScreenState extends State<MisMascotasScreen> {
  final petController = Get.find<PetController>();

  void _agregarMascota() async {
    // 🔹 Abrir el formulario y cerrar automáticamente al guardar
    final resultado = await Get.dialog(const PetFormDialog());
    if (resultado == true) {
      Get.snackbar('Éxito', 'Mascota registrada correctamente',
          backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Mis Mascotas"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<PetModel>>(
                stream: petController.getPetsStream(
                    FirebaseAuth.instance.currentUser?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.green));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final mascotas = snapshot.data ?? [];
                  if (mascotas.isEmpty) {
                    return const Center(
                        child: Text('No hay mascotas registradas aún',
                            style: TextStyle(color: Colors.black54)));
                  }

                  return ListView.builder(
                    itemCount: mascotas.length,
                    itemBuilder: (context, index) {
                      final mascota = mascotas[index];
                      return PetCard(
                        nombre: mascota.nombre,
                        raza: mascota.raza,
                        edad: mascota.edad,
                        tipo: mascota.tipo,
                        onEditar: () async {
                          final resultado = await Get.dialog(PetFormDialog(
                            mascota: {
                              'id': mascota.id,
                              'nombre': mascota.nombre,
                              'raza': mascota.raza,
                              'edad': mascota.edad,
                              'tipo': mascota.tipo,
                            },
                            modoEditar: true,
                          ));
                          if (resultado == true) {
                            Get.snackbar('Éxito', 'Mascota actualizada correctamente',
                                backgroundColor: Colors.green,
                                colorText: Colors.white);
                          }
                        },
                        onEliminar: () async {
                          final confirm = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Confirmar'),
                              content: Text(
                                "¿Seguro que deseas eliminar a '${mascota.nombre}'?",
                                style: const TextStyle(fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Get.back(result: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mascota.id != null) {
                            await petController.deletePet(mascota.id!);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _agregarMascota,
                icon:
                    const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text("Agregar Nueva Mascota"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
