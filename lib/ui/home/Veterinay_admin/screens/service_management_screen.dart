import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/service_controller.dart';
import 'package:veterinaria_movil/moldes/service_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceManagementScreen extends StatelessWidget {
  ServiceManagementScreen({super.key});

  final ServiceController serviceController = Get.put(ServiceController());
  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final precioCtrl = TextEditingController();

  //  Mostrar el formulario de registro / edición
  void _mostrarDialogo({ServiceModel? servicioExistente}) {
   final isEditing = servicioExistente != null;
  if (isEditing) {
    nombreCtrl.text = servicioExistente.nombre;
    descripcionCtrl.text = servicioExistente.descripcion;
    precioCtrl.text = servicioExistente.precio.toString();
  } else {
    nombreCtrl.clear();
    descripcionCtrl.clear();
    precioCtrl.clear();
  }

  showDialog(
    context: Get.context!, // 👈 usamos el contexto global seguro
    barrierDismissible: false,
    builder: (context) {
      bool isSaving = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEditing ? "Editar Servicio" : "Nuevo Servicio"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("Nombre del servicio", nombreCtrl),
                const SizedBox(height: 8),
                _buildField("Descripción", descripcionCtrl),
                const SizedBox(height: 8),
                _buildField("Precio (COP)", precioCtrl, tipo: TextInputType.number),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // 🔹 cierre garantizado
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) return;

                        final service = ServiceModel(
                          id: servicioExistente?.id,
                          nombre: nombreCtrl.text.trim(),
                          descripcion: descripcionCtrl.text.trim(),
                          precio: double.tryParse(precioCtrl.text.trim()) ?? 0,
                          veterinaryId: currentUser.uid,
                        );

                        try {
                          if (isEditing) {
                            await serviceController.updateService(servicioExistente!.id!, service);
                            Get.snackbar("Actualizado", "El servicio se actualizó correctamente ✅");
                          } else {
                            await serviceController.addService(service);
                            Get.snackbar("Guardado", "El servicio se registró correctamente ✅");
                          }

                          // 🔹 Esperamos un breve momento y cerramos el diálogo correctamente
                          await Future.delayed(const Duration(milliseconds: 200));
                          if (context.mounted) Navigator.of(context).pop(); // 👈 cierre garantizado
                        } catch (e) {
                          Get.snackbar("Error", "Ocurrió un problema: $e");
                        } finally {
                          if (context.mounted) setState(() => isSaving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF388E3C)),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? "Actualizar" : "Guardar"),
              ),
            ],
          );
        },
      );
    },
  );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {TextInputType tipo = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF388E3C)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text("Gestión de Servicios"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF388E3C),
        onPressed: () => _mostrarDialogo(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: serviceController.getServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay servicios registrados"));
          }

          final servicios = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servicios.length,
            itemBuilder: (context, i) {
              final s = servicios[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    s.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.descripcion, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        "💰 ${s.precio.toStringAsFixed(0)} COP",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _mostrarDialogo(servicioExistente: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => serviceController.deleteService(s.id!),
                      ),
                    ],
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
