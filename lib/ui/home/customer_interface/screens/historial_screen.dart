import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_movil/ui/home/customer_interface/widgets/pet_history_card.dart';
import 'package:veterinaria_movil/controllers/clinical_history_controller.dart';
import 'package:veterinaria_movil/controllers/pet_controller.dart';
import 'package:veterinaria_movil/moldes/clinical_history_model.dart';
import 'package:veterinaria_movil/moldes/pet_model.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final clinicalHistoryController = ClinicalHistoryController();
  final petController = PetController();
  final searchController = TextEditingController();
  
  String searchQuery = '';
  String? selectedPetId;

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
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar por mascota, veterinaria...',
                    prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
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
                const SizedBox(height: 12),
                
                // Filtro por mascota
                StreamBuilder<List<PetModel>>(
                  stream: petController.getPetsStream(userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final pets = snapshot.data!;
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            isSelected: selectedPetId == null,
                            onTap: () => setState(() => selectedPetId = null),
                          ),
                          const SizedBox(width: 8),
                          ...pets.map((pet) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: pet.nombre,
                              isSelected: selectedPetId == pet.id,
                              onTap: () => setState(() => selectedPetId = pet.id),
                            ),
                          )),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Lista de historiales
          Expanded(
            child: StreamBuilder<List<PetModel>>(
              stream: petController.getPetsStream(userId),
              builder: (context, petSnapshot) {
                if (petSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (!petSnapshot.hasData || petSnapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes mascotas registradas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registra tus mascotas para ver su historial',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                final pets = petSnapshot.data!;
                final filteredPets = selectedPetId == null
                    ? pets
                    : pets.where((p) => p.id == selectedPetId).toList();

                if (filteredPets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron mascotas',
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPets.length,
                  itemBuilder: (context, index) {
                    final pet = filteredPets[index];
                    return _PetHistorySection(
                      pet: pet,
                      searchQuery: searchQuery,
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

// Chip de filtro
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
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
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

// Sección de historial por mascota
class _PetHistorySection extends StatelessWidget {
  final PetModel pet;
  final String searchQuery;

  const _PetHistorySection({
    required this.pet,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final clinicalHistoryController = ClinicalHistoryController();

    return StreamBuilder<List<ClinicalHistoryModel>>(
      stream: clinicalHistoryController.getClinicalHistoryByPetId(pet.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Sin historial clínico',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        final histories = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pet.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            ...histories.map((history) => FutureBuilder<Map<String, String>>(
              future: _getHistoryDetails(history),
              builder: (context, detailsSnapshot) {
                if (!detailsSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final details = detailsSnapshot.data!;
                
                return GestureDetector(
                  onTap: () => _showCompleteHistory(context, history),
                  child: PetHistoryCard(
                    fecha: DateFormat('dd/MM/yyyy').format(history.fecha),
                    tipo: details['tipo'] ?? 'Consulta general',
                    veterinario: details['veterinario'] ?? 'Dr. Veterinario',
                    descripcion: history.motivoConsulta.length > 80
                        ? '${history.motivoConsulta.substring(0, 80)}...'
                        : history.motivoConsulta,
                  ),
                );
              },
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<Map<String, String>> _getHistoryDetails(ClinicalHistoryModel history) async {
    try {
      // Obtener nombre del veterinario
      final vetDoc = await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(history.veterinarioId)
          .get();
      
      final vetData = vetDoc.data();
      final vetName = vetData != null
          ? 'Dr. ${vetData['apellido'] ?? 'Veterinario'}'
          : 'Dr. Veterinario';

      // Obtener tipo de servicio de la cita
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(history.citaId)
          .get();
      
      final appointmentData = appointmentDoc.data();
      final tipo = appointmentData?['tipoServicio'] ?? 'Consulta general';

      return {
        'veterinario': vetName,
        'tipo': tipo,
      };
    } catch (e) {
      return {
        'veterinario': 'Dr. Veterinario',
        'tipo': 'Consulta general',
      };
    }
  }

  Future<void> _showCompleteHistory(BuildContext context, ClinicalHistoryModel history) async {
    DocumentSnapshot? appointmentDoc;
    DocumentSnapshot? vetDoc;
    DocumentSnapshot? veterinariaDoc;

    try {
      appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(history.citaId)
          .get();

      vetDoc = await FirebaseFirestore.instance
          .collection('veterinarians')
          .doc(history.veterinarioId)
          .get();

      veterinariaDoc = await FirebaseFirestore.instance
          .collection('veterinarias')
          .doc(history.veterinariaId)
          .get();
    } catch (e) {
      print('Error cargando datos: $e');
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteHistoryModal(
        history: history,
        appointmentData: appointmentDoc?.data() as Map<String, dynamic>?,
        vetData: vetDoc?.data() as Map<String, dynamic>?,
        veterinariaData: veterinariaDoc?.data() as Map<String, dynamic>?,
      ),
    );
  }
}

// Modal de historial completo
class _CompleteHistoryModal extends StatelessWidget {
  final ClinicalHistoryModel history;
  final Map<String, dynamic>? appointmentData;
  final Map<String, dynamic>? vetData;
  final Map<String, dynamic>? veterinariaData;

  const _CompleteHistoryModal({
    required this.history,
    this.appointmentData,
    this.vetData,
    this.veterinariaData,
  });

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.green,
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
          color: Colors.green,
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