import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final Color green = const Color(0xFF388E3C);
  final Color greenLight = const Color(0xFFE8F5E9);
  
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F5), // Verde muy suave
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        centerTitle: true,
        title: const Text("Reportes y Estadísticas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterButton(),
            const SizedBox(height: 24),
            
            _buildTopVeterinariansSection(),
            const SizedBox(height: 24),

            _buildMonthlyActivitySection(),
            const SizedBox(height: 24),

            _buildConsultTypeSection(),
            const SizedBox(height: 24),

            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // BOTÓN DE FILTRO POR FECHAS
  Widget _buildFilterButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              startDate != null && endDate != null
                  ? "${_formatDate(startDate!)} - ${_formatDate(endDate!)}"
                  : "Filtrar por rango de fechas",
              style: TextStyle(
                color: startDate != null ? Colors.black87 : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.filter_list, color: green, size: 20),
        ],
      ),
    );
  }

  // SECCIÓN: VETERINARIOS CON MÁS CITAS
  Widget _buildTopVeterinariansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.leaderboard, color: green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Veterinarios con Más Citas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTopVeterinariansCard(),
      ],
    );
  }

  Widget _buildTopVeterinariansCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          final now = DateTime.now();
          final Map<String, int> counts = {};
          
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            DateTime fecha;
            final rawFecha = data['fecha'];
            if (rawFecha is Timestamp) {
              fecha = rawFecha.toDate();
            } else if (rawFecha is String) {
              fecha = DateTime.tryParse(rawFecha) ?? now;
            } else {
              fecha = now;
            }

            if (fecha.month == now.month && fecha.year == now.year) {
              final vetId = data['veterinarioId'] ?? '';
              counts[vetId] = (counts[vetId] ?? 0) + 1;
            }
          }

          final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = sorted.take(3).toList();
          final maxCount = top.isNotEmpty ? top.first.value : 1;

          return Column(
            children: List.generate(top.length, (i) {
              final entry = top[i];
              return Column(
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('veterinarians').doc(entry.key).get(),
                    builder: (ctx, vetSnap) {
                      final vetName = vetSnap.hasData && vetSnap.data!.exists
                          ? (vetSnap.data!.data() as Map<String, dynamic>)['nombre'] ?? 'Sin nombre'
                          : 'Sin nombre';
                      final progress = maxCount > 0 ? entry.value / maxCount : 0.0;
                      return _buildVetTile(i + 1, vetName, entry.value, progress);
                    },
                  ),
                  if (i < top.length - 1) const SizedBox(height: 16),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildVetTile(int index, String name, int count, double progress) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: green,
          ),
          child: Center(
            child: Text(
              index.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 4),
              Text("$count citas este mes", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(green),
            ),
          ),
        ),
      ],
    );
  }

  // SECCIÓN: ACTIVIDAD POR MES
  Widget _buildMonthlyActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_graph, color: green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Actividad por Mes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildMonthlyActivityCard(),
      ],
    );
  }

  Widget _buildMonthlyActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          final Map<String, int> byMonth = {};
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            DateTime fecha;
            final rawFecha = data['fecha'];
            if (rawFecha is Timestamp) {
              fecha = rawFecha.toDate();
            } else if (rawFecha is String) {
              fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
            } else {
              fecha = DateTime.now();
            }

            final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
            byMonth[key] = (byMonth[key] ?? 0) + 1;
          }

          final now = DateTime.now();
          final months = <Map<String, dynamic>>[];
          int maxCount = 1;
          
          for (int i = 0; i < 12; i++) {
            final dt = DateTime(now.year, now.month - i, 1);
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            final count = byMonth[key] ?? 0;
            
            if (count > 0) {
              if (count > maxCount) maxCount = count;
              months.add({'label': '${_monthLabel(dt.month)} ${dt.year}', 'count': count});
            }
          }

          if (months.isEmpty) {
            return Center(
              child: Text("No hay citas registradas", style: TextStyle(color: Colors.grey.shade600)),
            );
          }

          return Column(
            children: List.generate(months.length, (index) {
              final m = months[index];
              final cnt = m['count'] as int;
              final progress = maxCount > 0 ? cnt / maxCount : 0.0;
              return Column(
                children: [
                  _buildMonthTile(m['label'] as String, cnt, progress),
                  if (index < months.length - 1) const SizedBox(height: 12),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildMonthTile(String month, int count, double progress) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(month, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 2),
              Text("$count citas", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(green),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(count.toString(), textAlign: TextAlign.right, 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ],
    );
  }

  // SECCIÓN: CONSULTAS LOCAL VS DOMICILIO
  Widget _buildConsultTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pie_chart, color: green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Consultas: Local vs Domicilio",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildConsultTypeCard(),
      ],
    );
  }

  Widget _buildConsultTypeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          int local = 0;
          int domicilio = 0;
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final direccion = (data['direccion'] ?? '') as String;
            if (direccion.trim().isEmpty) {
              local++;
            } else {
              domicilio++;
            }
          }

          final total = local + domicilio;
          final localP = total > 0 ? local / total : 0.0;
          final domP = total > 0 ? domicilio / total : 0.0;

          return Column(
            children: [
              _buildConsultTile("Local", local, localP),
              const SizedBox(height: 16),
              _buildConsultTile("Domicilio", domicilio, domP),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total de consultas: $total",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Las consultas locales representan el ${(localP * 100).toStringAsFixed(0)}% del total.",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildConsultTile(String type, int amount, double progress) {
    final icon = type == "Local" ? Icons.store : Icons.home_work;
    return Row(
      children: [
        Icon(icon, color: green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 2),
              Text("$amount citas", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(green),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text("${(progress * 100).toInt()}%", textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }

  // BOTONES DE ACCIÓN
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 20),
            label: const Text("Por Fechas", style: TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              side: BorderSide(color: green, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _showDateRangeFilter,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 20),
            label: const Text("Exportar", style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Get.snackbar("Exportando", "El reporte está siendo generado...", backgroundColor: green, colorText: Colors.white);
            },
          ),
        ),
      ],
    );
  }

  // FUNCIÓN HELPER: MOSTRAR FILTRO DE FECHAS
  void _showDateRangeFilter() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        startDate = range.start;
        endDate = range.end;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _monthLabel(int month) {
    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    if (month < 1 || month > 12) return '';
    return months[month];
  }
}
