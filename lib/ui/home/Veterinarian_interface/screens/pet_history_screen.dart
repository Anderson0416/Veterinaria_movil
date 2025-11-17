import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_movil/moldes/clinical_history_model.dart';
import 'package:intl/intl.dart';

class PetHistoryScreen extends StatelessWidget {
  final String mascotaId;
  final String mascotaNombre;

  const PetHistoryScreen({
    super.key,
    required this.mascotaId,
    required this.mascotaNombre,
  });

  // Este Stream trae TODOS los historiales de esta mascota en TODAS las veterinarias
  Stream<List<ClinicalHistoryModel>> _getAllHistoriesByPetId(String petId) {
    return FirebaseFirestore.instance
        .collection('clinical_histories')
        .where('mascotaId', isEqualTo: petId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClinicalHistoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _showCompleteHistory(BuildContext context, ClinicalHistoryModel history) async {
    final appointmentDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(history.citaId)
        .get();

    final ownerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(history.duenoId)
        .get();

    final vetDoc = await FirebaseFirestore.instance
        .collection('veterinarians')
        .doc(history.veterinarioId)
        .get();

    final veterinariaDoc = await FirebaseFirestore.instance
        .collection('veterinarias')
        .doc(history.veterinariaId)
        .get();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteHistoryModal(
        history: history,
        appointmentData: appointmentDoc.data(),
        ownerData: ownerDoc.data(),
        vetData: vetDoc.data(),
        veterinariaData: veterinariaDoc.data(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: Text(
          'Historial de $mascotaNombre',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: StreamBuilder<List<ClinicalHistoryModel>>(
        stream: _getAllHistoriesByPetId(mascotaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el historial',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No hay historial clínico',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'para $mascotaNombre',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          final histories = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final history = histories[index];
              return _HistoryCard(
                history: history,
                onViewComplete: () => _showCompleteHistory(context, history),
              );
            },
          );
        },
      ),
    );
  }
}

// Tarjeta de Historial
class _HistoryCard extends StatelessWidget {
  final ClinicalHistoryModel history;
  final VoidCallback onViewComplete;

  const _HistoryCard({
    required this.history,
    required this.onViewComplete,
  });

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Color(0xFF388E3C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(history.fecha),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('veterinarias')
                            .doc(history.veterinariaId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text(
                              'Cargando veterinaria...',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            );
                          }
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          final nombre = data?['nombre'] ?? 'Veterinaria desconocida';
                          return Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${history.peso} kg',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              history.motivoConsulta.length > 60
                  ? '${history.motivoConsulta.substring(0, 60)}...'
                  : history.motivoConsulta,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  'Ver Completo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modal de historial completo
class _CompleteHistoryModal extends StatelessWidget {
  final ClinicalHistoryModel history;
  final Map<String, dynamic>? appointmentData;
  final Map<String, dynamic>? ownerData;
  final Map<String, dynamic>? vetData;
  final Map<String, dynamic>? veterinariaData;

  const _CompleteHistoryModal({
    required this.history,
    this.appointmentData,
    this.ownerData,
    this.vetData,
    this.veterinariaData,
  });

  @override
  Widget build(BuildContext context) {
    final ownerName = ownerData != null
        ? '${ownerData!['nombre'] ?? ''} ${ownerData!['apellido'] ?? ''}'.trim()
        : 'Cliente desconocido';

    final vetName = vetData != null
        ? 'Dr. ${vetData!['apellido'] ?? 'Veterinario'}'
        : 'Veterinario desconocido';

    final veterinariaName = veterinariaData?['nombre'] ?? 'Veterinaria desconocida';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historial Completo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Información de la Consulta'),
                    _InfoRow(label: 'Fecha', value: DateFormat('dd/MM/yyyy').format(history.fecha)),
                    _InfoRow(label: 'Mascota', value: history.mascotaNombre),
                    _InfoRow(label: 'Veterinaria', value: veterinariaName),
                    _InfoRow(label: 'Dueño', value: ownerName),
                    if (ownerData?['numeroDocumento'] != null)
                      _InfoRow(label: 'Cédula', value: ownerData!['numeroDocumento']),
                    _InfoRow(label: 'Veterinario', value: vetName),
                    if (appointmentData?['tipoServicio'] != null)
                      _InfoRow(label: 'Tipo de Servicio', value: appointmentData!['tipoServicio']),
                    if (appointmentData?['hora'] != null)
                      _InfoRow(label: 'Hora', value: appointmentData!['hora']),

                    const SizedBox(height: 20),

                    _SectionTitle(title: 'Datos del Paciente'),
                    _InfoRow(label: 'Peso', value: '${history.peso} kg'),
                    _InfoRow(label: 'Temperatura', value: '${history.temperatura} °C'),
                    _InfoRow(label: 'Frecuencia Cardíaca', value: '${history.frecuenciaCardiaca} bpm'),

                    const SizedBox(height: 20),

                    _SectionTitle(title: 'Motivo de Consulta'),
                    _TextBlock(text: history.motivoConsulta),

                    const SizedBox(height: 20),

                    _SectionTitle(title: 'Examen Físico'),
                    _InfoRow(label: 'Estado General', value: history.estadoGeneral),
                    if (history.observacionesExamen.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Observaciones:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      _TextBlock(text: history.observacionesExamen),
                    ],

                    const SizedBox(height: 20),

                    _SectionTitle(title: 'Diagnóstico'),
                    _TextBlock(text: history.diagnostico),

                    const SizedBox(height: 20),

                    _SectionTitle(title: 'Tratamiento'),
                    _TextBlock(text: history.tratamiento),

                    if (history.proximaCita != null) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'Próxima Cita'),
                      _InfoRow(
                        label: 'Fecha programada',
                        value: DateFormat('dd/MM/yyyy').format(history.proximaCita!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF388E3C),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;

  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}