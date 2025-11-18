import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PetHistoryScreen extends StatelessWidget {
  final String mascotaId;
  final String mascotaNombre;

  const PetHistoryScreen({
    super.key,
    required this.mascotaId,
    required this.mascotaNombre,
  });

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
      body: StreamBuilder<QuerySnapshot>(
        // OPTIMIZACIÓN: StreamBuilder directo con QuerySnapshot (sin mapeo intermedio)
        stream: FirebaseFirestore.instance
            .collection('clinical_history')
            .where('mascotaId', isEqualTo: mascotaId)
            .orderBy('fecha', descending: true)
            .snapshots(),
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
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _HistoryCard(
                historyId: doc.id,
                data: data,
                onTap: () => _showCompleteHistory(context, doc.id, data),
              );
            },
          );
        },
      ),
    );
  }

  void _showCompleteHistory(BuildContext context, String historyId, Map<String, dynamic> historyData) async {
    // Cargar datos relacionados
    final appointmentDoc = historyData['citaId'] != null
        ? await FirebaseFirestore.instance.collection('appointments').doc(historyData['citaId']).get()
        : null;

    final ownerDoc = historyData['duenoId'] != null
        ? await FirebaseFirestore.instance.collection('customers').doc(historyData['duenoId']).get()
        : null;

    final vetDoc = historyData['veterinarioId'] != null
        ? await FirebaseFirestore.instance.collection('veterinarians').doc(historyData['veterinarioId']).get()
        : null;

    final veterinariaDoc = historyData['veterinariaId'] != null
        ? await FirebaseFirestore.instance.collection('veterinarias').doc(historyData['veterinariaId']).get()
        : null;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteHistoryModal(
        historyData: historyData,
        appointmentData: appointmentDoc?.data(),
        ownerData: ownerDoc?.data(),
        vetData: vetDoc?.data(),
        veterinariaData: veterinariaDoc?.data(),
      ),
    );
  }
}

// Tarjeta de Historial - OPTIMIZADA
class _HistoryCard extends StatelessWidget {
  final String historyId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.historyId,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : DateTime.now();

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
                        DateFormat('dd/MM/yyyy').format(fecha),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: data['veterinariaId'] != null
                            ? FirebaseFirestore.instance.collection('veterinarias').doc(data['veterinariaId']).get()
                            : null,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text(
                              'Cargando veterinaria...',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            );
                          }
                          final vetData = snapshot.data?.data() as Map<String, dynamic>?;
                          final nombre = vetData?['nombre'] ?? 'Veterinaria desconocida';
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
                    '${data['peso'] ?? 0} kg',
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
              (data['motivoConsulta'] ?? '').length > 60
                  ? '${(data['motivoConsulta'] ?? '').substring(0, 60)}...'
                  : data['motivoConsulta'] ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
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
  final Map<String, dynamic> historyData;
  final Map<String, dynamic>? appointmentData;
  final Map<String, dynamic>? ownerData;
  final Map<String, dynamic>? vetData;
  final Map<String, dynamic>? veterinariaData;

  const _CompleteHistoryModal({
    required this.historyData,
    this.appointmentData,
    this.ownerData,
    this.vetData,
    this.veterinariaData,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = historyData['fecha'] != null ? (historyData['fecha'] as Timestamp).toDate() : DateTime.now();
    final ownerName = ownerData != null
        ? '${ownerData!['nombre'] ?? ''} ${ownerData!['apellido'] ?? ''}'.trim()
        : 'Cliente desconocido';
    final vetName = vetData != null ? 'Dr. ${vetData!['apellido'] ?? 'Veterinario'}' : 'Veterinario desconocido';
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
                    _InfoRow(label: 'Fecha', value: DateFormat('dd/MM/yyyy').format(fecha)),
                    _InfoRow(label: 'Mascota', value: historyData['mascotaNombre'] ?? ''),
                    _InfoRow(label: 'Veterinaria', value: veterinariaName),
                    _InfoRow(label: 'Dueño', value: ownerName),
                    if (ownerData?['numeroDocumento'] != null)
                      _InfoRow(label: 'Cédula', value: ownerData!['numeroDocumento']),
                    _InfoRow(label: 'Veterinario', value: vetName),
                    if (appointmentData?['tipoServicio'] != null)
                      _InfoRow(label: 'Tipo de Servicio', value: appointmentData!['tipoServicio']),
                    if (appointmentData?['hora'] != null) _InfoRow(label: 'Hora', value: appointmentData!['hora']),
                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Datos del Paciente'),
                    _InfoRow(label: 'Peso', value: '${historyData['peso'] ?? 0} kg'),
                    _InfoRow(label: 'Temperatura', value: '${historyData['temperatura'] ?? 0} °C'),
                    _InfoRow(label: 'Frecuencia Cardíaca', value: '${historyData['frecuenciaCardiaca'] ?? 0} bpm'),
                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Motivo de Consulta'),
                    _TextBlock(text: historyData['motivoConsulta'] ?? ''),
                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Examen Físico'),
                    _InfoRow(label: 'Estado General', value: historyData['estadoGeneral'] ?? ''),
                    if ((historyData['observacionesExamen'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Observaciones:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      _TextBlock(text: historyData['observacionesExamen']),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Diagnóstico'),
                    _TextBlock(text: historyData['diagnostico'] ?? ''),
                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Tratamiento'),
                    _TextBlock(text: historyData['tratamiento'] ?? ''),
                    if (historyData['proximaCita'] != null) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'Próxima Cita'),
                      _InfoRow(
                        label: 'Fecha programada',
                        value: DateFormat('dd/MM/yyyy').format((historyData['proximaCita'] as Timestamp).toDate()),
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