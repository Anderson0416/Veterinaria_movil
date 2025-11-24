import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/controllers/clinical_history_controller.dart';
import 'package:veterinaria_movil/moldes/clinical_history_model.dart';
import 'package:intl/intl.dart';

class VetClinicalHistoryScreen extends StatefulWidget {
  const VetClinicalHistoryScreen({super.key});

  @override
  State<VetClinicalHistoryScreen> createState() => _VetClinicalHistoryScreenState();
}

class _VetClinicalHistoryScreenState extends State<VetClinicalHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final clinicalHistoryController = ClinicalHistoryController();
  final searchController = TextEditingController();
  
  String searchQuery = '';
  String? veterinariaId;
  bool isLoading = true;

  // Cache para evitar consultas repetidas
  final Map<String, Map<String, dynamic>> _customerCache = {};

  @override
  void initState() {
    super.initState();
    _loadVeterinariaId();
  }

  Future<void> _loadVeterinariaId() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final vetDoc = await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(userId)
          .get();
      
      if (vetDoc.exists && mounted) {
        setState(() {
          veterinariaId = vetDoc.data()?['veterinaryId'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando veterinariaId: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text('Historial Clínico', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : veterinariaId == null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildHistoryList()),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Error al cargar la información',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar por mascota, dueño, veterinario o fecha (dd/mm/yyyy)...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF388E3C)),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
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
            borderSide: const BorderSide(color: Color(0xFF388E3C), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<List<ClinicalHistoryModel>>(
      stream: clinicalHistoryController.getClinicalHistoryByVeterinaryId(veterinariaId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF388E3C)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        // Filtrar historiales
        return FutureBuilder<List<ClinicalHistoryModel>>(
          future: _filterHistories(snapshot.data!),
          builder: (context, filteredSnapshot) {
            if (filteredSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF388E3C)),
              );
            }

            final filteredHistories = filteredSnapshot.data ?? [];

            if (filteredHistories.isEmpty) {
              return _buildNoResultsState();
            }

            return ListView.builder(
              key: const PageStorageKey('historyList'),
              padding: const EdgeInsets.all(16),
              itemCount: filteredHistories.length,
              itemBuilder: (context, index) {
                final history = filteredHistories[index];
                return _HistoryCard(
                  key: ValueKey(history.id),
                  history: history,
                  customerCache: _customerCache,
                  onViewComplete: () => _showCompleteHistory(history),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<ClinicalHistoryModel>> _filterHistories(List<ClinicalHistoryModel> histories) async {
    if (searchQuery.isEmpty) return histories;
    
    final filtered = <ClinicalHistoryModel>[];
    
    for (final history in histories) {
      // Buscar por nombre de mascota
      if (history.mascotaNombre.toLowerCase().contains(searchQuery)) {
        filtered.add(history);
        continue;
      }
      
      // 🔹 NUEVO: Buscar por fecha
      final fechaFormateada = DateFormat('dd/MM/yyyy').format(history.fecha).toLowerCase();
      if (fechaFormateada.contains(searchQuery)) {
        filtered.add(history);
        continue;
      }
      
      // Buscar por datos del dueño
      try {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(history.duenoId)
            .get();
        
        if (ownerDoc.exists) {
          final ownerData = ownerDoc.data()!;
          final nombre = (ownerData['nombre'] ?? '').toLowerCase();
          final apellido = (ownerData['apellido'] ?? '').toLowerCase();
          final cedula = (ownerData['numeroDocumento'] ?? '').toLowerCase();
          
          if (nombre.contains(searchQuery) || 
              apellido.contains(searchQuery) ||
              cedula.contains(searchQuery)) {
            filtered.add(history);
            continue;
          }
        }
      } catch (e) {
        print('Error buscando dueño: $e');
      }
      
      // Buscar por veterinario
      try {
        final vetDoc = await FirebaseFirestore.instance
            .collection('veterinarians')
            .doc(history.veterinarioId)
            .get();
        
        if (vetDoc.exists) {
          final vetData = vetDoc.data()!;
          final apellido = (vetData['apellido'] ?? '').toLowerCase();
          
          if (apellido.contains(searchQuery)) {
            filtered.add(history);
            continue;
          }
        }
      } catch (e) {
        print('Error buscando veterinario: $e');
      }
    }
    
    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay historiales clínicos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los historiales aparecerán aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otro término de búsqueda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompleteHistory(ClinicalHistoryModel history) async {
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

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteHistoryModal(
        history: history,
        appointmentData: appointmentDoc.data(),
        ownerData: ownerDoc.data(),
        vetData: vetDoc.data(),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final ClinicalHistoryModel history;
  final Map<String, Map<String, dynamic>> customerCache;
  final VoidCallback onViewComplete;

  const _HistoryCard({
    super.key,
    required this.history,
    required this.customerCache,
    required this.onViewComplete,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  String? ownerName;
  bool isLoadingOwner = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerName();
  }

  Future<void> _loadOwnerName() async {
    if (widget.customerCache.containsKey(widget.history.duenoId)) {
      final data = widget.customerCache[widget.history.duenoId]!;
      if (mounted) {
        setState(() {
          ownerName = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim();
          isLoadingOwner = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.history.duenoId)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        widget.customerCache[widget.history.duenoId] = data;
        setState(() {
          ownerName = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim();
          isLoadingOwner = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ownerName = 'Cliente desconocido';
          isLoadingOwner = false;
        });
      }
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.history.mascotaNombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        isLoadingOwner 
                            ? 'Cargando...' 
                            : 'Dueño: ${ownerName ?? "Desconocido"}',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                    '${widget.history.peso} kg',
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
              'Última visita: ${DateFormat('dd/MM/yyyy').format(widget.history.fecha)}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              'Consulta general • ${widget.history.estadoGeneral}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onViewComplete,
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
          ],
        ),
      ),
    );
  }
}

class _CompleteHistoryModal extends StatelessWidget {
  final ClinicalHistoryModel history;
  final Map<String, dynamic>? appointmentData;
  final Map<String, dynamic>? ownerData;
  final Map<String, dynamic>? vetData;

  const _CompleteHistoryModal({
    required this.history,
    this.appointmentData,
    this.ownerData,
    this.vetData,
  });

  @override
  Widget build(BuildContext context) {
    final ownerName = ownerData != null
        ? '${ownerData!['nombre'] ?? ''} ${ownerData!['apellido'] ?? ''}'.trim()
        : 'Cliente desconocido';
    
    final vetName = vetData != null
        ? 'Dr. ${vetData!['apellido'] ?? 'Veterinario'}'
        : 'Veterinario desconocido';

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
                    _SectionTitle(title: 'Información de la Cita'),
                    _InfoRow(label: 'Fecha', value: DateFormat('dd/MM/yyyy').format(history.fecha)),
                    _InfoRow(label: 'Mascota', value: history.mascotaNombre),
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