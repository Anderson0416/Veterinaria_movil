import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VetAppointmentsScreen extends StatelessWidget {
  const VetAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text('Citas Programadas'),
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
                Icons.schedule_outlined,
                size: 80,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                'Citas Programadas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aquí se mostrarán las citas programadas del veterinario',
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
