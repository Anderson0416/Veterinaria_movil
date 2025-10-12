import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/pet_card.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/pet_form_dialog.dart';

class MisMascotasScreen extends StatefulWidget {
  const MisMascotasScreen({super.key});

  @override
  State<MisMascotasScreen> createState() => _MisMascotasScreenState();
}

class _MisMascotasScreenState extends State<MisMascotasScreen> {
  List<Map<String, dynamic>> mascotas = [
    {
      "nombre": "Max",
      "raza": "Golden Retriever",
      "edad": "3 años",
      "tipo": "Perro"
    },

  ];

  void _agregarMascota() async {
    await Get.dialog(const PetFormDialog());
  }

  void _eliminarMascota(int index) {
    setState(() => mascotas.removeAt(index));
    Get.snackbar("Eliminado", "La mascota ha sido eliminada ");
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
              child: ListView.builder(
                itemCount: mascotas.length,
                itemBuilder: (context, index) {
                  final mascota = mascotas[index];
                  return PetCard(
                    nombre: mascota["nombre"],
                    raza: mascota["raza"],
                    edad: mascota["edad"],
                    tipo: mascota["tipo"],
                    onEditar: () {
                      Get.dialog(
                        PetFormDialog(
                          mascota: mascota,
                          modoEditar: true,
                        ),
                      );
                    },
                    onEliminar: () => _eliminarMascota(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _agregarMascota,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
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
