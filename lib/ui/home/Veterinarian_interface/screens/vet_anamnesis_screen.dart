import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VetAnamnesisScreen extends StatelessWidget {
  const VetAnamnesisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text('Realizar Anamnesis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_ind_outlined,
                size: 80,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                'Realizar Anamnesis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aquí puedes crear una nueva consulta médica y realizar la anamnesis',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
