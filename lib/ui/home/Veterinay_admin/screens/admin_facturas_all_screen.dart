import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/admin_factura_card.dart';

class AdminFacturasAllScreen extends StatefulWidget {
  const AdminFacturasAllScreen({super.key});

  @override
  State<AdminFacturasAllScreen> createState() => _AdminFacturasAllScreenState();
}

class _AdminFacturasAllScreenState extends State<AdminFacturasAllScreen> {
  final Color green = const Color(0xFF388E3C);

  String filtro = "";

  final List<Map<String, dynamic>> facturas = [
    {
      'id': 'FAC-10001',
      'cliente': 'Carlos Gómez',
      'servicio': 'Vacunación',
      'fecha': '22/01/2025',
      'total': 65000,
    },
    {
      'id': 'FAC-10002',
      'cliente': 'Ana Torres',
      'servicio': 'Consulta General',
      'fecha': '20/01/2025',
      'total': 45000,
    },
    {
      'id': 'FAC-10003',
      'cliente': 'Luis Pérez',
      'servicio': 'Baño y Peluquería',
      'fecha': '19/01/2025',
      'total': 80000,
    },
    {
      'id': 'FAC-10004',
      'cliente': 'María Giraldo',
      'servicio': 'Cirugía Menor',
      'fecha': '18/01/2025',
      'total': 120000,
    },
    {
      'id': 'FAC-10005',
      'cliente': 'Samuel Rojas',
      'servicio': 'Desparasitación',
      'fecha': '15/01/2025',
      'total': 30000,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final facturasFiltradas = facturas.where((f) {
      final texto = filtro.toLowerCase();
      return f['id'].toLowerCase().contains(texto) ||
          f['cliente'].toLowerCase().contains(texto) ||
          f['servicio'].toLowerCase().contains(texto);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: green,
        title: const Text("Todas las Facturas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),

            Expanded(
              child: facturasFiltradas.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron facturas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: facturasFiltradas.length,
                      itemBuilder: (context, index) =>
                          AdminFacturaCard(factura: facturasFiltradas[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => filtro = value),
      decoration: InputDecoration(
        hintText: "Buscar por cliente, servicio o factura...",
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.search, color: green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
      ),
    );
  }
}
