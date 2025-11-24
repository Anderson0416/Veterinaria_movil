import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/admin_facturas_all_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/reports_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinay_admin/screens/service_management_screen.dart';
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
    Get.offAll(() => const LoginScreens());
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('veterinarias')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String veterinaryName = "VetCare";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              veterinaryName = data['nombre'] ?? 'VetCare';
            }

            return AppBar(
              backgroundColor: const Color(0xFF388E3C),
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "¡Bienvenido a $veterinaryName!",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Bienvenido a VetCare",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "¡Gestione su veterinaria desde aquí!",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showVeterinaryInfo,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Sección de estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tarjeta dinámica que muestra la cantidad de veterinarios registrados
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('veterinarians')
                        .where('veterinaryId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String value = '0';
                      if (snapshot.hasError) {
                        value = '-';
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        value = '...';
                      } else {
                        value = (snapshot.data?.size ?? 0).toString();
                      }

                      return AdminStatCard(
                        title: 'veterinarios',
                        value: value,
                        icon: Icons.people,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Tarjeta dinámica que muestra citas del mes actual
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('veterinariaId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String value = '0';
                      if (snapshot.hasError) {
                        value = '-';
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        value = '...';
                      } else {
                        // Filtrar citas del mes actual
                        final now = DateTime.now();
                        int citasDelMes = 0;
                        for (final doc in snapshot.data?.docs ?? []) {
                          final data = doc.data() as Map<String, dynamic>;
                          DateTime fecha;
                          final rawFecha = data['fecha'];
                          if (rawFecha is Timestamp) {
                            fecha = rawFecha.toDate();
                          } else if (rawFecha is String) {
                            fecha = DateTime.tryParse(rawFecha) ?? now;
                          } else {
                            fecha = now;
                          }

                          if (fecha.month == now.month && fecha.year == now.year) {
                            citasDelMes++;
                          }
                        }
                        value = citasDelMes.toString();
                      }

                      return AdminStatCard(
                        title: "Citas Mes",
                        value: value,
                        icon: Icons.calendar_today,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            //  Sección de acciones principales
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
              icon: Icons.miscellaneous_services,
              title: "Gestión de Servicios",
              subtitle: "Agrega, edita o elimina servicios ofrecidos",
              onTap: () => Get.to(() => ServiceManagementScreen()),
            ),
            
            AdminActionCard(
              icon: Icons.receipt_long,
              title: "Gestión de facturas",
              subtitle: "revisa las facturas emitidas",
              onTap: () => Get.to(() => AdminFacturasAllScreen()),
            ),

            AdminActionCard(
              icon: Icons.bar_chart_outlined,
              title: "Generar Reportes",
              subtitle: "Estadísticas y análisis de rendimiento",
              onTap: () => Get.to(() => const ReportsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
