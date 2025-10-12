import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/veterinary_data_screen.dart';
import 'package:veterinaria_movil/ui/home/login_screens.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/staff_register_screen.dart';

// Widgets importados (desde la carpeta widgets)
import '../widgets/admin_action_card.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/veterinary_info_popup.dart';

class VeterinaryMenuScreen extends StatelessWidget {
  const VeterinaryMenuScreen({super.key});

  // Cerrar sesión
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const LoginScreens()); // Asegúrate de tener definida esta ruta en tu app
  }

  // Mostrar información de la veterinaria en popup
  Future<void> _showVeterinaryInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No hay sesión iniciada");
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('veterinarias')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        Get.snackbar("Sin datos", "No se encontró información de esta veterinaria");
        return;
      }

      Get.dialog(VeterinaryInfoPopup(
        data: doc.data()!,
        onLogout: _logout,
      ));
    } catch (e) {
      Get.snackbar("Error", "Ocurrió un problema: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Panel de Veterinaria"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: _showVeterinaryInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👇 Sección de estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
                  child: AdminStatCard(
                    title: "Personal",
                    value: "12",
                    icon: Icons.people,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AdminStatCard(
                    title: "Citas Mes",
                    value: "85",
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 👇 Sección de acciones principales
            const Text(
              "Gestión Administrativa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            AdminActionCard(
              icon: Icons.apartment,
              title: "Datos Veterinaria",
              subtitle: "Gestionar información de la clínica",
              onTap: () => Get.to( () => const VeterinaryDataScreen()),
            ),
            AdminActionCard(
              icon: Icons.people_alt_outlined,
              title: "Registro de Veterinarios",
              subtitle: "Gestionar datos del personal veterinario",
              onTap: () => Get.to( () => const StaffRegisterScreen()),
            ),
            AdminActionCard(
              icon: Icons.bar_chart_outlined,
              title: "Generar Reportes",
              subtitle: "Estadísticas y análisis de rendimiento",
              onTap: () => Get.snackbar("Reportes", "Función pendiente"),
            ),

            const SizedBox(height: 20),

            // 👇 Actividad reciente
            const Text(
              "Actividad Reciente",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            const RecentActivityCard(
              title: "Cita completada - Luna 🐶",
              subtitle: "Atendida por Dr. Martínez",
              date: "09/10/2025",
            ),
            const RecentActivityCard(
              title: "Nuevo registro de cliente",
              subtitle: "Usuario: Ana Torres",
              date: "08/10/2025",
            ),
          ],
        ),
      ),
    );
  }
}
