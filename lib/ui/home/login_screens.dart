import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/screens/customer_menu_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/veterinary_menu_screen.dart';
import 'package:veterinaria_movil/ui/home/veterinarian_menu_screen.dart';
import 'package:veterinaria_movil/ui/select_user_screen.dart';

// 🔹 Importa tu nueva pantalla de administración
import 'package:veterinaria_movil/ui/home/admin_menu_screen.dart';

class LoginScreens extends StatelessWidget {
  const LoginScreens({super.key});

  Future<void> _login(String email, String password) async {
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

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception("Usuario no encontrado");

      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot? userDoc;
      String role = '';

      // 🔹 Buscar en veterinarias
      userDoc = await firestore.collection('veterinarias').doc(user.uid).get();
      if (userDoc.exists) {
        role = 'veterinaria';

        // Nueva validación: si la veterinaria no está activa, bloquear acceso
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('activo') && data['activo'] == false) {
          if (Get.isDialogOpen ?? false) Get.back();
          Get.snackbar(
            "Cuenta inactiva",
            "Tu cuenta está desactivada. Comunícate con VetCare para activarla.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
          );
          await FirebaseAuth.instance.signOut();
          return;
        }
      } else {
        // 🔹 Buscar en veterinarios
        userDoc = await firestore.collection('veterinarians').doc(user.uid).get();
        if (userDoc.exists) {
          role = 'veterinario';
        } else {
          // 🔹 Buscar en clientes
          userDoc = await firestore.collection('customers').doc(user.uid).get();
          if (userDoc.exists) {
            role = 'cliente';
          } else {
            // 🔹 Buscar en users (tabla donde está el admin)
            final userQuery = await firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

            if (userQuery.docs.isNotEmpty) {
              final data = userQuery.docs.first.data();
              role = data['role'] ?? '';
            }
          }
        }
      }

      if (Get.isDialogOpen ?? false) Get.back();

      if (role.isEmpty) {
        Get.snackbar(
          "Error",
          "No se encontró el perfil del usuario en la base de datos",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // 🔹 Redirección según el rol encontrado
      switch (role.toLowerCase()) {
        case 'veterinaria':
          Get.off(() => const VeterinaryMenuScreen());
          break;
        case 'veterinario':
          Get.off(() => const VeterinarianMenuScreen());
          break;
        case 'cliente':
          Get.off(() => const CustomerMenuScreen());
          break;
        case 'admin': // ✅ Nuevo caso agregado
          Get.off(() => AdminMenuScreen());
          break;
        default:
          Get.snackbar(
            "Error",
            "Rol no válido o desconocido: $role",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
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
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

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
              TextField(
                controller: userController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
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
                maxLength: 15,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  await _login(
                    userController.text.trim(),
                    passController.text,
                  );
                },
                decoration: InputDecoration(
                  counterText: "",
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
                  onPressed: () async {
                    await _login(
                      userController.text.trim(),
                      passController.text,
                    );
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
