import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/add_user_controllers.dart';
import 'package:veterinaria_movil/ui/home/register_customer_screen.dart';
import 'package:veterinaria_movil/ui/home/register_veterinary_screen.dart';


class RegisterUserScreen extends StatelessWidget {
  const RegisterUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AddUserControllers controller = Get.find();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passController = TextEditingController();

    // 👇 Recuperamos el tipo desde SelectUserScreen
    final args = Get.arguments ?? {};
    final roleType = args['type'] ?? 'cliente';

    return Scaffold(
      appBar: AppBar(
        title: Text("Registro ($roleType)"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Registro de $roleType",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email, color: Colors.green),
                  labelText: "Correo electrónico",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                  labelText: "Contraseña",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      Get.snackbar("Error", "Completa todos los campos");
                      return;
                    }

                    // Registrar usuario en Firebase
                    final userCreated = await controller.registerUser(
                      email,
                      password,
                      roleType,
                    );

                    // Si el registro fue exitoso, redirigimos
                    if (userCreated) {
                      if (roleType == 'cliente') {
                        Get.off(() => const RegisterCustomerScreen());
                      } else if (roleType == 'veterinaria') {
                        Get.off(() => const RegisterVeterinaryScreen());
                      }
                    }
                  },
                  child: const Text("Registrar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
