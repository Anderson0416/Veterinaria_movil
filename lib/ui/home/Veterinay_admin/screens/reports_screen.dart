import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

// Clase auxiliar para dibujar un gráfico circular sencillo (pie chart)
class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;

    final total = values.fold<double>(0, (p, e) => p + (e.isNaN ? 0.0 : e));

    final paint = Paint()..style = PaintingStyle.fill;

    double startAngle = -math.pi / 2; // comenzar desde arriba

    if (total <= 0) {
      // dibujar círculo gris cuando no hay datos
      paint.color = Colors.grey.shade200;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      final sweep = (val / total) * (math.pi * 2);
      paint.color = i < colors.length ? colors[i] : Colors.grey.shade400;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
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
            const SizedBox(height: 12),
            
            _buildActionButtons(),
            const SizedBox(height: 24),
            
            _buildTopVeterinariansSection(),
            const SizedBox(height: 24),

            _buildMonthlyActivitySection(),
            const SizedBox(height: 24),

            // Nueva tarjeta: ingresos generados
            _buildRevenueSection(),
            const SizedBox(height: 24),
            const SizedBox(height: 24),

            _buildConsultTypeSection(),
            const SizedBox(height: 24),

            //  Nueva sección: Estado de citas (Pendiente / Atendida / Cancelada)
            _buildStatusByStateSection(),
            const SizedBox(height: 24),
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

  // -----------------------
  // TARJETA: INGRESOS GENERADOS
  // Muestra la suma de precioServicio para las citas de la veterinaria (filtradas por veterinariaId si hay sesión activa)
  // Respeta el filtro por rango de fechas (startDate / endDate) si está aplicado.
  Widget _buildRevenueSection() {
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
              child: Icon(Icons.monetization_on, color: green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Ingresos Generados",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildRevenueCard(),
      ],
    );
  }

  // Tarjeta principal que calcula y muestra ingresos a partir de 'precioServicio'
  Widget _buildRevenueCard() {
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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          // obtener id de la veterinaria (usuario actual) para filtrar ingresos únicamente de su clínica
          final vetId = FirebaseAuth.instance.currentUser?.uid ?? '';

          double totalRevenue = 0.0; // suma de precioServicio
          int citasContadas = 0; // número de citas que se tomaron en cuenta

          // determinar límites de fecha si hay filtro activo
          DateTime? from;
          DateTime? to;
          if (startDate != null || endDate != null) {
            from = startDate != null ? DateTime(startDate!.year, startDate!.month, startDate!.day) : DateTime.fromMillisecondsSinceEpoch(0);
            to = endDate != null ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59) : DateTime.now().add(const Duration(days: 36500));
          }

          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;

            // parseo de fecha robusto
            DateTime fecha;
            final rawFecha = data['fecha'];
            if (rawFecha is Timestamp) {
              fecha = rawFecha.toDate();
            } else if (rawFecha is String) {
              fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
            } else if (rawFecha is DateTime) {
              fecha = rawFecha;
            } else {
              fecha = DateTime.now();
            }

            // aplicar filtro de fecha si existe
            if (from != null && to != null) {
              if (fecha.isBefore(from) || fecha.isAfter(to)) continue;
            }

            // si hay sesión, solo contar citas de esta veterinaria
            if (vetId.isNotEmpty) {
              final vId = (data['veterinariaId'] ?? '').toString();
              if (vId != vetId) continue;
            }

            // leer precioServicio (asegurando conversión segura a double)
            final precioRaw = data['precioServicio'];
            double precio = 0.0;
            if (precioRaw is num) {
              precio = precioRaw.toDouble();
            } else if (precioRaw is String) {
              precio = double.tryParse(precioRaw.replaceAll(',', '.')) ?? 0.0;
            }

            totalRevenue += precio;
            citasContadas++;
          }

          // format simple (2 decimales)
          final totalText = '\$${totalRevenue.toStringAsFixed(2)}';
          final avg = citasContadas > 0 ? (totalRevenue / citasContadas) : 0.0;

          return Column(
            children: [
              // fila resumen: Total y número de citas
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total generado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        Text(totalText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // tarjeta pequeña con conteo de citas y promedio
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: greenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: green.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$citasContadas citas', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Promedio: \$${avg.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // explicación y leyenda
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
                    Text('Mostrando ingresos de la veterinaria${startDate != null && endDate != null ? ' desde ${_formatDate(startDate!)} hasta ${_formatDate(endDate!)}' : ''}.', style: TextStyle(color: Colors.grey.shade800)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
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

          
          DateTime? from;
          DateTime? to;
          if (startDate != null || endDate != null) {
            from = startDate != null ? DateTime(startDate!.year, startDate!.month, startDate!.day) : DateTime.fromMillisecondsSinceEpoch(0);
            to = endDate != null ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59) : DateTime.now().add(const Duration(days: 36500));
          }

          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;

            
            DateTime fecha;
            final rawFecha = data['fecha'];
            if (rawFecha is Timestamp) {
              fecha = rawFecha.toDate();
            } else if (rawFecha is String) {
              fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
            } else if (rawFecha is DateTime) {
              fecha = rawFecha;
            } else {
              fecha = DateTime.now();
            }

            // Respect optional date range
            if (from != null && to != null) {
              if (fecha.isBefore(from) || fecha.isAfter(to)) continue;
            }

            // Prefer the new 'modalidad' field (values: 'presencial' or 'domicilio')
            final modalRaw = (data['modalidad'] ?? data['modalidadSeleccionada'] ?? '').toString().toLowerCase().trim();
            if (modalRaw.isNotEmpty) {
              if (modalRaw.contains('presencial') || modalRaw.contains('local')) {
                local++;
              } else if (modalRaw.contains('domicilio') || modalRaw.contains('home')) {
                domicilio++;
              } else {
                // unknown modalidad -> still classify using direccion as fallback
                final direccion = (data['direccion'] ?? '').toString();
                if (direccion.trim().isEmpty) {
                  local++;
                } else {
                  domicilio++;
                }
              }
            } else {
              // fallback to old behavior: if direccion is empty => local
              final direccion = (data['direccion'] ?? '').toString();
              if (direccion.trim().isEmpty) {
                local++;
              } else {
                domicilio++;
              }
            }
          }

          final total = local + domicilio;
          final localP = total > 0 ? local / total : 0.0;
          final domP = total > 0 ? domicilio / total : 0.0;

          // colores para la gráfica circular acorde a la interfaz
          final colorLocal = green; // local usa el color principal
          final colorDomicilio = const Color(0xFF42A5F5); // azul suave que combina con la paleta

          return Column(
            children: [
              // fila principal: gráfica circular + leyenda
              Row(
                children: [
                  // Gráfica circular personalizada
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        values: [local.toDouble(), domicilio.toDouble()],
                        colors: [colorLocal, colorDomicilio],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            const SizedBox(height: 4),
                            const Text('Total citas', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  // Leyenda a la derecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Local', local, localP, colorLocal),
                        const SizedBox(height: 12),
                        _buildLegendItem('Domicilio', domicilio, domP, colorDomicilio),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // resumen y contexto (mantener caja estética)
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
                      "${(localP * 100).toStringAsFixed(0)}% Local — ${(domP * 100).toStringAsFixed(0)}% Domicilio",
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

  // (El helper _buildConsultTile fue removido porque ahora se muestra la gráfica circular)

  // Helper: leyenda para la gráfica circular
  Widget _buildLegendItem(String label, int count, double portion, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(width: 6),
        Text('${(portion * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  // Pintor de la gráfica circular (pie chart) - la clase se define fuera de la clase del State

  // -----------------------
  // SECCIÓN: ESTADO DE CITAS
  // Muestra un gráfico de barras horizontales con la cantidad de citas por estado
  // (pendiente / atendida / cancelada). Respeta el filtro por rango de fechas.
  Widget _buildStatusByStateSection() {
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
              child: Icon(Icons.bar_chart, color: green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Estado de citas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildStatusByStateCard(),
      ],
    );
  }

  // Tarjeta con la gráfica de barras horizontales para los estados
  Widget _buildStatusByStateCard() {
    // colores de la gráfica según petición
    const pendienteColor = Color(0xFFFFF3CD); // amarillo suave
    const atendidaColor = Color(0xFF388E3C); // verde pedido
    const canceladaColor = Color(0xFFFFCDD2); // rojo suave

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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          // límites de fecha según filtros
          DateTime? from;
          DateTime? to;
          if (startDate != null || endDate != null) {
            from = startDate != null ? DateTime(startDate!.year, startDate!.month, startDate!.day) : DateTime.fromMillisecondsSinceEpoch(0);
            to = endDate != null ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59) : DateTime.now().add(const Duration(days: 36500));
          }

          // contadores por estado
          int pendientes = 0;
          int atendidas = 0;
          int canceladas = 0;

          // filtrar y contar
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;

            // parseo robusto de fecha
            DateTime fecha;
            final rawFecha = data['fecha'];
            if (rawFecha is Timestamp) {
              fecha = rawFecha.toDate();
            } else if (rawFecha is String) {
              fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
            } else if (rawFecha is DateTime) {
              fecha = rawFecha;
            } else {
              fecha = DateTime.now();
            }

            // aplicar rango si existe
            if (from != null && to != null) {
              if (fecha.isBefore(from) || fecha.isAfter(to)) continue;
            }

            // leer estado y normalizar
            final estadoRaw = (data['estado'] ?? '').toString().toLowerCase().trim();
            if (estadoRaw.contains('pendiente')) {
              pendientes++;
            } else if (estadoRaw.contains('atendida') || estadoRaw.contains('atendido')) {
              atendidas++;
            } else if (estadoRaw.contains('cancelada') || estadoRaw.contains('cancelado')) {
              canceladas++;
            }
          }

          final total = pendientes + atendidas + canceladas;
          // calcular proporciones evitando división por cero
          final pPend = total > 0 ? pendientes / total : 0.0;
          final pAtend = total > 0 ? atendidas / total : 0.0;
          final pCanc = total > 0 ? canceladas / total : 0.0;

          return Column(
            children: [
              _buildStatusTile('Pendiente', pendientes, pPend, pendienteColor),
              const SizedBox(height: 12),
              _buildStatusTile('Atendida', atendidas, pAtend, atendidaColor),
              const SizedBox(height: 12),
              _buildStatusTile('Cancelada', canceladas, pCanc, canceladaColor),
              const SizedBox(height: 18),
              // resumen y contexto
              Row(
                children: [
                  Expanded(
                    child: Text('Total de citas: $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (startDate != null && endDate != null)
                    Text('Rango: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper: fila con barra horizontal para cada estado
  Widget _buildStatusTile(String label, int count, double portion, Color color) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: portion,
                  minHeight: 16,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$count citas', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text('${(portion * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
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
        // Botón para limpiar el filtro de fechas (deshabilitado si no hay filtro)
        SizedBox(
          width: 130,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.clear, size: 20),
            label: const Text("Limpiar", style: TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: startDate == null && endDate == null
                ? null
                : () {
                    setState(() {
                      // limpiar filtros de fecha
                      startDate = null;
                      endDate = null;
                    });
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
