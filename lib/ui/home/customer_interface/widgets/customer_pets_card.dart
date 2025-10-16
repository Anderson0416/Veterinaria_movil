import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerPetsCard extends StatelessWidget {
  const CustomerPetsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final petController = Get.find<PetController>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🐾 Mis Mascotas",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: StreamBuilder<List<PetModel>>(
                stream: petController.getPetsStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }
                  final mascotas = snapshot.data ?? [];
                  if (mascotas.isEmpty) {
                    return Center(child: Text('No hay mascotas', style: TextStyle(color: Colors.black54)));
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mascotas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _buildMascotaFromModel(mascotas[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotaFromModel(PetModel m) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.pets, color: Colors.green),
        ),
        const SizedBox(height: 6),
        Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(m.tipo, style: const TextStyle(color: Colors.green)),
      ],
    );
  }
}
