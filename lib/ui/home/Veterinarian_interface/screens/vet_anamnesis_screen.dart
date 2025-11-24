import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/clinical_history_controller.dart';
import 'package:veterinaria_movil/moldes/clinical_history_model.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';
import 'package:intl/intl.dart';
import 'package:veterinaria_movil/ui/home/Veterinarian_interface/screens/pet_history_screen.dart';

class VetAnamnesisScreen extends StatefulWidget {
  final String appointmentId;
  final String mascotaId;
  final String mascotaNombre;
  final String duenoId;
  final String veterinariaId;

  const VetAnamnesisScreen({
    super.key,
    required this.appointmentId,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.duenoId,
    required this.veterinariaId,
  });

  @override
  State<VetAnamnesisScreen> createState() => _VetAnamnesisScreenState();
}

class _VetAnamnesisScreenState extends State<VetAnamnesisScreen> {
  final _formKey = GlobalKey<FormState>();
  final clinicalHistoryController = ClinicalHistoryController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final pesoCtrl = TextEditingController();
  final temperaturaCtrl = TextEditingController();
  final frecuenciaCtrl = TextEditingController();
  final motivoCtrl = TextEditingController();
  final estadoGeneralCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();
  final diagnosticoCtrl = TextEditingController();
  final tratamientoCtrl = TextEditingController();

  PetModel? petData;

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.mascotaId)
          .get();

      if (doc.exists) {
        setState(() {
          petData = PetModel.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      print('Error cargando datos de mascota: $e');
    }
  }

 Future<void> _guardarAnamnesis() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Error',
        'Por favor completa todos los campos obligatorios',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Mostrar loading
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF388E3C)),
                SizedBox(height: 16),
                Text('Guardando anamnesis...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final history = ClinicalHistoryModel(
      citaId: widget.appointmentId,
      mascotaId: widget.mascotaId,
      mascotaNombre: widget.mascotaNombre,
      duenoId: widget.duenoId,
      veterinarioId: _auth.currentUser?.uid ?? '',
      veterinariaId: widget.veterinariaId,
      fecha: DateTime.now(),
      peso: double.tryParse(pesoCtrl.text) ?? 0.0,
      temperatura: double.tryParse(temperaturaCtrl.text) ?? 0.0,
      frecuenciaCardiaca: int.tryParse(frecuenciaCtrl.text) ?? 0,
      motivoConsulta: motivoCtrl.text.trim(),
      estadoGeneral: estadoGeneralCtrl.text.trim(),
      observacionesExamen: observacionesCtrl.text.trim(),
      diagnostico: diagnosticoCtrl.text.trim(),
      tratamiento: tratamientoCtrl.text.trim(),
      proximaCita: null,
    );

    try {
      await clinicalHistoryController.createClinicalHistory(history);

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({'estado': 'atendida'});

      // Cerrar loading
      Get.back();
      
      // Mostrar mensaje de éxito
      Get.snackbar(
        '✓ Anamnesis Guardada',
        'La información clínica se guardó exitosamente',
        backgroundColor: const Color(0xFF388E3C),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Esperar un momento para que se vea el mensaje
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Regresar a la pantalla anterior (dos veces)
      Get.back();
      Get.back();

    } catch (e) {
      // Cerrar loading
      Get.back();
      
      // Mostrar error
      Get.snackbar(
        'Error',
        'No se pudo guardar la anamnesis: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  @override
  void dispose() {
    pesoCtrl.dispose();
    temperaturaCtrl.dispose();
    frecuenciaCtrl.dispose();
    motivoCtrl.dispose();
    estadoGeneralCtrl.dispose();
    observacionesCtrl.dispose();
    diagnosticoCtrl.dispose();
    tratamientoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text('Realizar Anamnesis', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.to(() => PetHistoryScreen(
                      mascotaId: widget.mascotaId,
                      mascotaNombre: widget.mascotaNombre,
                    ));
                  },
                  icon: const Icon(Icons.history, color: Color(0xFF388E3C)),
                  label: const Text(
                    'Ver Historial Clínico',
                    style: TextStyle(color: Color(0xFF388E3C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF388E3C)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Datos del Paciente',
                icon: Icons.favorite,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoField(
                          label: 'Mascota',
                          value: widget.mascotaNombre,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          label: 'Peso (kg)',
                          controller: pesoCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          label: 'Temperatura (°C)',
                          controller: temperaturaCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          label: 'Frecuencia Cardíaca',
                          controller: frecuenciaCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Motivo de Consulta',
                children: [
                  _InputField(
                    label: 'Descripción del motivo de la consulta...',
                    controller: motivoCtrl,
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Examen Físico',
                children: [
                  _InputField(
                    label: 'Estado General',
                    controller: estadoGeneralCtrl,
                    hint: 'Ej: Excelente',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    label: 'Observaciones del Examen',
                    controller: observacionesCtrl,
                    hint: 'Observaciones detalladas...',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Diagnóstico y Tratamiento',
                children: [
                  _InputField(
                    label: 'Diagnóstico',
                    controller: diagnosticoCtrl,
                    hint: 'Diagnóstico presuntivo...',
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    label: 'Tratamiento',
                    controller: tratamientoCtrl,
                    hint: 'Plan de tratamiento...',
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarAnamnesis,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Guardar Anamnesis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF388E3C)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Color(0xFF388E3C)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF388E3C), size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;

  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF388E3C)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF388E3C), width: 2),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: const Color(0xFF388E3C))
            : null,
      ),
    );
  }
}