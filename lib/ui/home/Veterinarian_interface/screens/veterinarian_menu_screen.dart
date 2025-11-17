import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/widgets/veterinarian_profile_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/screens/vet_appointments_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/screens/vet_clinical_history_screen.dart';
import '../../../../../controllers/veterinarian_controller.dart';
import '../../../../../moldes/veterinarian_models.dart';

class VeterinarianMenuScreen extends StatefulWidget {
  const VeterinarianMenuScreen({super.key});

  @override
  State<VeterinarianMenuScreen> createState() => _VeterinarianMenuScreenState();
}

class _VeterinarianMenuScreenState extends State<VeterinarianMenuScreen> {
  final VeterinarianController vetController = Get.find<VeterinarianController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  VeterinarianModel? veterinarian;

  @override
  void initState() {
    super.initState();
    _loadVetData();
  }

  Future<void> _loadVetData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final vet = await vetController.getVeterinarianById(user.uid);
    setState(() => veterinarian = vet);
  }

  @override
  Widget build(BuildContext context) {
    final vet = veterinarian;
    final initials = vet != null && vet.nombre.isNotEmpty
        ? vet.nombre[0].toUpperCase() +
            (vet.apellido.isNotEmpty ? vet.apellido[0].toUpperCase() : "")
        : "V";

    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      body: Column(
        children: [
          // HEADER con curva inferior y estilo verde oscuro
          Container(
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF388E3C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vet != null ? "Dr. ${vet.apellido}" : "Cargando...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Panel Veterinario",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    if (vet != null) {
                      Get.to(() => VeterinarianProfileScreen(vet: vet));
                    } else {
                      Get.snackbar("Error", "No se pudo cargar el perfil");
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TodayAppointmentsStatCard(
                          veterinarioId: _auth.currentUser?.uid ?? '',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AttendedAppointmentsStatCard(
                          veterinarioId: _auth.currentUser?.uid ?? '',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PendingAppointmentsStatCard(
                          veterinarioId: _auth.currentUser?.uid ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _MainOptionCard(
                    icon: Icons.schedule_outlined,
                    title: "Citas Programadas",
                    subtitle: "Ver agenda y gestionar citas",
                    onTap: () => Get.to(() => const VetAppointmentsScreen()),
                  ),
                  _MainOptionCard(
                    icon: Icons.pets_outlined,
                    title: "Historial Clínico",
                    subtitle: "Buscar y revisar historiales de mascotas",
                     onTap: () => Get.to(() => const VetClinicalHistoryScreen()),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Próximas Citas Hoy",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TodayAppointmentsList(
                    veterinarioId: _auth.currentUser?.uid ?? '',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 📊 Tarjeta de Citas HOY - FUNCIONAL
class _TodayAppointmentsStatCard extends StatelessWidget {
  final String veterinarioId;

  const _TodayAppointmentsStatCard({required this.veterinarioId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('appointments')
          .where('veterinarioId', isEqualTo: veterinarioId)
          .snapshots(),
      builder: (context, snapshot) {
        int todayCount = 0;
        
        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['fecha'] != null) {
              final fechaTimestamp = data['fecha'] as Timestamp;
              final fechaCita = fechaTimestamp.toDate();
              
              if (fechaCita.isAfter(today.subtract(const Duration(seconds: 1))) &&
                  fechaCita.isBefore(tomorrow)) {
                todayCount++;
              }
            }
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFF388E3C), size: 26),
                const SizedBox(height: 6),
                Text(
                  todayCount.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                const Text(
                  "Citas Hoy",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ✅ Tarjeta de Citas ATENDIDAS - FUNCIONAL
class _AttendedAppointmentsStatCard extends StatelessWidget {
  final String veterinarioId;

  const _AttendedAppointmentsStatCard({required this.veterinarioId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('appointments')
          .where('veterinarioId', isEqualTo: veterinarioId)
          .where('estado', isEqualTo: 'atendida')
          .snapshots(),
      builder: (context, snapshot) {
        int attendedCount = 0;
        
        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['fecha'] != null) {
              final fechaTimestamp = data['fecha'] as Timestamp;
              final fechaCita = fechaTimestamp.toDate();
              
              if (fechaCita.isAfter(today.subtract(const Duration(seconds: 1))) &&
                  fechaCita.isBefore(tomorrow)) {
                attendedCount++;
              }
            }
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF388E3C), size: 26),
                const SizedBox(height: 6),
                Text(
                  attendedCount.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                const Text(
                  "Atendidas",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ⏳ Tarjeta de citas pendientes dinámicas
class _PendingAppointmentsStatCard extends StatelessWidget {
  final String veterinarioId;

  const _PendingAppointmentsStatCard({required this.veterinarioId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('appointments')
          .where('veterinarioId', isEqualTo: veterinarioId)
          .where('estado', isEqualTo: 'pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        int pendingCount = 0;
        
        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['fecha'] != null) {
              final fechaTimestamp = data['fecha'] as Timestamp;
              final fechaCita = fechaTimestamp.toDate();
              
              if (fechaCita.isAfter(today.subtract(const Duration(seconds: 1))) &&
                  fechaCita.isBefore(tomorrow)) {
                pendingCount++;
              }
            }
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Icon(Icons.pending_actions_outlined, color: Color(0xFF388E3C), size: 26),
                const SizedBox(height: 6),
                Text(
                  pendingCount.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                const Text(
                  "Pendientes",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 📋 Lista de citas de HOY - FUNCIONAL
class _TodayAppointmentsList extends StatelessWidget {
  final String veterinarioId;

  const _TodayAppointmentsList({required this.veterinarioId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('appointments')
          .where('veterinarioId', isEqualTo: veterinarioId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return _emptyState();
        }

        // Filtrar citas de hoy en memoria
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        final todayAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['fecha'] == null) return false;
          
          final fechaTimestamp = data['fecha'] as Timestamp;
          final fechaCita = fechaTimestamp.toDate();
          
          return fechaCita.isAfter(today.subtract(const Duration(seconds: 1))) &&
                 fechaCita.isBefore(tomorrow);
        }).toList();

        if (todayAppointments.isEmpty) {
          return _emptyState();
        }

        // Ordenar por hora
        todayAppointments.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final horaA = dataA['hora'] ?? '';
          final horaB = dataB['hora'] ?? '';
          return horaA.compareTo(horaB);
        });

        return Column(
          children: todayAppointments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _AppointmentCard(
              time: "${data['hora'] ?? 'Sin hora'} - ${data['mascotaNombre'] ?? 'Sin nombre'}",
              service: data['tipoServicio'] ?? 'Consulta general',
              status: _getStatusText(data['estado'] ?? 'pendiente'),
              client: data['clienteNombre'] ?? 'Cliente desconocido',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              "No tienes citas programadas para hoy",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "¡Disfruta tu día libre! 🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return 'Confirmada';
      case 'atendida':
        return 'Atendida';
      case 'pendiente':
        return 'Pendiente';
      default:
        return 'Pendiente';
    }
  }
}

class _MainOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MainOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF388E3C).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF388E3C)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.black38, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String time;
  final String service;
  final String client;
  final String status;

  const _AppointmentCard({
    required this.time,
    required this.service,
    required this.client,
    required this.status,
  });

  Color getStatusColor() {
    switch (status) {
      case "Confirmada":
        return Colors.green.shade600;
      case "Atendida":
        return Colors.blue.shade600;
      case "Pendiente":
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "$service\n$client",
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}