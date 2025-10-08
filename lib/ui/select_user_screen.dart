import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/ui/home/register_user_screen.dart';

class SelectUserScreen extends StatelessWidget {
  const SelectUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 👈 hace que se vea como modal
        children: [
          const Text(
            "Registrarse como",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Get.back(); // cerrar modal
              Get.to(() => const RegisterUserScreen(),
                  arguments: {'type': 'cliente'});
            },
            child: const Text("Cliente"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Get.back(); // cerrar modal
              Get.to(() => const RegisterUserScreen(),
                  arguments: {'type': 'veterinaria'});
            },
            child: const Text("Veterinaria"),
          ),
        ],
      ),
    );
  }
}
