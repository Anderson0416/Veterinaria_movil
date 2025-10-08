import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/veterinary_controller.dart';
import 'package:veterinaria_movil/moldes/veterinary_model.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterVeterinaryScreen extends StatelessWidget {
  const RegisterVeterinaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VeterinaryController controller = Get.put(VeterinaryController());
    final FirebaseAuth auth = FirebaseAuth.instance;

    // Controladores de texto
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController direccionController = TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController nitController = TextEditingController();
    final TextEditingController correoController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      appBar: AppBar(
        title: const Text("Registro de Veterinaria"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.local_hospital,
                  color: Colors.green, size: 60),
              const SizedBox(height: 10),
              const Text(
                "Registrar Veterinaria",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildTextField(nombreController, "Nombre de la Veterinaria",
                  icon: Icons.business),
              const SizedBox(height: 15),
              _buildTextField(direccionController, "Dirección",
                  icon: Icons.location_on),
              const SizedBox(height: 15),
              _buildTextField(telefonoController, "Teléfono",
                  icon: Icons.phone),
              const SizedBox(height: 15),
              _buildTextField(nitController, "NIT", icon: Icons.badge),
              const SizedBox(height: 15),
              _buildTextField(correoController, "Correo Electrónico",
                  icon: Icons.email),
              const SizedBox(height: 25),

              // Botón de registrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    "Registrar Veterinaria",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final currentUser = auth.currentUser;

                    if (currentUser == null) {
                      Get.snackbar("Error", "Debes iniciar sesión primero");
                      return;
                    }

                    if (nombreController.text.isEmpty ||
                        direccionController.text.isEmpty ||
                        telefonoController.text.isEmpty ||
                        nitController.text.isEmpty ||
                        correoController.text.isEmpty) {
                      Get.snackbar("Error", "Por favor completa todos los campos");
                      return;
                    }

                    final veterinary = VeterinaryModel(
                      id: currentUser.uid, // Usa el mismo id del usuario Auth
                      nombre: nombreController.text,
                      direccion: direccionController.text,
                      telefono: telefonoController.text,
                      nit: nitController.text,
                      correo: correoController.text,
                    );

                    await controller.addVeterinary(veterinary);

                    // Vuelve al login después del registro
                    Get.offAll(() => const LoginScreens());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget reutilizable para los campos de texto ---
  Widget _buildTextField(TextEditingController controller, String label,
      {required IconData icon}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
