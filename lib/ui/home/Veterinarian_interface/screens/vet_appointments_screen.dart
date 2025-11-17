import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/screens/vet_anamnesis_screen.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String selectedFilter = 'Hoy'; // Filtro por defecto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text('Citas Programadas', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Filtros: Hoy, Mañana, Esta Semana
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Hoy',
                  isSelected: selectedFilter == 'Hoy',
                  onTap: () => setState(() => selectedFilter = 'Hoy'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Mañana',
                  isSelected: selectedFilter == 'Mañana',
                  onTap: () => setState(() => selectedFilter = 'Mañana'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Esta Semana',
                  isSelected: selectedFilter == 'Esta Semana',
                  onTap: () => setState(() => selectedFilter = 'Esta Semana'),
                ),
              ],
            ),
          ),
          
          // Lista de citas filtradas
          Expanded(
            child: _AppointmentsList(
              veterinarioId: _auth.currentUser?.uid ?? '',
              filter: selectedFilter,
            ),
          ),
        ],
      ),
    );
  }
}

// Chip de filtro personalizado
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Lista de citas con filtros
class _AppointmentsList extends StatelessWidget {
  final String veterinarioId;
  final String filter;

  const _AppointmentsList({
    required this.veterinarioId,
    required this.filter,
  });

  // Extraer fecha de cualquier formato
  DateTime? _extractDate(dynamic fechaData) {
    if (fechaData == null) return null;
    
    if (fechaData is Timestamp) {
      return fechaData.toDate();
    } else if (fechaData is String) {
      try {
        return DateTime.parse(fechaData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Verificar si la fecha está en el rango del filtro
  bool _isDateInRange(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (filter == 'Hoy') {
      final tomorrow = today.add(const Duration(days: 1));
      return fecha.isAfter(today.subtract(const Duration(seconds: 1))) &&
             fecha.isBefore(tomorrow);
    } else if (filter == 'Mañana') {
      final tomorrow = today.add(const Duration(days: 1));
      final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
      return fecha.isAfter(tomorrow.subtract(const Duration(seconds: 1))) &&
             fecha.isBefore(dayAfterTomorrow);
    } else {
      // Esta Semana (próximos 7 días desde hoy)
      final endOfWeek = today.add(const Duration(days: 7));
      return fecha.isAfter(today.subtract(const Duration(seconds: 1))) &&
             fecha.isBefore(endOfWeek.add(const Duration(days: 1)));
    }
  }

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
            child: CircularProgressIndicator(color: Color(0xFF388E3C)),
          );
        }

        if (!snapshot.hasData) {
          return _emptyState();
        }

        // Filtrar citas según el filtro seleccionado EN MEMORIA
        final filteredAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fecha = _extractDate(data['fecha']);
          
          if (fecha == null) return false;
          return _isDateInRange(fecha);
        }).toList();

        if (filteredAppointments.isEmpty) {
          return _emptyState();
        }

        // Ordenar por hora
        filteredAppointments.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final horaA = dataA['hora'] ?? '';
          final horaB = dataB['hora'] ?? '';
          return horaA.compareTo(horaB);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final doc = filteredAppointments[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return _AppointmentCard(
              appointmentId: doc.id,
              mascotaId: data['mascotaId'] ?? '',
              mascotaNombre: data['mascotaNombre'] ?? 'Sin nombre',
              clienteNombre: data['clienteNombre'] ?? 'Cliente desconocido',
              tipoServicio: data['tipoServicio'] ?? 'Consulta general',
              hora: data['hora'] ?? 'Sin hora',
              estado: data['estado'] ?? 'pendiente',
              duenoId: data['duenoId'] ?? '',
              veterinariaId: data['veterinariaId'] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay citas programadas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para $filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta de cita individual
class _AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final String mascotaId;
  final String mascotaNombre;
  final String clienteNombre;
  final String tipoServicio;
  final String hora;
  final String estado;
  final String duenoId;
  final String veterinariaId;

  const _AppointmentCard({
    required this.appointmentId,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.clienteNombre,
    required this.tipoServicio,
    required this.hora,
    required this.estado,
    required this.duenoId,
    required this.veterinariaId,
  });

  Color _getStatusColor() {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return const Color(0xFF4CAF50);
      case 'pendiente':
        return const Color(0xFFFFA726);
      case 'atendida':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return 'Confirmada';
      case 'pendiente':
        return 'Pendiente';
      case 'atendida':
        return 'Atendida';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombre y hora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Color(0xFF388E3C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mascotaNombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          clienteNombre,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Tipo de servicio
            Text(
              tipoServicio,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            
            // Estado y botón
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Botón Iniciar Consulta - ✅ CORREGIDO
// Botón Iniciar Consulta - SOLO SI NO HA SIDO ATENDIDA
if (estado.toLowerCase() != 'atendida')
  ElevatedButton(
    onPressed: () async {
      // Obtener el veterinaryId correcto del veterinario logueado
      final vetDoc = await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      
      final veterinaryId = vetDoc.data()?['veterinaryId'] ?? veterinariaId;
      
      // Navegar a la pantalla de Anamnesis con el ID correcto
      Get.to(() => VetAnamnesisScreen(
        appointmentId: appointmentId,
        mascotaId: mascotaId,
        mascotaNombre: mascotaNombre,
        duenoId: duenoId,
        veterinariaId: veterinaryId,
      ));
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF388E3C),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    child: const Text(
      'Iniciar Consulta',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}