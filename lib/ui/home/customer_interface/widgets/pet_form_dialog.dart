// widget para el formulario de registro y edición de mascotas

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/controllers/animal_type_controller.dart';
import 'package:veterinaria_movil/controllers/breed_controller.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';
import 'package:veterinaria_movil/moldes/breed_model.dart';
import 'package:veterinaria_movil/moldes/animal_type_model.dart';

class PetFormDialog extends StatefulWidget {
  final Map<String, dynamic>? mascota;
  final bool modoEditar;

  const PetFormDialog({super.key, this.mascota, this.modoEditar = false});

  @override
  State<PetFormDialog> createState() => _PetFormDialogState();
}

class _PetFormDialogState extends State<PetFormDialog> {
  final nombreCtrl = TextEditingController();
  final edadCtrl = TextEditingController();

  String? selectedTipoNombre;
  String? selectedRazaId;

  List<AnimalTypeModel> tiposAnimales = [];
  List<BreedModel> razas = [];

  late final AnimalTypeController animalTypeController;
  late final BreedController breedController;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<AnimalTypeController>()) {
      Get.put(AnimalTypeController());
    }
    if (!Get.isRegistered<BreedController>()) {
      Get.put(BreedController());
    }

    animalTypeController = Get.find<AnimalTypeController>();
    breedController = Get.find<BreedController>();

    nombreCtrl.text = widget.mascota?['nombre'] ?? '';
    edadCtrl.text = widget.mascota?['edad'] ?? '';

    // ✅ Cargar tipos y razas si es modo edición
    _loadTipos().then((_) async {
      if (widget.modoEditar) {
        selectedTipoNombre = widget.mascota?['tipo'];
        selectedRazaId = widget.mascota?['raza'];

        // ✅ Buscar el tipo por nombre y cargar sus razas
        final tipoSeleccionado =
            tiposAnimales.firstWhereOrNull((t) => t.nombre == selectedTipoNombre);

        if (tipoSeleccionado != null) {
          await _loadRazas(tipoSeleccionado.id!);
        }

        // ✅ Refrescar interfaz
        setState(() {});
      }
    });
  }

  Future<void> _loadTipos() async {
    tiposAnimales = await animalTypeController.getAnimalTypes();
    setState(() {});
  }

  Future<void> _loadRazas(String tipoId) async {
    razas = await breedController.getBreedsByAnimalType(tipoId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                widget.modoEditar
                    ? "Editar Mascota"
                    : "Registrar Nueva Mascota",
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),

              // ✅ Nombre
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Tipo (ComboBox) - Usa NOMBRE como valor
              DropdownButtonFormField<String>(
                value: selectedTipoNombre,
                decoration: const InputDecoration(
                  labelText: "Tipo de Animal",
                  border: OutlineInputBorder(),
                ),
                items: tiposAnimales
                    .map(
                      (tipo) => DropdownMenuItem<String>(
                        value: tipo.nombre, // ✅ usamos nombre, no ID
                        child: Text(tipo.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    selectedTipoNombre = value;
                    selectedRazaId = null;
                    razas.clear();
                  });

                  // ✅ Buscamos el tipo por nombre para cargar sus razas
                  final tipoSeleccionado =
                      tiposAnimales.firstWhereOrNull((t) => t.nombre == value);
                  if (tipoSeleccionado != null) {
                    await _loadRazas(tipoSeleccionado.id!);
                  }
                },
              ),
              const SizedBox(height: 10),

              // ✅ Raza (ComboBox filtrado)
              DropdownButtonFormField<String>(
                value: selectedRazaId,
                decoration: const InputDecoration(
                  labelText: "Raza",
                  border: OutlineInputBorder(),
                ),
                items: razas
                    .map(
                      (raza) => DropdownMenuItem<String>(
                        value: raza.nombre,
                        child: Text(raza.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedRazaId = value);
                },
              ),
              const SizedBox(height: 10),

              // ✅ Edad
              TextField(
                controller: edadCtrl,
                decoration: const InputDecoration(
                  labelText: "Edad (ej. 2 años)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Botones
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

                          if (widget.modoEditar &&
                              widget.mascota?['id'] != null) {
                            final id = widget.mascota!['id'] as String;
                            final updatedPet = PetModel(
                              id: id,
                              nombre: nombreCtrl.text.trim(),
                              raza: selectedRazaId ?? '',
                              edad: edadCtrl.text.trim(),
                              tipo: selectedTipoNombre ?? '', // ✅ guarda nombre
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
                              raza: selectedRazaId ?? '',
                              edad: edadCtrl.text.trim(),
                              tipo: selectedTipoNombre ?? '', // ✅ guarda nombre
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
                      child: Text(widget.modoEditar
                          ? "Guardar Cambios"
                          : "Registrar"),
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
