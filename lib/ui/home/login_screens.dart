import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/customer_menu_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/veterinary_menu_screen.dart';
import 'package:veterinaria_movil/ui/select_user_screen.dart';

class LoginScreens extends StatelessWidget {
  const LoginScreens({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController userController = TextEditingController();
    final TextEditingController passController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF7EE),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 30,
                child: Icon(Icons.favorite, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 10),
              const Text(
                "VetCare",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Cuidamos a tus mascotas",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Sugerencia: el label dice "Usuario" pero aquí se espera un correo
              TextField(
                controller: userController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: "Usuario (correo)",
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
                  prefixIcon: const Icon(Icons.lock_outline),
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

                  // --------- LOGIN REAL con FirebaseAuth ----------
                  onPressed: () async {
                    final email = userController.text.trim();
                    final password = passController.text;

                    if (email.isEmpty || password.isEmpty) {
                      Get.snackbar(
                        "Error",
                        "Ingresa usuario y contraseña",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.withOpacity(0.7),
                        colorText: Colors.white,
                      );
                      return;
                    }

                    // muestra un diálogo de carga simple
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );

                    try {
                      // intenta autenticar con Firebase
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // cerrar indicador
                      if (Get.isDialogOpen ?? false) Get.back();

                      // redirección (por ahora seguimos con la regla simple)
                      if (email.toLowerCase().startsWith("vet")) {
                        Get.off(() => const VeterinaryMenuScreen());
                      } else {
                        Get.off(() => const CustomerMenuScreen());
                      }
                    } on FirebaseAuthException catch (e) {
                      if (Get.isDialogOpen ?? false) Get.back();
                      Get.snackbar(
                        "Error de autenticación",
                        e.message ?? "Credenciales inválidas",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.withOpacity(0.8),
                        colorText: Colors.white,
                      );
                    } catch (e) {
                      if (Get.isDialogOpen ?? false) Get.back();
                      Get.snackbar(
                        "Error",
                        e.toString(),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  child: const Text(
                    "Iniciar Sesión",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  // 👇 Mostrar SelectUserScreen como ventana emergente
                  Get.dialog(
                    Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const SelectUserScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Regístrate aquí",
                  style: TextStyle(
                    color: Colors.green,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
