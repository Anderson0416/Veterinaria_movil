import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/widgets/veterinarian_profile_screen.dart';
import '../../../controllers/veterinarian_controller.dart';
import '../../../moldes/veterinarian_models.dart';


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
          // 🟢 HEADER con curva inferior y estilo verde oscuro
          Container(
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF388E3C), // Verde oscuro institucional
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 👨‍⚕️ Información del veterinario
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

                // 🔘 Avatar con acceso al perfil
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

          // 📋 CUERPO PRINCIPAL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Sección de estadísticas
                  Row(
                    children: const [
                      Expanded(
                        child: _StatCard(
                          title: "Citas Hoy",
                          value: "8",
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: "Atendidas",
                          value: "3",
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: "Pendientes",
                          value: "5",
                          icon: Icons.pending_actions_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Sección de acciones
                  const _MainOptionCard(
                    icon: Icons.schedule_outlined,
                    title: "Citas Programadas",
                    subtitle: "Ver agenda y gestionar citas",
                  ),
                  const _MainOptionCard(
                    icon: Icons.pets_outlined,
                    title: "Historial Clínico",
                    subtitle: "Buscar y revisar historiales de mascotas",
                  ),
                  const _MainOptionCard(
                    icon: Icons.assignment_ind_outlined,
                    title: "Realizar Anamnesis",
                    subtitle: "Crear nueva consulta médica",
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Próximas citas
                  const Text(
                    "Próximas Citas Hoy",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _AppointmentCard(
                    time: "10:00 - Max",
                    service: "Consulta general",
                    status: "Confirmada",
                    client: "María González",
                  ),
                  const _AppointmentCard(
                    time: "11:30 - Rocky",
                    service: "Control dental",
                    status: "En curso",
                    client: "Ana Martín",
                  ),
                  const _AppointmentCard(
                    time: "15:00 - Bella",
                    service: "Consulta general",
                    status: "Confirmada",
                    client: "Luis Herrera",
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

// 🟩 Tarjeta de estadísticas pequeñas
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF388E3C), size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// 🟩 Tarjetas principales de acción
class _MainOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MainOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        onTap: () => Get.snackbar(title, "Función en desarrollo"),
      ),
    );
  }
}

// 🟩 Tarjetas de próximas citas
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
      case "En curso":
        return Colors.orange.shade600;
      case "Confirmada":
        return Colors.green.shade600;
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
