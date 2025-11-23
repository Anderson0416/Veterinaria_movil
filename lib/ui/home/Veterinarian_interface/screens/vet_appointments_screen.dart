import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:veterinaria_movil/moldes/appointment_model.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/screens/factura_screen.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/screens/vet_anamnesis_screen.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String selectedFilter = 'Hoy';

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

class _AppointmentsList extends StatelessWidget {
  final String veterinarioId;
  final String filter;

  const _AppointmentsList({
    required this.veterinarioId,
    required this.filter,
  });

  DateTime? _extractDate(dynamic fechaData) {
    if (fechaData == null) return null;
    if (fechaData is Timestamp) return fechaData.toDate();
    if (fechaData is String) {
      try {
        return DateTime.parse(fechaData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool _isDateInRange(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (filter == 'Hoy') {
      return fecha.isAfter(today.subtract(const Duration(seconds: 1))) &&
             fecha.isBefore(today.add(const Duration(days: 1)));
    } else if (filter == 'Mañana') {
      final tomorrow = today.add(const Duration(days: 1));
      return fecha.isAfter(tomorrow.subtract(const Duration(seconds: 1))) &&
             fecha.isBefore(tomorrow.add(const Duration(days: 1)));
    } else {
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

        if (!snapshot.hasData) return _emptyState();

        final filteredAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fecha = _extractDate(data['fecha']);
          if (fecha == null) return false;
          return _isDateInRange(fecha);
        }).toList();

        if (filteredAppointments.isEmpty) return _emptyState();

        filteredAppointments.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          return (dataA['hora'] ?? '').compareTo(dataB['hora'] ?? '');
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
              pagado: data['pagado'] ?? false,
              direccion: data['direccion'] ?? '',
              latitud: (data['latitud'] as num?)?.toDouble() ?? 0.0,
              longitud: (data['longitud'] as num?)?.toDouble() ?? 0.0,
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
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay citas programadas',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('para $filter', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

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
  final bool pagado;
  final String direccion;
  final double latitud;
  final double longitud;

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
    required this.pagado,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });

  Color _getStatusColor() {
    switch (estado.toLowerCase()) {
      case 'confirmada': return const Color(0xFF4CAF50);
      case 'pendiente': return const Color(0xFFFFA726);
      case 'atendida': return const Color(0xFF2196F3);
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (estado.toLowerCase()) {
      case 'confirmada': return 'Confirmada';
      case 'pendiente': return 'Pendiente';
      case 'atendida': return 'Atendida';
      case 'cancelada': return 'Cancelada';
      default: return 'Desconocido';
    }
  }

  void abrirMapa() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$latitud,$longitud";

    final Uri uri = Uri.parse(googleMapsUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw "No se pudo abrir Google Maps";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final servicioId = data['servicioId'] ?? "";
        final precioServicio = data['precioServicio'] ?? 0;
        final String modalidad = data['modalidad'] ?? "Presencial";
        final bool esDomicilio = modalidad == "Domicilio";

        final bool isCancelada = estado.toLowerCase() == "cancelada";

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
                          child: const Icon(Icons.pets,
                              color: Color(0xFF388E3C), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mascotaNombre,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text(clienteNombre,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                    Text(hora,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 12),
                Text(tipoServicio,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black54)),

                const SizedBox(height: 12),
                Text(
                  modalidad == "Domicilio" ? "Servicio a domicilio" : "Servicio presencial",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: modalidad == "Domicilio" ? Colors.blue : Colors.green,
                  ),
                ),
                if (esDomicilio && !isCancelada)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton.icon(
                      onPressed: abrirMapa,
                      icon: const Icon(Icons.location_on),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        foregroundColor: Colors.white,
                      ),
                      label: const Text("Ver ubicación en Google Maps"),
                    ),
                  ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: pagado
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pagado ? "Pagado" : "No Pagado",
                            style: TextStyle(
                              color: pagado ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isCancelada && estado.toLowerCase() != 'atendida')
                      ElevatedButton(
                        onPressed: () async {
                          if (!pagado) {
                            final cita = CitaModel(
                              id: appointmentId,
                              mascotaId: mascotaId,
                              duenoId: duenoId,
                              veterinariaId: veterinariaId,
                              veterinarioId: '',
                              servicioId: servicioId,
                              precioServicio: precioServicio,
                              fecha: DateTime.now(),
                              hora: hora,
                              direccion: direccion,
                              latitud: latitud,
                              longitud: longitud,
                              estado: 'pendiente',
                              pagado: false,
                              observaciones: '',
                              modalidad: modalidad,
                            );

                            Get.to(() => FacturaScreen(cita: cita));
                            return;
                          }
                          final vetDoc =
                              await FirebaseFirestore.instance.collection('veterinarians').doc(FirebaseAuth.instance.currentUser?.uid).get();
                          final veterinaryId = vetDoc.data()?['veterinaryId'] ?? veterinariaId;
                          Get.to(() => VetAnamnesisScreen(
                                appointmentId: appointmentId,
                                mascotaId: mascotaId,
                                mascotaNombre: mascotaNombre,
                                duenoId: duenoId,
                                veterinariaId: veterinaryId,
                              ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pagado ? const Color(0xFF388E3C) : Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          pagado ? 'Iniciar Consulta' : 'Pagar Consulta',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
