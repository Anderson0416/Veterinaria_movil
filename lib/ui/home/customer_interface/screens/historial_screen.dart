import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Historial de Mascotas"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre de mascota...',
                prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                ),
              ),
            ),
          ),

          // Lista de historiales
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clinical_history')
                  .where('duenoId', isEqualTo: userId)
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text('Error al cargar historial', style: TextStyle(fontSize: 18, color: Colors.red.shade600)),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
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
                        Text('No hay historial clínico', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text('Los historiales de tus mascotas aparecerán aquí', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                // Filtrar por nombre de mascota
                final allDocs = snapshot.data!.docs;
                
                // Ordenar por fecha manualmente
                allDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final fechaA = dataA['fecha'] as Timestamp?;
                  final fechaB = dataB['fecha'] as Timestamp?;
                  if (fechaA == null || fechaB == null) return 0;
                  return fechaB.compareTo(fechaA);
                });
                
                final filteredDocs = searchQuery.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final mascotaNombre = (data['mascotaNombre'] ?? '').toString().toLowerCase();
                        return mascotaNombre.contains(searchQuery);
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No se encontraron resultados', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Intenta con otro nombre', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                // Agrupar por mascota
                final Map<String, List<Map<String, dynamic>>> groupedByPet = {};
                for (final doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  final mascotaId = data['mascotaId'] ?? '';
                  if (!groupedByPet.containsKey(mascotaId)) {
                    groupedByPet[mascotaId] = [];
                  }
                  groupedByPet[mascotaId]!.add(data);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedByPet.length,
                  itemBuilder: (context, index) {
                    final mascotaId = groupedByPet.keys.elementAt(index);
                    final histories = groupedByPet[mascotaId]!;
                    final mascotaNombre = histories.first['mascotaNombre'] ?? 'Mascota';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.pets, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                mascotaNombre,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${histories.length} ${histories.length == 1 ? 'registro' : 'registros'}',
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...histories.map((data) => _HistoryCard(historyData: data)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> historyData;

  const _HistoryCard({required this.historyData});

  @override
  Widget build(BuildContext context) {
    final fecha = historyData['fecha'] != null ? (historyData['fecha'] as Timestamp).toDate() : DateTime.now();

    return FutureBuilder<Map<String, String>>(
      future: _getDetails(),
      builder: (context, snapshot) {
        final veterinario = snapshot.data?['veterinario'] ?? 'Dr. Veterinario';
        final tipo = snapshot.data?['tipo'] ?? 'Consulta';
        final veterinaria = snapshot.data?['veterinaria'] ?? 'Veterinaria';

        return GestureDetector(
          onTap: () => _showModal(context),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.medical_services, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(fecha), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(veterinaria, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                        child: Text('${historyData['peso'] ?? 0} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    historyData['motivoConsulta'] ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text('$veterinario • $tipo', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getDetails() async {
    try {
      final vetDoc = historyData['veterinarioId'] != null
          ? await FirebaseFirestore.instance.collection('veterinarians').doc(historyData['veterinarioId']).get()
          : null;
      final appointmentDoc = historyData['citaId'] != null
          ? await FirebaseFirestore.instance.collection('appointments').doc(historyData['citaId']).get()
          : null;
      final veteriDoc = historyData['veterinariaId'] != null
          ? await FirebaseFirestore.instance.collection('veterinarias').doc(historyData['veterinariaId']).get()
          : null;

      return {
        'veterinario': vetDoc != null ? 'Dr. ${vetDoc.data()?['apellido'] ?? 'Veterinario'}' : 'Dr. Veterinario',
        'tipo': appointmentDoc?.data()?['tipoServicio'] ?? 'Consulta',
        'veterinaria': veteriDoc?.data()?['nombre'] ?? 'Veterinaria',
      };
    } catch (e) {
      return {'veterinario': 'Dr. Veterinario', 'tipo': 'Consulta', 'veterinaria': 'Veterinaria'};
    }
  }

  void _showModal(BuildContext context) async {
    final appointmentDoc = historyData['citaId'] != null
        ? await FirebaseFirestore.instance.collection('appointments').doc(historyData['citaId']).get()
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
      builder: (ctx) => _CompleteHistoryModal(
        historyData: historyData,
        appointmentData: appointmentDoc?.data(),
        vetData: vetDoc?.data(),
        veterinariaData: veterinariaDoc?.data(),
      ),
    );
  }
}

class _CompleteHistoryModal extends StatelessWidget {
  final Map<String, dynamic> historyData;
  final Map<String, dynamic>? appointmentData;
  final Map<String, dynamic>? vetData;
  final Map<String, dynamic>? veterinariaData;

  const _CompleteHistoryModal({required this.historyData, this.appointmentData, this.vetData, this.veterinariaData});

  @override
  Widget build(BuildContext context) {
    final fecha = historyData['fecha'] != null ? (historyData['fecha'] as Timestamp).toDate() : DateTime.now();
    final vetName = vetData != null ? 'Dr. ${vetData!['apellido'] ?? 'Veterinario'}' : 'Veterinario';
    final veterinariaName = veterinariaData?['nombre'] ?? 'Veterinaria';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Historial Completo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
                    _SectionTitle('Información de la Consulta'),
                    _InfoRow('Fecha', DateFormat('dd/MM/yyyy').format(fecha)),
                    _InfoRow('Mascota', historyData['mascotaNombre'] ?? ''),
                    _InfoRow('Veterinaria', veterinariaName),
                    _InfoRow('Veterinario', vetName),
                    if (appointmentData?['tipoServicio'] != null) _InfoRow('Tipo de Servicio', appointmentData!['tipoServicio']),
                    if (appointmentData?['hora'] != null) _InfoRow('Hora', appointmentData!['hora']),
                    const SizedBox(height: 20),
                    _SectionTitle('Datos del Paciente'),
                    _InfoRow('Peso', '${historyData['peso'] ?? 0} kg'),
                    _InfoRow('Temperatura', '${historyData['temperatura'] ?? 0} °C'),
                    _InfoRow('Frecuencia Cardíaca', '${historyData['frecuenciaCardiaca'] ?? 0} bpm'),
                    const SizedBox(height: 20),
                    _SectionTitle('Motivo de Consulta'),
                    _TextBlock(historyData['motivoConsulta'] ?? ''),
                    const SizedBox(height: 20),
                    _SectionTitle('Examen Físico'),
                    _InfoRow('Estado General', historyData['estadoGeneral'] ?? ''),
                    if ((historyData['observacionesExamen'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      _TextBlock(historyData['observacionesExamen']),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle('Diagnóstico'),
                    _TextBlock(historyData['diagnostico'] ?? ''),
                    const SizedBox(height: 20),
                    _SectionTitle('Tratamiento'),
                    _TextBlock(historyData['tratamiento'] ?? ''),
                    if (historyData['proximaCita'] != null) ...[
                      const SizedBox(height: 20),
                      _SectionTitle('Próxima Cita'),
                      _InfoRow('Fecha programada', DateFormat('dd/MM/yyyy').format((historyData['proximaCita'] as Timestamp).toDate())),
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

  Widget _SectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)));
  Widget _InfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
          ],
        ),
      );
  Widget _TextBlock(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      );
}