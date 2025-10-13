import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/veterinarian_controller.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/moldes/veterinarian_models.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';

class VeterinarianMenuScreen extends StatelessWidget {
  const VeterinarianMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VeterinarianController vetController = Get.find<VeterinarianController>();
    final VeterinaryController veterinaryController = Get.find<VeterinaryController>();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<void> mostrarDatos() async {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'No hay sesión activa');
        return;
      }

      // Obtener veterinario por ID (UID del usuario autenticado)
      final VeterinarianModel? veterinarian = await vetController.getVeterinarianById(user.uid);

      if (veterinarian == null) {
        Get.snackbar('Error', 'No se encontró la información del veterinario');
        return;
      }

      // Buscar veterinaria asociada
      VeterinaryModel? veterinary;
      if (veterinarian.veterinaryId != null && veterinarian.veterinaryId!.isNotEmpty) {
        veterinary = await veterinaryController.getVeterinaryById(veterinarian.veterinaryId!);
      }

      // Mostrar datos en un AlertDialog
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Datos del Veterinario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👨‍⚕️ Nombre: ${veterinarian.nombre}'),
              const SizedBox(height: 6),
              Text('📞 Teléfono: ${veterinarian.telefono}'),
              const SizedBox(height: 6),
              Text('🏥 Veterinaria: ${veterinary?.nombre}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú del Veterinario'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: mostrarDatos,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.info_outline, color: Colors.white),
          label: const Text(
            'Mostrar mis datos',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
