import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/veterinarian_controller.dart';
import 'package:veterinaria_movil/moldes/veterinarian_models.dart';
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
    final vetController = Get.find<VeterinarianController>();
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Registro de Personal"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection("veterinarians")
              .where('veterinaryId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
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
                    Text("No hay veterinarios registrados aún.",
                        style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 30),
                    StaffForm(),
                  ],
                ),
              );
            }

            final veterinarios = snapshot.data!.docs;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  ...veterinarios.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    return StaffCard(
                      nombre: "${data['nombre']} ${data['apellido'] ?? ''}",
                      rol: data['especialidad'] ?? 'Sin especialidad',
                      email: data['email'] ?? '',
                      telefono: data['telefono'] ?? '',
                      activo: true,
                      onEditar: () async {
                        // Abrir diálogo de edición
                        final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
                        final apellidoCtrl = TextEditingController(text: data['apellido'] ?? '');
                        final telefonoCtrl = TextEditingController(text: data['telefono'] ?? '');
                        final especialidadCtrl = TextEditingController(text: data['especialidad'] ?? '');
                        final direccionCtrl = TextEditingController(text: data['direccion'] ?? '');

                        await Get.dialog(Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Editar Veterinario', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                                  const SizedBox(height: 8),
                                  TextField(controller: apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido')),
                                  const SizedBox(height: 8),
                                  TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                                  const SizedBox(height: 8),
                                  TextField(controller: especialidadCtrl, decoration: const InputDecoration(labelText: 'Especialidad')),
                                  const SizedBox(height: 8),
                                  TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final updated = {
                                            'nombre': nombreCtrl.text.trim(),
                                            'apellido': apellidoCtrl.text.trim(),
                                            'telefono': telefonoCtrl.text.trim(),
                                            'especialidad': especialidadCtrl.text.trim(),
                                            'direccion': direccionCtrl.text.trim(),
                                          };
                                          // Actualizar sólo campos permitidos
                                          final vetModel = await vetController.getVeterinarianById(id);
                                          if (vetModel != null) {
                                            final updatedModel = VeterinarianModel(
                                              id: vetModel.id,
                                              nombre: updated['nombre'] ?? vetModel.nombre,
                                              apellido: updated['apellido'] ?? vetModel.apellido,
                                              email: vetModel.email,
                                              telefono: updated['telefono'] ?? vetModel.telefono,
                                              fechaNacimiento: vetModel.fechaNacimiento,
                                              tipoDocumento: vetModel.tipoDocumento,
                                              numeroDocumento: vetModel.numeroDocumento,
                                              departamento: vetModel.departamento,
                                              ciudad: vetModel.ciudad,
                                              direccion: updated['direccion'] ?? vetModel.direccion,
                                              especialidad: updated['especialidad'] ?? vetModel.especialidad,
                                              veterinaryId: vetModel.veterinaryId,
                                            );

                                            await vetController.updateVeterinarian(id, updatedModel);
                                          }
                                          Get.back();
                                        },
                                        child: const Text('Guardar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                      },
                      onEliminar: () async {
                        final confirm = await Get.dialog<bool>(AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: Text('¿Eliminar al veterinario ${data['nombre'] ?? ''} ${data['apellido'] ?? ''}?'),
                          actions: [
                            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
                            ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Eliminar')),
                          ],
                        ));
                        if (confirm == true) {
                          await vetController.deleteVeterinarian(id);
                        }
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.dialog(Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: StaffForm(
                  onRegistered: () {
                    // Cerrar diálogo cuando se registre exitosamente
                    if (Get.isDialogOpen ?? false) Get.back();
                    // Mostrar confirmación adicional
                    Get.snackbar('Registro', 'Veterinario registrado correctamente', snackPosition: SnackPosition.BOTTOM);
                  },
                ),
              ),
            ),
          ));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo veterinario'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}