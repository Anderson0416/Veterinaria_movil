// lib/ui/home/customer/screens/agendar_cita_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/clinic_info_card.dart';
import '../widgets/cita_dropdown_field.dart';
import '../widgets/cita_text_field.dart';

class AgendarCitaScreen extends StatefulWidget {
  const AgendarCitaScreen({super.key});

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final petController = PetController();
  final fechaCtrl = TextEditingController();
  final horaCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  // Selection state
  String? mascotaSeleccionada;
  String? servicioSeleccionado;
  String? veterinarioSeleccionado;
  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;
  String? modalidadSeleccionada;
  String? selectedClinicId;

  // Clinic info shown
  String? clinicaNombre;
  String? clinicaDireccion;
  String? clinicaTelefono;

  // Sample lists (can be replaced by dynamic queries later)
  final List<String> servicios = ['Consulta', 'Vacunación', 'Cirugía'];
  final List<String> veterinarios = [];
  final List<String> modalidades = ['Presencial', 'Domicilio'];

  @override
  void dispose() {
    observacionesCtrl.dispose();
    fechaCtrl.dispose();
    horaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateSimple() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
        fechaCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _pickTimeSimple() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() {
        horaSeleccionada = picked;
        horaCtrl.text = picked.format(context);
      });
    }
  }

  void _confirmarCita() {
    if (mascotaSeleccionada == null ||
        servicioSeleccionado == null ||
        fechaSeleccionada == null ||
        horaSeleccionada == null ||
        modalidadSeleccionada == null) {
      Get.snackbar('Campos incompletos', 'Por favor, completa toda la información requerida');
      return;
    }

    Get.defaultDialog(
      title: 'Cita Registrada',
      middleText:
          'Tu cita para $mascotaSeleccionada ha sido agendada el ${fechaCtrl.text} a las ${horaCtrl.text}. Modalidad: $modalidadSeleccionada.',
      textConfirm: 'Aceptar',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Agendar Nueva Cita'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Clinic selector on top
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('veterinarias').snapshots(),
              builder: (context, snapClinicas) {
                if (snapClinicas.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                final docs = snapClinicas.data?.docs ?? [];
                final clinicNames = docs
                    .map<String>((d) => (d.data() as Map<String, dynamic>)['nombre']?.toString() ?? 'Veterinaria')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CitaDropdownField(
                      label: 'Seleccionar Clínica',
                      value: clinicaNombre,
                      items: clinicNames,
                      onChanged: (v) {
                        if (v == null) return;
                        QueryDocumentSnapshot? match;
                        for (var d in docs) {
                          final name = (d.data() as Map<String, dynamic>)['nombre']?.toString() ?? '';
                          if (name == v) {
                            match = d;
                            break;
                          }
                        }
                        if (match != null) {
                          final found = match;
                          setState(() {
                            selectedClinicId = found.id;
                            final data = found.data() as Map<String, dynamic>;
                            clinicaNombre = data['nombre'] ?? '';
                            clinicaDireccion = data['direccion'] ?? '';
                            clinicaTelefono = data['telefono'] ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ClinicInfoCard(
                      nombre: clinicaNombre ?? 'Veterinaria',
                      direccion: clinicaDireccion ?? '',
                      telefono: clinicaTelefono ?? '',
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // Form card
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Información de la Cita',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 12),

                          // Mascota (dinámica)
                          StreamBuilder<List<PetModel>>(
                            stream: petController.getPetsStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Colors.green));
                              }
                              final pets = snapshot.data ?? [];
                              final petNames = pets.map((p) => p.nombre).toList();
                              return CitaDropdownField(
                                label: 'Mascota',
                                value: mascotaSeleccionada,
                                items: petNames,
                                onChanged: (v) => setState(() => mascotaSeleccionada = v),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // Servicio
                          CitaDropdownField(
                            label: 'Tipo de Servicio',
                            value: servicioSeleccionado,
                            items: servicios,
                            onChanged: (v) => setState(() => servicioSeleccionado = v),
                          ),

                          const SizedBox(height: 12),

                          // Fecha y hora
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickDateSimple,
                                  child: AbsorbPointer(
                                    child: CitaTextField(
                                      label: 'Fecha',
                                      readOnly: true,
                                      controller: fechaCtrl,
                                      hint: 'dd/mm/aaaa',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickTimeSimple,
                                  child: AbsorbPointer(
                                    child: CitaTextField(
                                      label: 'Hora',
                                      readOnly: true,
                                      controller: horaCtrl,
                                      hint: '--:--',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Veterinario
                          CitaDropdownField(
                            label: 'Veterinario (Opcional)',
                            value: veterinarioSeleccionado,
                            items: veterinarios,
                            onChanged: (v) => setState(() => veterinarioSeleccionado = v),
                          ),

                          const SizedBox(height: 12),

                          // Modalidad
                          CitaDropdownField(
                            label: 'Modalidad',
                            value: modalidadSeleccionada,
                            items: modalidades,
                            onChanged: (v) => setState(() => modalidadSeleccionada = v),
                          ),

                          const SizedBox(height: 12),

                          // Observaciones
                          CitaTextField(
                            label: 'Observaciones',
                            controller: observacionesCtrl,
                            hint: 'Describe cualquier síntoma o información relevante...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botones
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmarCita,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar Cita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.green)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
