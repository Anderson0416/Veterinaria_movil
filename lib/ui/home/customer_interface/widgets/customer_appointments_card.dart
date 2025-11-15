// ui/customer/widgets/customer_appointments_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/controllers/appointment_controllers.dart';
import 'package:veterinaria_movil/moldes/appointment_model.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/appointment_dialog.dart';



class CustomerAppointmentsCard extends StatefulWidget {
  const CustomerAppointmentsCard({super.key});

  @override
  State<CustomerAppointmentsCard> createState() => _CustomerAppointmentsCardState();
}

class _CustomerAppointmentsCardState extends State<CustomerAppointmentsCard> {
  final AppointmentController appointmentController = Get.put(AppointmentController());
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " Próximas Citas",
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<CitaModel>>(
              stream: appointmentController.getCitasPorDueno(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                final citas = snapshot.data ?? [];

                if (citas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No tienes citas registradas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: citas
                      .map((cita) => _buildCitaItem(context, cita))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  //  Construye cada cita individual dentro de la tarjeta
 
  Widget _buildCitaItem(BuildContext context, CitaModel cita) {
    return FutureBuilder<Map<String, String>>(
      future: _obtenerDatosCita(cita),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        final datos = snapshot.data!;

        return GestureDetector(
          onTap: () {
            AppointmentDialog.showDetails(
              context: context,
              cita: cita,
              datos: datos,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Izquierda: Mascota + Servicio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      datos['mascota']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      datos['servicio']!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),

                // Derecha: Fecha + Hora
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      datos['fecha']!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      datos['hora']!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //  Obtener nombres de mascota, servicio, fecha formateada
  
  Future<Map<String, String>> _obtenerDatosCita(CitaModel cita) async {
    // Mascota
    final petDoc = await _db.collection('pets').doc(cita.mascotaId).get();
    final mascotaNombre = petDoc.data()?['nombre'] ?? 'Mascota desconocida';

    // Servicio
    final serviceDoc =
        await _db.collection('types_services').doc(cita.servicioId).get();
    final servicioNombre = serviceDoc.data()?['nombre'] ?? 'Servicio desconocido';

    // Fecha
    final fechaFormateada =
        '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}';

    return {
      'mascota': mascotaNombre.toString(),
      'servicio': servicioNombre.toString(),
      'fecha': fechaFormateada,
      'hora': cita.hora,
    };
  }
}
