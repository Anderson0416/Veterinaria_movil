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

                List<CitaModel> citas = snapshot.data ?? [];
                final ahora = DateTime.now();

                // ⛔ NO mostrar citas canceladas
                citas = citas.where((cita) => cita.estado != "Cancelada").toList();

                // Filtrar citas pasadas
                citas = citas.where((cita) {
                  if (cita.estado == "atendida" || cita.estado == "finalizada") return false;

                  final partes = cita.hora.split(" ");
                  final horaMin = partes[0].split(":");
                  int hour = int.parse(horaMin[0]);
                  int minute = int.parse(horaMin[1]);

                  if (partes[1] == "PM" && hour != 12) hour += 12;
                  if (partes[1] == "AM" && hour == 12) hour = 0;

                  final citaFechaHora = DateTime(
                    cita.fecha.year,
                    cita.fecha.month,
                    cita.fecha.day,
                    hour,
                    minute,
                  );

                  return citaFechaHora.isAfter(ahora);
                }).toList();

                citas.sort((a, b) {
                  final fechaA = DateTime(a.fecha.year, a.fecha.month, a.fecha.day);
                  final fechaB = DateTime(b.fecha.year, b.fecha.month, b.fecha.day);
                  return fechaA.compareTo(fechaB);
                });

                if (citas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No tienes próximas citas',
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

  Future<Map<String, String>> _obtenerDatosCita(CitaModel cita) async {
    final petDoc = await _db.collection('pets').doc(cita.mascotaId).get();
    final mascotaNombre = petDoc.data()?['nombre'] ?? 'Mascota desconocida';

    final serviceDoc =
        await _db.collection('types_services').doc(cita.servicioId).get();
    final servicioNombre = serviceDoc.data()?['nombre'] ?? 'Servicio desconocido';

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
