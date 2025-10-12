// lib/ui/home/customer/screens/agendar_cita_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  String? mascotaSeleccionada;
  String? servicioSeleccionado;
  String? veterinarioSeleccionado;
  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;
  final observacionesCtrl = TextEditingController();

  final fechaCtrl = TextEditingController();
  final horaCtrl = TextEditingController();

  String? clinicaNombre;
  String? clinicaDireccion;
  String? clinicaTelefono;

  final List<String> mascotas = ["Max", "Luna", "Rocky"];
  final List<String> servicios = ["Consulta general", "Vacunación", "Control dental"];
  final List<String> veterinarios = ["Sin preferencia", "Dr. García", "Dra. Martínez"];

  @override
  void initState() {
    super.initState();
    _loadClinicInfo();
  }

  @override
  void dispose() {
    observacionesCtrl.dispose();
    fechaCtrl.dispose();
    horaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClinicInfo() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('veterinarias').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          clinicaNombre = data['nombre'] ?? "Veterinaria";
          clinicaDireccion = data['direccion'] ?? "Dirección no disponible";
          clinicaTelefono = data['telefono'] ?? "N/A";
        });
      }
    } catch (e) {
      Get.snackbar("Error", "No se pudo cargar la información de la clínica");
    }
  }

  // --- versiones sencillas de pickers ---
  Future<void> _pickDateSimple() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
        final dd = picked.day.toString().padLeft(2, '0');
        final mm = picked.month.toString().padLeft(2, '0');
        final yyyy = picked.year.toString();
        fechaCtrl.text = "$dd/$mm/$yyyy";
      });
    }
  }

  Future<void> _pickTimeSimple() async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: horaSeleccionada ?? now,
    );
    if (picked != null) {
      setState(() {
        horaSeleccionada = picked;
        horaCtrl.text = picked.format(context); // usa formato local sencillo (e.g. 14:30)
      });
    }
  }

  void _confirmarCita() {
    if (mascotaSeleccionada == null ||
        servicioSeleccionado == null ||
        fechaSeleccionada == null ||
        horaSeleccionada == null) {
      Get.snackbar("Campos incompletos", "Por favor, completa toda la información requerida");
      return;
    }

    Get.defaultDialog(
      title: "Cita Registrada",
      middleText:
          "Tu cita para $mascotaSeleccionada ha sido agendada el ${fechaCtrl.text} a las ${horaCtrl.text}.",
      textConfirm: "Aceptar",
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
        title: const Text("Agendar Nueva Cita"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Card principal
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Información de la Cita",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 12),

                      // Mascota
                      CitaDropdownField(
                        label: "Mascota",
                        value: mascotaSeleccionada,
                        items: mascotas,
                        onChanged: (v) => setState(() => mascotaSeleccionada = v),
                      ),

                      // Servicio
                      CitaDropdownField(
                        label: "Tipo de Servicio",
                        value: servicioSeleccionado,
                        items: servicios,
                        onChanged: (v) => setState(() => servicioSeleccionado = v),
                      ),

                      // Fecha y hora (sencillos)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDateSimple,
                              child: AbsorbPointer(
                                child: CitaTextField(
                                  label: "Fecha",
                                  readOnly: true,
                                  controller: fechaCtrl,
                                  hint: "dd/mm/aaaa",
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
                                  label: "Hora",
                                  readOnly: true,
                                  controller: horaCtrl,
                                  hint: "--:--",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Veterinario
                      CitaDropdownField(
                        label: "Veterinario (Opcional)",
                        value: veterinarioSeleccionado,
                        items: veterinarios,
                        onChanged: (v) => setState(() => veterinarioSeleccionado = v),
                      ),

                      // Observaciones
                      CitaTextField(
                        label: "Observaciones",
                        controller: observacionesCtrl,
                        hint: "Describe cualquier síntoma o información relevante...",
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Información de la clínica
              ClinicInfoCard(
                nombre: clinicaNombre ?? "Veterinaria",
                direccion: clinicaDireccion ?? "",
                telefono: clinicaTelefono ?? "",
              ),

              const SizedBox(height: 20),

              // Botones
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmarCita,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Confirmar Cita"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.green)),
                  ),
                  child: const Text("Cancelar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
