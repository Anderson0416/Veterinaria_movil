import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  final Color green = const Color(0xFF388E3C);
  final Color greenLight = const Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF8), // fondo verde muy suave
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        centerTitle: true,
        title: const Text("Reportes y Estadísticas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionHeader(Icons.leaderboard, "Veterinarios con Más Citas"),
            const SizedBox(height: 10),
            _buildTopVeterinariansCard(),
            const SizedBox(height: 25),

            _buildSectionHeader(Icons.auto_graph, "Actividad por Mes"),
            const SizedBox(height: 10),
            _buildMonthlyActivityCard(),
            const SizedBox(height: 25),

            _buildSectionHeader(Icons.pie_chart, "Consultas por Tipo"),
            const SizedBox(height: 10),
            _buildConsultTypeCard(),
            const SizedBox(height: 30),

            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // ENCABEZADO DE CADA SECCIÓN
  // -----------------------------------------------------------
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: green, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------
  // CARD: TOP VETERINARIOS
  // -----------------------------------------------------------
  Widget _buildTopVeterinariansCard() {
    return _whiteCard(
      child: Column(
        children: [
          _vetRankTile(1, "Dr. García", 45, 0.90),
          const SizedBox(height: 12),
          _vetRankTile(2, "Dra. Martínez", 38, 0.75),
          const SizedBox(height: 12),
          _vetRankTile(3, "Dr. López", 32, 0.60),
        ],
      ),
    );
  }

  Widget _vetRankTile(int index, String name, int count, double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: greenLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: green,
            child: Text(
              index.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  "$count citas este mes",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          _progressBar(progress),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // CARD: ACTIVIDAD POR MES
  // -----------------------------------------------------------
  Widget _buildMonthlyActivityCard() {
    return _whiteCard(
      child: Column(
        children: [
          _monthTile("Oct 2025", 120, 0.60),
          const SizedBox(height: 12),
          _monthTile("Nov 2025", 150, 0.75),
          const SizedBox(height: 12),
          _monthTile("Dic 2025", 180, 0.95),
          const SizedBox(height: 12),
          _monthTile("Ene 2025", 95, 0.45),
        ],
      ),
    );
  }

  Widget _monthTile(String month, int count, double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: greenLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$month\n$count citas",
              style: const TextStyle(
                height: 1.2,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _progressBar(progress),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // CARD: CONSULTAS LOCAL VS DOMICILIO
  // -----------------------------------------------------------
  Widget _buildConsultTypeCard() {
    return _whiteCard(
      child: Column(
        children: [
          _consultTile("Local", 280, 0.70),
          const SizedBox(height: 18),
          _consultTile("Domicilio", 120, 0.30),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: greenLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: green.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Total de consultas: 400",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  "Las consultas locales representan el 70% del total.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _consultTile(String type, int amount, double progress) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "$type\n$amount citas",
            style: const TextStyle(
                height: 1.2, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        _progressBar(progress),
        const SizedBox(width: 8),
        Text("${(progress * 100).toInt()}%",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // -----------------------------------------------------------
  // BOTÓN EXPORTAR
  // -----------------------------------------------------------
  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text("Exportar Reporte Completo",
            style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Get.snackbar("Exportando", "El reporte está siendo generado...");
        },
      ),
    );
  }

  // -----------------------------------------------------------
  // UI BASE: CARD BLANCA
  // -----------------------------------------------------------
  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  // -----------------------------------------------------------
  // BARRA DE PROGRESO REDONDEADA
  // -----------------------------------------------------------
  Widget _progressBar(double value) {
    return SizedBox(
      width: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 7,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(green),
        ),
      ),
    );
  }
}
